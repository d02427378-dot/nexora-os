#include "SoftwareCenterBackend.hpp"

#include <QtTest>

class SoftwareCenterBackendTest final : public QObject
{
    Q_OBJECT

private slots:
    void catalogIsExplicitAndClosed()
    {
        SoftwareCenterBackend backend;
        QVERIFY(backend.isCatalogPackage(QStringLiteral("vlc")));
        QVERIFY(backend.isCatalogPackage(QStringLiteral("krita")));
        QVERIFY(!backend.isCatalogPackage(QStringLiteral("bash")));
        QVERIFY(!backend.isCatalogPackage(QStringLiteral("gparted")));
        QVERIFY(!backend.isCatalogPackage(QStringLiteral("vlc;rm-rf")));
        QVERIFY(!backend.isCatalogPackage(QStringLiteral("--help")));
    }

    void mutationsRequireSuccessfulSimulation()
    {
        SoftwareCenterBackend backend;
        QVERIFY(!backend.confirmInstall(QStringLiteral("vlc")));
        QVERIFY(!backend.confirmRemove(QStringLiteral("vlc")));
        QVERIFY(!backend.previewInstall(QStringLiteral("bash")));
        QVERIFY(!backend.previewRemove(QStringLiteral("gparted")));
        QVERIFY(!backend.busy());
    }
};

QTEST_GUILESS_MAIN(SoftwareCenterBackendTest)
#include "tst_softwarecenterbackend.moc"
