#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class SoftwareCenterBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList packages READ packages NOTIFY packagesChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool simulationReady READ simulationReady NOTIFY simulationReadyChanged)
    Q_PROPERTY(QString simulationPackage READ simulationPackage NOTIFY simulationReadyChanged)
    Q_PROPERTY(QString simulationAction READ simulationAction NOTIFY simulationReadyChanged)
    Q_PROPERTY(QString simulationOutput READ simulationOutput NOTIFY simulationReadyChanged)
    Q_PROPERTY(QString operationOutput READ operationOutput NOTIFY operationOutputChanged)

public:
    explicit SoftwareCenterBackend(QObject *parent = nullptr);
    ~SoftwareCenterBackend() override = default;

    QVariantList packages() const { return m_packages; }
    bool busy() const { return m_busy; }
    QString statusMessage() const { return m_statusMessage; }
    bool simulationReady() const { return m_simulationReady; }
    QString simulationPackage() const { return m_simulationPackage; }
    QString simulationAction() const { return m_simulationAction; }
    QString simulationOutput() const { return m_simulationOutput; }
    QString operationOutput() const { return m_operationOutput; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool previewInstall(const QString &packageId);
    Q_INVOKABLE bool previewRemove(const QString &packageId);
    Q_INVOKABLE bool confirmInstall(const QString &packageId);
    Q_INVOKABLE bool confirmRemove(const QString &packageId);
    Q_INVOKABLE bool isCatalogPackage(const QString &packageId) const;

signals:
    void packagesChanged();
    void busyChanged();
    void statusMessageChanged();
    void simulationReadyChanged();
    void operationOutputChanged();
    void operationFinished(const QString &packageId, const QString &action, bool success);

private slots:
    void processFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void processError(QProcess::ProcessError error);

private:
    enum class Task {
        Idle,
        RefreshApt,
        RefreshDpkg,
        SimulateInstall,
        SimulateRemove,
        Install,
        Remove
    };

    struct CatalogEntry {
        QString id;
        QString title;
        QString category;
        QString description;
    };

    static const QList<CatalogEntry> &catalog();
    static QString aptField(const QString &text, const QString &field);
    QVariantMap findPackage(const QString &packageId) const;
    void setBusy(bool value);
    void setStatusMessage(const QString &value);
    void startRefreshPackage();
    void startDpkgQuery();
    void startSimulation(const QString &packageId, const QString &action);
    bool startMutation(const QString &packageId, const QString &action);
    void completeRefresh();
    void failCurrentTask(const QString &reason);
    void setSimulationReady(bool value);
    void setOperationOutput(const QString &value);
    static QString boundedText(const QString &value, qsizetype limit = 24000);

    QProcess m_process;
    QVariantList m_packages;
    QVariantList m_refreshResults;
    QVariantMap m_currentRecord;
    QString m_statusMessage;
    QString m_simulationPackage;
    QString m_simulationAction;
    QString m_simulationOutput;
    QString m_operationOutput;
    Task m_task = Task::Idle;
    int m_refreshIndex = 0;
    bool m_busy = false;
    bool m_simulationReady = false;
};
