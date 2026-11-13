#include <QCoreApplication>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QQmlApplicationEngine>
#include <QFileInfo>
#include <QUrl>
#include <QDebug>
#include <cstdlib>
#include <qqml.h>

#include "AssistantBackend.hpp"
#include "TerminalBackend.hpp"
#include "CodeEditorBackend.hpp"
#include "ImageEditorBackend.hpp"
#include "ImagePreviewProvider.hpp"
#include "SoftwareCenterBackend.hpp"
#include "SystemMonitorBackend.hpp"

int main(int argc, char *argv[])
{
    // Qt WebEngine/QML doit partager son contexte OpenGL avant toute
    // construction de QGuiApplication ou d’un moteur QML.
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGLRhi);

    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("Nexora OS"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.1.0"));
    QCoreApplication::setOrganizationName(QStringLiteral("Nexora"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("nexora-os.org"));
    qmlRegisterType<TerminalBackend>("Nexora.Terminal", 1, 0, "TerminalBackend");
    qmlRegisterType<CodeEditorBackend>("Nexora.Editor", 1, 0, "CodeEditorBackend");
    qmlRegisterType<ImageEditorBackend>("Nexora.Images", 1, 0, "ImageEditorBackend");
    qmlRegisterType<SoftwareCenterBackend>("Nexora.Store", 1, 0, "SoftwareCenterBackend");
    qmlRegisterType<SystemMonitorBackend>("Nexora.System", 1, 0, "SystemMonitorBackend");
    qmlRegisterType<AssistantBackend>("Nexora.Assistant", 1, 0, "AssistantBackend");

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("nexora-image"), new ImagePreviewProvider);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [&app](QObject *object, const QUrl &url) {
            if (object == nullptr) {
                qCritical() << "Impossible de charger l’interface Nexora:" << url;
                QCoreApplication::exit(EXIT_FAILURE);
            }
        },
        Qt::QueuedConnection);

    QUrl shellUrl;
    if (argc > 1) {
        const QFileInfo qmlFile(QString::fromLocal8Bit(argv[1]));
        shellUrl = QUrl::fromLocalFile(qmlFile.absoluteFilePath());
    } else {
        shellUrl = QUrl::fromLocalFile(QStringLiteral(NEXORA_DEFAULT_QML_PATH));
    }

    engine.load(shellUrl);
    if (engine.rootObjects().isEmpty())
        return EXIT_FAILURE;

    return app.exec();
}
