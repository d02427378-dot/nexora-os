#include "TerminalBackend.hpp"

#include <QDir>
#include <QtTest>

class TerminalBackendTest final : public QObject
{
    Q_OBJECT

private slots:
    void commandOutputAndExitCode()
    {
        TerminalBackend backend;
        QVERIFY(backend.execute(QStringLiteral("printf 'NEXORA_SAFE_TEST\\n'")));
        QTRY_VERIFY_WITH_TIMEOUT(!backend.running(), 5000);
        QVERIFY(backend.output().contains(QStringLiteral("NEXORA_SAFE_TEST")));
        QVERIFY(!backend.output().contains(QStringLiteral("__NEXORA_")));
        QCOMPARE(backend.lastExitCode(), 0);
    }

    void workingDirectoryPersistsAcrossCommands()
    {
        TerminalBackend backend;
        QVERIFY(backend.execute(QStringLiteral("cd /tmp")));
        QTRY_VERIFY_WITH_TIMEOUT(!backend.running(), 5000);
        QCOMPARE(QDir::cleanPath(backend.workingDirectory()), QStringLiteral("/tmp"));

        QVERIFY(backend.execute(QStringLiteral("pwd")));
        QTRY_VERIFY_WITH_TIMEOUT(!backend.running(), 5000);
        QVERIFY(backend.output().contains(QStringLiteral("\n/tmp\n")));
        QCOMPARE(backend.lastExitCode(), 0);
    }

    void concurrentCommandIsRejectedAndProcessCanBeCancelled()
    {
        TerminalBackend backend;
        QVERIFY(backend.execute(QStringLiteral("sleep 10")));
        QTest::qWait(100);
        QVERIFY(backend.running());
        QVERIFY(!backend.execute(QStringLiteral("printf 'should not run'")));
        backend.cancel();
        QTRY_VERIFY_WITH_TIMEOUT(!backend.running(), 3000);
    }
};

QTEST_GUILESS_MAIN(TerminalBackendTest)
#include "tst_terminalbackend.moc"
