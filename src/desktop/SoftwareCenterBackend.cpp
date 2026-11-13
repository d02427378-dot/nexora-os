#include "SoftwareCenterBackend.hpp"

#include <QTimer>

namespace {
const QString kAptCache = QStringLiteral("/usr/bin/apt-cache");
const QString kDpkgQuery = QStringLiteral("/usr/bin/dpkg-query");
const QString kPkexec = QStringLiteral("/usr/bin/pkexec");
const QString kAptGet = QStringLiteral("/usr/bin/apt-get");
}

SoftwareCenterBackend::SoftwareCenterBackend(QObject *parent)
    : QObject(parent)
{
    m_process.setProcessChannelMode(QProcess::MergedChannels);
    connect(&m_process, &QProcess::finished,
            this, &SoftwareCenterBackend::processFinished);
    connect(&m_process, &QProcess::errorOccurred,
            this, &SoftwareCenterBackend::processError);
}

const QList<SoftwareCenterBackend::CatalogEntry> &SoftwareCenterBackend::catalog()
{
    static const QList<CatalogEntry> entries {
        { QStringLiteral("firefox-esr"), QStringLiteral("Firefox ESR"), QStringLiteral("Internet"), QStringLiteral("Navigateur web à support étendu." ) },
        { QStringLiteral("gimp"), QStringLiteral("GIMP"), QStringLiteral("Création"), QStringLiteral("Retouche et composition d’images." ) },
        { QStringLiteral("krita"), QStringLiteral("Krita"), QStringLiteral("Création"), QStringLiteral("Peinture numérique et illustration." ) },
        { QStringLiteral("vlc"), QStringLiteral("VLC"), QStringLiteral("Audio et vidéo"), QStringLiteral("Lecteur multimédia multi-format." ) },
        { QStringLiteral("kdenlive"), QStringLiteral("Kdenlive"), QStringLiteral("Création"), QStringLiteral("Montage vidéo non linéaire." ) },
        { QStringLiteral("audacity"), QStringLiteral("Audacity"), QStringLiteral("Audio et vidéo"), QStringLiteral("Enregistrement et édition audio." ) },
        { QStringLiteral("inkscape"), QStringLiteral("Inkscape"), QStringLiteral("Création"), QStringLiteral("Dessin vectoriel SVG." ) },
        { QStringLiteral("keepassxc"), QStringLiteral("KeePassXC"), QStringLiteral("Sécurité"), QStringLiteral("Gestionnaire local de mots de passe." ) },
        { QStringLiteral("thunderbird"), QStringLiteral("Thunderbird"), QStringLiteral("Internet"), QStringLiteral("Client de courrier électronique." ) },
        { QStringLiteral("libreoffice-writer"), QStringLiteral("LibreOffice Writer"), QStringLiteral("Bureautique"), QStringLiteral("Traitement de texte." ) },
        { QStringLiteral("ark"), QStringLiteral("Ark"), QStringLiteral("Utilitaires"), QStringLiteral("Gestionnaire d’archives graphiques." ) },
        { QStringLiteral("neovim"), QStringLiteral("Neovim"), QStringLiteral("Développement"), QStringLiteral("Éditeur de texte en terminal." ) }
    };
    return entries;
}

void SoftwareCenterBackend::refresh()
{
    if (m_busy || m_process.state() != QProcess::NotRunning)
        return;

    m_task = Task::RefreshApt;
    m_refreshIndex = 0;
    m_refreshResults.clear();
    setBusy(true);
    setStatusMessage(QStringLiteral("Lecture des paquets depuis les index APT locaux…"));
    startRefreshPackage();
}

bool SoftwareCenterBackend::isCatalogPackage(const QString &packageId) const
{
    for (const CatalogEntry &entry : catalog()) {
        if (entry.id == packageId)
            return true;
    }
    return false;
}

bool SoftwareCenterBackend::previewInstall(const QString &packageId)
{
    if (m_busy || !isCatalogPackage(packageId))
        return false;
    const QVariantMap record = findPackage(packageId);
    if (record.isEmpty() || !record.value(QStringLiteral("available")).toBool()
            || record.value(QStringLiteral("installed")).toBool())
        return false;
    startSimulation(packageId, QStringLiteral("install"));
    return true;
}

bool SoftwareCenterBackend::previewRemove(const QString &packageId)
{
    if (m_busy || !isCatalogPackage(packageId))
        return false;
    const QVariantMap record = findPackage(packageId);
    if (record.isEmpty() || !record.value(QStringLiteral("installed")).toBool())
        return false;
    startSimulation(packageId, QStringLiteral("remove"));
    return true;
}

bool SoftwareCenterBackend::confirmInstall(const QString &packageId)
{
    if (!m_simulationReady || m_simulationPackage != packageId
            || m_simulationAction != QStringLiteral("install"))
        return false;
    const QVariantMap record = findPackage(packageId);
    if (record.isEmpty() || !record.value(QStringLiteral("available")).toBool()
            || record.value(QStringLiteral("installed")).toBool())
        return false;
    setSimulationReady(false);
    return startMutation(packageId, QStringLiteral("install"));
}

bool SoftwareCenterBackend::confirmRemove(const QString &packageId)
{
    if (!m_simulationReady || m_simulationPackage != packageId
            || m_simulationAction != QStringLiteral("remove"))
        return false;
    const QVariantMap record = findPackage(packageId);
    if (record.isEmpty() || !record.value(QStringLiteral("installed")).toBool())
        return false;
    setSimulationReady(false);
    return startMutation(packageId, QStringLiteral("remove"));
}

void SoftwareCenterBackend::startRefreshPackage()
{
    if (m_refreshIndex >= catalog().size()) {
        completeRefresh();
        return;
    }

    const CatalogEntry &entry = catalog().at(m_refreshIndex);
    m_currentRecord = {
        { QStringLiteral("id"), entry.id },
        { QStringLiteral("title"), entry.title },
        { QStringLiteral("category"), entry.category },
        { QStringLiteral("description"), entry.description },
        { QStringLiteral("available"), false },
        { QStringLiteral("installed"), false },
        { QStringLiteral("version"), QString() },
        { QStringLiteral("installedVersion"), QString() }
    };
    setStatusMessage(QStringLiteral("Vérification de %1…").arg(entry.title));
    m_task = Task::RefreshApt;
    m_process.start(kAptCache, { QStringLiteral("show"), entry.id });
}

void SoftwareCenterBackend::startDpkgQuery()
{
    const QString packageId = m_currentRecord.value(QStringLiteral("id")).toString();
    m_task = Task::RefreshDpkg;
    m_process.start(kDpkgQuery, {
        QStringLiteral("-W"),
        QStringLiteral("-f=${db:Status-Status}\\t${Version}"),
        packageId
    });
}

void SoftwareCenterBackend::startSimulation(const QString &packageId, const QString &action)
{
    m_simulationPackage = packageId;
    m_simulationAction = action;
    m_simulationOutput.clear();
    setSimulationReady(false);
    setOperationOutput(QString());
    m_task = action == QStringLiteral("install") ? Task::SimulateInstall : Task::SimulateRemove;
    setBusy(true);
    setStatusMessage(QStringLiteral("Simulation APT en lecture seule pour %1…").arg(packageId));
    m_process.start(kAptGet, {
        QStringLiteral("-s"),
        QStringLiteral("--no-install-recommends"),
        action,
        QStringLiteral("--"),
        packageId
    });
}

bool SoftwareCenterBackend::startMutation(const QString &packageId, const QString &action)
{
    if (!isCatalogPackage(packageId) || m_busy || m_process.state() != QProcess::NotRunning)
        return false;

    m_task = action == QStringLiteral("install") ? Task::Install : Task::Remove;
    setOperationOutput(QString());
    setBusy(true);
    setStatusMessage(QStringLiteral("Demande d’autorisation système pour %1 %2…")
                     .arg(action == QStringLiteral("install") ? QStringLiteral("installer") : QStringLiteral("retirer"), packageId));
    m_process.start(kPkexec, {
        kAptGet,
        QStringLiteral("-y"),
        QStringLiteral("--no-install-recommends"),
        action,
        QStringLiteral("--"),
        packageId
    });
    return true;
}

void SoftwareCenterBackend::processFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    const QString output = QString::fromLocal8Bit(m_process.readAll());
    const bool success = exitStatus == QProcess::NormalExit && exitCode == 0;

    switch (m_task) {
    case Task::RefreshApt: {
        const QString version = aptField(output, QStringLiteral("Version"));
        const QString description = aptField(output, QStringLiteral("Description"));
        m_currentRecord.insert(QStringLiteral("available"), !version.isEmpty());
        if (!version.isEmpty())
            m_currentRecord.insert(QStringLiteral("version"), version);
        if (!description.isEmpty())
            m_currentRecord.insert(QStringLiteral("description"), description);
        startDpkgQuery();
        break;
    }
    case Task::RefreshDpkg: {
        const QStringList fields = output.trimmed().split(QLatin1Char('\t'));
        const bool installed = !fields.isEmpty() && fields.at(0).trimmed() == QStringLiteral("installed");
        m_currentRecord.insert(QStringLiteral("installed"), installed);
        if (installed && fields.size() > 1)
            m_currentRecord.insert(QStringLiteral("installedVersion"), fields.at(1).trimmed());
        m_refreshResults.append(m_currentRecord);
        ++m_refreshIndex;
        startRefreshPackage();
        break;
    }
    case Task::SimulateInstall:
    case Task::SimulateRemove:
        m_simulationOutput = boundedText(output);
        setOperationOutput(m_simulationOutput);
        setBusy(false);
        m_task = Task::Idle;
        if (success) {
            setStatusMessage(QStringLiteral("Simulation prête. Vérifiez les changements proposés avant de confirmer."));
            setSimulationReady(true);
        } else {
            setStatusMessage(QStringLiteral("La simulation APT a échoué; aucune modification n’a été effectuée."));
            setSimulationReady(false);
        }
        break;
    case Task::Install:
    case Task::Remove: {
        const QString action = m_task == Task::Install ? QStringLiteral("install") : QStringLiteral("remove");
        const QString packageId = m_simulationPackage;
        setOperationOutput(boundedText(output));
        setBusy(false);
        m_task = Task::Idle;
        setStatusMessage(success
            ? QStringLiteral("Opération APT terminée pour %1.").arg(packageId)
            : QStringLiteral("Opération APT annulée ou échouée pour %1; consultez le détail.").arg(packageId));
        emit operationFinished(packageId, action, success);
        if (success) {
            QTimer::singleShot(0, this, &SoftwareCenterBackend::refresh);
        }
        break;
    }
    case Task::Idle:
        break;
    }
}

void SoftwareCenterBackend::processError(QProcess::ProcessError error)
{
    if (error != QProcess::FailedToStart)
        return;
    failCurrentTask(QStringLiteral("Impossible de démarrer %1 : %2")
                    .arg(m_process.program(), m_process.errorString()));
}

void SoftwareCenterBackend::completeRefresh()
{
    m_packages = m_refreshResults;
    emit packagesChanged();
    int availableCount = 0;
    for (const QVariant &value : m_packages) {
        if (value.toMap().value(QStringLiteral("available")).toBool())
            ++availableCount;
    }
    m_task = Task::Idle;
    setBusy(false);
    setStatusMessage(QStringLiteral("%1 applications du catalogue, %2 disponibles dans les index APT configurés.")
                     .arg(m_packages.size()).arg(availableCount));
}

void SoftwareCenterBackend::failCurrentTask(const QString &reason)
{
    const Task failedTask = m_task;
    m_task = Task::Idle;
    setBusy(false);
    setStatusMessage(reason);
    if (failedTask == Task::SimulateInstall || failedTask == Task::SimulateRemove) {
        setSimulationReady(false);
        setOperationOutput(reason);
    } else if (failedTask == Task::Install || failedTask == Task::Remove) {
        const QString action = failedTask == Task::Install ? QStringLiteral("install") : QStringLiteral("remove");
        setOperationOutput(reason);
        emit operationFinished(m_simulationPackage, action, false);
    }
}

QVariantMap SoftwareCenterBackend::findPackage(const QString &packageId) const
{
    for (const QVariant &value : m_packages) {
        const QVariantMap record = value.toMap();
        if (record.value(QStringLiteral("id")).toString() == packageId)
            return record;
    }
    return {};
}

QString SoftwareCenterBackend::aptField(const QString &text, const QString &field)
{
    const QString prefix = field + QLatin1Char(':');
    const QStringList lines = text.split(QLatin1Char('\n'));
    for (const QString &line : lines) {
        if (line.startsWith(prefix))
            return line.mid(prefix.size()).trimmed();
    }
    return {};
}

void SoftwareCenterBackend::setBusy(bool value)
{
    if (m_busy == value)
        return;
    m_busy = value;
    emit busyChanged();
}

void SoftwareCenterBackend::setStatusMessage(const QString &value)
{
    if (m_statusMessage == value)
        return;
    m_statusMessage = value;
    emit statusMessageChanged();
}

void SoftwareCenterBackend::setSimulationReady(bool value)
{
    if (m_simulationReady == value)
        return;
    m_simulationReady = value;
    emit simulationReadyChanged();
}

void SoftwareCenterBackend::setOperationOutput(const QString &value)
{
    if (m_operationOutput == value)
        return;
    m_operationOutput = value;
    emit operationOutputChanged();
}

QString SoftwareCenterBackend::boundedText(const QString &value, qsizetype limit)
{
    if (value.size() <= limit)
        return value;
    return QStringLiteral("[…début tronqué…]\n") + value.right(limit);
}
