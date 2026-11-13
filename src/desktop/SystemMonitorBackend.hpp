#pragma once

#include <QObject>
#include <QHash>
#include <QString>
#include <QVariantList>

class SystemMonitorBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double cpuUsagePercent READ cpuUsagePercent NOTIFY metricsChanged)
    Q_PROPERTY(qulonglong memoryTotalBytes READ memoryTotalBytes NOTIFY metricsChanged)
    Q_PROPERTY(qulonglong memoryUsedBytes READ memoryUsedBytes NOTIFY metricsChanged)
    Q_PROPERTY(double memoryUsagePercent READ memoryUsagePercent NOTIFY metricsChanged)
    Q_PROPERTY(int processCount READ processCount NOTIFY metricsChanged)
    Q_PROPERTY(QString uptimeText READ uptimeText NOTIFY metricsChanged)
    Q_PROPERTY(QString lastUpdated READ lastUpdated NOTIFY metricsChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY metricsChanged)
    Q_PROPERTY(QVariantList processes READ processes NOTIFY processesChanged)

public:
    explicit SystemMonitorBackend(QObject *parent = nullptr);

    double cpuUsagePercent() const { return m_cpuUsagePercent; }
    qulonglong memoryTotalBytes() const { return m_memoryTotalBytes; }
    qulonglong memoryUsedBytes() const { return m_memoryUsedBytes; }
    double memoryUsagePercent() const { return m_memoryUsagePercent; }
    int processCount() const { return m_processCount; }
    QString uptimeText() const { return m_uptimeText; }
    QString lastUpdated() const { return m_lastUpdated; }
    QString statusMessage() const { return m_statusMessage; }
    QVariantList processes() const { return m_processes; }

    Q_INVOKABLE void refresh();

signals:
    void metricsChanged();
    void processesChanged();

private:
    bool readCpuTicks(qulonglong *totalTicks, qulonglong *idleTicks) const;
    bool readMemory(qulonglong *totalBytes, qulonglong *availableBytes) const;
    QString readUptime() const;
    QVariantList readProcesses(qulonglong totalTickDelta, bool haveCpuDelta);

    double m_cpuUsagePercent = 0.0;
    qulonglong m_memoryTotalBytes = 0;
    qulonglong m_memoryUsedBytes = 0;
    double m_memoryUsagePercent = 0.0;
    int m_processCount = 0;
    QString m_uptimeText;
    QString m_lastUpdated;
    QString m_statusMessage = QStringLiteral("Lecture seule des métriques Linux.");
    QVariantList m_processes;
    QHash<int, qulonglong> m_previousProcessTicks;
    qulonglong m_previousTotalTicks = 0;
    qulonglong m_previousIdleTicks = 0;
    bool m_hasPreviousCpuSample = false;
};
