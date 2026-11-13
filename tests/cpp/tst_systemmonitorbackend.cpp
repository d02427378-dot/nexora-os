#include <QMetaObject>
#include <QVariantMap>
#include <QtTest>

#include "SystemMonitorBackend.hpp"

class TestSystemMonitorBackend : public QObject
{
    Q_OBJECT

private slots:
    void readsLiveKernelMetrics()
    {
        SystemMonitorBackend backend;
        QVERIFY(backend.memoryTotalBytes() > 0);
        QVERIFY(backend.memoryUsedBytes() <= backend.memoryTotalBytes());
        QVERIFY(backend.memoryUsagePercent() >= 0.0);
        QVERIFY(backend.memoryUsagePercent() <= 100.0);
        QVERIFY(backend.cpuUsagePercent() >= 0.0);
        QVERIFY(backend.cpuUsagePercent() <= 100.0);
        QVERIFY(backend.processCount() > 0);
        QVERIFY(!backend.uptimeText().isEmpty());
        QVERIFY(!backend.lastUpdated().isEmpty());
        QVERIFY(backend.statusMessage().contains(QStringLiteral("lecture seule")));

        const QVariantList processList = backend.processes();
        QVERIFY(!processList.isEmpty());
        QVERIFY(processList.size() <= 120);
        const QVariantMap process = processList.constFirst().toMap();
        QVERIFY(process.value(QStringLiteral("pid")).toInt() > 0);
        QVERIFY(!process.value(QStringLiteral("name")).toString().isEmpty());
        QVERIFY(process.value(QStringLiteral("cpuPercent")).toDouble() >= 0.0);
        QVERIFY(process.value(QStringLiteral("memoryBytes")).toULongLong() <= backend.memoryTotalBytes());
    }

    void refreshUpdatesSnapshot()
    {
        SystemMonitorBackend backend;
        QSignalSpy metricsSpy(&backend, &SystemMonitorBackend::metricsChanged);
        backend.refresh();
        QCOMPARE(metricsSpy.count(), 1);
        QVERIFY(backend.memoryTotalBytes() > 0);
        QVERIFY(backend.processCount() > 0);
    }

    void exposesNoProcessControlMethods()
    {
        const QMetaObject *meta = &SystemMonitorBackend::staticMetaObject;
        QVERIFY(meta->indexOfMethod("killProcess(int)") < 0);
        QVERIFY(meta->indexOfMethod("terminateProcess(int)") < 0);
        QVERIFY(meta->indexOfMethod("suspendProcess(int)") < 0);
    }
};

QTEST_GUILESS_MAIN(TestSystemMonitorBackend)
#include "tst_systemmonitorbackend.moc"
