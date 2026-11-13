#include "SystemMonitorBackend.hpp"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QStringList>
#include <QTimer>
#include <algorithm>
#include <cmath>

SystemMonitorBackend::SystemMonitorBackend(QObject *parent)
    : QObject(parent)
{
    auto *timer = new QTimer(this);
    timer->setInterval(2000);
    connect(timer, &QTimer::timeout, this, &SystemMonitorBackend::refresh);
    refresh();
    timer->start();
}

void SystemMonitorBackend::refresh()
{
    qulonglong totalTicks = 0;
    qulonglong idleTicks = 0;
    const bool cpuReadable = readCpuTicks(&totalTicks, &idleTicks);
    qulonglong totalTickDelta = 0;
    const bool haveCpuDelta = cpuReadable && m_hasPreviousCpuSample && totalTicks > m_previousTotalTicks;
    if (haveCpuDelta) {
        totalTickDelta = totalTicks - m_previousTotalTicks;
        const qulonglong idleDelta = idleTicks >= m_previousIdleTicks ? idleTicks - m_previousIdleTicks : 0;
        m_cpuUsagePercent = totalTickDelta == 0 ? 0.0
            : std::clamp(100.0 * (1.0 - static_cast<double>(idleDelta) / static_cast<double>(totalTickDelta)), 0.0, 100.0);
    } else {
        m_cpuUsagePercent = 0.0;
    }
    if (cpuReadable) {
        m_previousTotalTicks = totalTicks;
        m_previousIdleTicks = idleTicks;
        m_hasPreviousCpuSample = true;
    }

    qulonglong totalMemory = 0;
    qulonglong availableMemory = 0;
    if (readMemory(&totalMemory, &availableMemory)) {
        m_memoryTotalBytes = totalMemory;
        m_memoryUsedBytes = totalMemory > availableMemory ? totalMemory - availableMemory : 0;
        m_memoryUsagePercent = totalMemory == 0 ? 0.0
            : std::clamp(100.0 * static_cast<double>(m_memoryUsedBytes) / static_cast<double>(totalMemory), 0.0, 100.0);
    }

    const QVariantList newProcesses = readProcesses(totalTickDelta, haveCpuDelta);
    const bool processListChanged = newProcesses != m_processes;
    m_processes = newProcesses;
    m_uptimeText = readUptime();
    m_lastUpdated = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));

    const bool metricsReadable = cpuReadable && totalMemory > 0 && !m_uptimeText.isEmpty();
    m_statusMessage = metricsReadable
        ? QStringLiteral("Données Linux en direct · lecture seule · aucun contrôle de processus.")
        : QStringLiteral("Certaines métriques de /proc ne sont pas accessibles; les valeurs disponibles restent affichées.");

    emit metricsChanged();
    if (processListChanged)
        emit processesChanged();
}

bool SystemMonitorBackend::readCpuTicks(qulonglong *totalTicks, qulonglong *idleTicks) const
{
    QFile file(QStringLiteral("/proc/stat"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;
    const QString line = QString::fromLatin1(file.readLine()).trimmed();
    const QStringList fields = line.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
    if (fields.size() < 5 || fields.constFirst() != QStringLiteral("cpu"))
        return false;

    qulonglong total = 0;
    // guest et guest_nice (indices 9–10) sont déjà inclus dans user/nice.
    const qsizetype cpuFieldEnd = std::min<qsizetype>(fields.size(), 9);
    for (qsizetype i = 1; i < cpuFieldEnd; ++i) {
        bool ok = false;
        const qulonglong value = fields.at(i).toULongLong(&ok);
        if (!ok)
            return false;
        total += value;
        if (i == 4 || i == 5) // idle + iowait
            *idleTicks += value;
    }
    *totalTicks = total;
    return true;
}

bool SystemMonitorBackend::readMemory(qulonglong *totalBytes, qulonglong *availableBytes) const
{
    QFile file(QStringLiteral("/proc/meminfo"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    qulonglong totalKb = 0;
    qulonglong availableKb = 0;
    qulonglong freeKb = 0;
    qulonglong buffersKb = 0;
    qulonglong cachedKb = 0;
    qulonglong reclaimableKb = 0;
    qulonglong sharedKb = 0;
    const QStringList lines = QString::fromLatin1(file.readAll()).split(QLatin1Char('\n'));
    for (const QString &rawLine : lines) {
        const QString line = rawLine.trimmed();
        const qsizetype colon = line.indexOf(QLatin1Char(':'));
        if (colon < 0)
            continue;
        const QString key = line.left(colon);
        const QStringList valueFields = line.mid(colon + 1).split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
        if (valueFields.isEmpty())
            continue;
        bool ok = false;
        const qulonglong value = valueFields.constFirst().toULongLong(&ok);
        if (!ok)
            continue;
        if (key == QStringLiteral("MemTotal")) totalKb = value;
        else if (key == QStringLiteral("MemAvailable")) availableKb = value;
        else if (key == QStringLiteral("MemFree")) freeKb = value;
        else if (key == QStringLiteral("Buffers")) buffersKb = value;
        else if (key == QStringLiteral("Cached")) cachedKb = value;
        else if (key == QStringLiteral("SReclaimable")) reclaimableKb = value;
        else if (key == QStringLiteral("Shmem")) sharedKb = value;
    }
    if (totalKb == 0)
        return false;
    if (availableKb == 0) {
        const qulonglong cacheAvailable = cachedKb + reclaimableKb > sharedKb
            ? cachedKb + reclaimableKb - sharedKb : 0;
        availableKb = std::min(totalKb, freeKb + buffersKb + cacheAvailable);
    }
    *totalBytes = totalKb * 1024;
    *availableBytes = std::min(totalKb, availableKb) * 1024;
    return true;
}

QString SystemMonitorBackend::readUptime() const
{
    QFile file(QStringLiteral("/proc/uptime"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    const QStringList fields = QString::fromLatin1(file.readLine()).trimmed().split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
    if (fields.isEmpty())
        return {};
    bool ok = false;
    const qulonglong seconds = static_cast<qulonglong>(fields.constFirst().toDouble(&ok));
    if (!ok)
        return {};

    const qulonglong days = seconds / 86400;
    const qulonglong hours = (seconds % 86400) / 3600;
    const qulonglong minutes = (seconds % 3600) / 60;
    if (days > 0)
        return QStringLiteral("%1 j %2 h %3 min").arg(days).arg(hours, 2, 10, QLatin1Char('0')).arg(minutes, 2, 10, QLatin1Char('0'));
    return QStringLiteral("%1 h %2 min").arg(hours, 2, 10, QLatin1Char('0')).arg(minutes, 2, 10, QLatin1Char('0'));
}

QVariantList SystemMonitorBackend::readProcesses(qulonglong totalTickDelta, bool haveCpuDelta)
{
    QDir procDirectory(QStringLiteral("/proc"));
    const QStringList entries = procDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    QHash<int, qulonglong> currentProcessTicks;
    QVariantList result;
    m_processCount = 0;

    static const QRegularExpression numericPid(QStringLiteral("^[0-9]+$"));
    static const QRegularExpression whitespace(QStringLiteral("\\s+"));
    for (const QString &entry : entries) {
        if (!numericPid.match(entry).hasMatch())
            continue;
        bool pidOk = false;
        const int pid = entry.toInt(&pidOk);
        if (!pidOk)
            continue;
        ++m_processCount;

        QFile commFile(QStringLiteral("/proc/%1/comm").arg(entry));
        if (!commFile.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;
        const QString name = QString::fromLocal8Bit(commFile.readLine()).trimmed();
        if (name.isEmpty())
            continue;

        qulonglong rssKb = 0;
        QFile statusFile(QStringLiteral("/proc/%1/status").arg(entry));
        if (statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QStringList statusLines = QString::fromLatin1(statusFile.readAll()).split(QLatin1Char('\n'));
            for (const QString &line : statusLines) {
                if (!line.startsWith(QStringLiteral("VmRSS:")))
                    continue;
                const QStringList values = line.mid(6).split(whitespace, Qt::SkipEmptyParts);
                if (!values.isEmpty())
                    rssKb = values.constFirst().toULongLong();
                break;
            }
        }

        double cpuPercent = 0.0;
        QFile statFile(QStringLiteral("/proc/%1/stat").arg(entry));
        if (statFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QString statLine = QString::fromLocal8Bit(statFile.readLine()).trimmed();
            const qsizetype closeParen = statLine.lastIndexOf(QLatin1Char(')'));
            if (closeParen >= 0) {
                const QStringList fields = statLine.mid(closeParen + 1).trimmed().split(whitespace, Qt::SkipEmptyParts);
                // Après le nom entre parenthèses, utime/stime sont aux indices 11 et 12.
                if (fields.size() > 12) {
                    bool userOk = false;
                    bool systemOk = false;
                    const qulonglong ticks = fields.at(11).toULongLong(&userOk) + fields.at(12).toULongLong(&systemOk);
                    if (userOk && systemOk) {
                        currentProcessTicks.insert(pid, ticks);
                        if (haveCpuDelta && totalTickDelta > 0 && m_previousProcessTicks.contains(pid)) {
                            const qulonglong previous = m_previousProcessTicks.value(pid);
                            if (ticks >= previous)
                                cpuPercent = std::clamp(100.0 * static_cast<double>(ticks - previous) / static_cast<double>(totalTickDelta), 0.0, 100.0);
                        }
                    }
                }
            }
        }

        result.append(QVariantMap {
            { QStringLiteral("pid"), pid },
            { QStringLiteral("name"), name },
            { QStringLiteral("cpuPercent"), cpuPercent },
            { QStringLiteral("memoryBytes"), rssKb * 1024 },
            { QStringLiteral("memoryPercent"), m_memoryTotalBytes > 0
                ? 100.0 * static_cast<double>(rssKb * 1024) / static_cast<double>(m_memoryTotalBytes) : 0.0 }
        });
    }

    m_previousProcessTicks = currentProcessTicks;
    std::sort(result.begin(), result.end(), [](const QVariant &left, const QVariant &right) {
        const QVariantMap a = left.toMap();
        const QVariantMap b = right.toMap();
        const double cpuA = a.value(QStringLiteral("cpuPercent")).toDouble();
        const double cpuB = b.value(QStringLiteral("cpuPercent")).toDouble();
        if (std::abs(cpuA - cpuB) > 0.05)
            return cpuA > cpuB;
        return a.value(QStringLiteral("memoryBytes")).toULongLong() > b.value(QStringLiteral("memoryBytes")).toULongLong();
    });
    if (result.size() > 120)
        result = result.mid(0, 120);
    return result;
}
