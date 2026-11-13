#include "AssistantBackend.hpp"

#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QTcpServer>
#include <QTcpSocket>
#include <QtTest>

namespace {
QByteArray completionResponse(const QString &actionType, const QString &actionValue)
{
    const QJsonObject assistantContent {
        { QStringLiteral("message"), QStringLiteral("Réponse de test." ) },
        { QStringLiteral("code"), QStringLiteral("import QtQuick 2.15\\nItem {}" ) },
        { QStringLiteral("action"), QJsonObject {
              { QStringLiteral("type"), actionType },
              { QStringLiteral("value"), actionValue }
          } }
    };
    const QString content = QString::fromUtf8(QJsonDocument(assistantContent).toJson(QJsonDocument::Compact));
    const QJsonObject envelope {
        { QStringLiteral("choices"), QJsonArray {
              QJsonObject { { QStringLiteral("message"), QJsonObject {
                    { QStringLiteral("content"), content }
                } } }
          } }
    };
    return QJsonDocument(envelope).toJson(QJsonDocument::Compact);
}

void serveOneRequest(QTcpServer *server, const QByteArray &responseBody,
                     QByteArray *rawRequest, bool *responseSent)
{
    QObject::connect(server, &QTcpServer::newConnection, server,
                     [server, responseBody, rawRequest, responseSent]() {
        QTcpSocket *socket = server->nextPendingConnection();
        auto *buffer = new QByteArray;
        QObject::connect(socket, &QTcpSocket::readyRead, socket,
                         [socket, buffer, responseBody, rawRequest, responseSent]() {
            buffer->append(socket->readAll());
            const qsizetype headerEnd = buffer->indexOf("\r\n\r\n");
            if (headerEnd < 0)
                return;

            const QString headers = QString::fromLatin1(buffer->left(headerEnd));
            const QRegularExpression contentLengthExpression(
                QStringLiteral("(?:^|\\r\\n)content-length:\\s*(\\d+)"),
                QRegularExpression::CaseInsensitiveOption);
            const QRegularExpressionMatch match = contentLengthExpression.match(headers);
            if (!match.hasMatch())
                return;
            const qsizetype contentLength = match.captured(1).toLongLong();
            if (buffer->size() < headerEnd + 4 + contentLength || *responseSent)
                return;

            *rawRequest = *buffer;
            *responseSent = true;
            const QByteArray response = QByteArrayLiteral("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\nContent-Length: ")
                    + QByteArray::number(responseBody.size()) + QByteArrayLiteral("\r\n\r\n") + responseBody;
            socket->write(response);
            socket->disconnectFromHost();
        });
        QObject::connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
    });
}
}

class AssistantBackendTest final : public QObject
{
    Q_OBJECT

private slots:
    void rejectsInsecureRemoteAndEmbeddedCredentials()
    {
        AssistantBackend backend;
        QVERIFY(!backend.ask(QStringLiteral("bonjour"),
                             QStringLiteral("http://example.invalid/v1/chat/completions"),
                             QStringLiteral("fixture-model"), QStringLiteral("secret")));
        QVERIFY(backend.error().contains(QStringLiteral("HTTPS")));
        QVERIFY(!backend.busy());

        QVERIFY(!backend.ask(QStringLiteral("bonjour"),
                             QStringLiteral("https://user:pass@example.invalid/v1/chat/completions"),
                             QStringLiteral("fixture-model"), QStringLiteral("secret")));
        QVERIFY(backend.error().contains(QStringLiteral("identifiants")));

        QVERIFY(!backend.ask(QStringLiteral("bonjour"),
                             QStringLiteral("https://api.example.invalid/v1/chat/completions"),
                             QStringLiteral("fixture-model"), QString()));
        QVERIFY(backend.error().contains(QStringLiteral("clé API")));
    }

    void sendsLocalChatRequestAndParsesAllowedAction()
    {
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost, 0));
        const QByteArray responseBody = completionResponse(QStringLiteral("open_app"), QStringLiteral("games"));
        QByteArray rawRequest;
        bool responseSent = false;
        serveOneRequest(&server, responseBody, &rawRequest, &responseSent);

        AssistantBackend backend;
        QSignalSpy completed(&backend, &AssistantBackend::requestCompleted);
        const QString endpoint = QStringLiteral("http://127.0.0.1:%1/v1/chat/completions").arg(server.serverPort());
        QVERIFY(backend.ask(QStringLiteral("Ouvre les mini-jeux"), endpoint,
                            QStringLiteral("fixture-model"), QStringLiteral("local-test-key")));
        QTRY_COMPARE_WITH_TIMEOUT(completed.size(), 1, 5000);
        QVERIFY(completed.first().at(0).toBool());
        QVERIFY(responseSent);
        QVERIFY(rawRequest.contains("Authorization: Bearer local-test-key"));

        const qsizetype bodyStart = rawRequest.indexOf("\r\n\r\n") + 4;
        const QJsonDocument requestDocument = QJsonDocument::fromJson(rawRequest.mid(bodyStart));
        QVERIFY(requestDocument.isObject());
        const QJsonObject request = requestDocument.object();
        QCOMPARE(request.value(QStringLiteral("model")).toString(), QStringLiteral("fixture-model"));
        QVERIFY(!request.contains(QStringLiteral("tools")));
        const QJsonArray messages = request.value(QStringLiteral("messages")).toArray();
        QCOMPARE(messages.size(), 2);
        QCOMPARE(messages.at(1).toObject().value(QStringLiteral("content")).toString(),
                 QStringLiteral("Ouvre les mini-jeux"));
        QCOMPARE(backend.answer(), QStringLiteral("Réponse de test."));
        QCOMPARE(backend.codeDraft(), QStringLiteral("import QtQuick 2.15\\nItem {}"));
        QCOMPARE(backend.actionType(), QStringLiteral("open_app"));
        QCOMPARE(backend.actionValue(), QStringLiteral("games"));
        QVERIFY(!backend.busy());
    }

    void ignoresUnlistedActionWithoutExecutingIt()
    {
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost, 0));
        const QByteArray responseBody = completionResponse(QStringLiteral("run_shell"), QStringLiteral("rm -rf /"));
        QByteArray rawRequest;
        bool responseSent = false;
        serveOneRequest(&server, responseBody, &rawRequest, &responseSent);

        AssistantBackend backend;
        QSignalSpy completed(&backend, &AssistantBackend::requestCompleted);
        const QString endpoint = QStringLiteral("http://localhost:%1/v1/chat/completions").arg(server.serverPort());
        QVERIFY(backend.ask(QStringLiteral("Fais quelque chose"), endpoint,
                            QStringLiteral("fixture-model"), QString()));
        QTRY_COMPARE_WITH_TIMEOUT(completed.size(), 1, 5000);
        QVERIFY(completed.first().at(0).toBool());
        QCOMPARE(backend.actionType(), QStringLiteral("none"));
        QVERIFY(backend.actionValue().isEmpty());
        QVERIFY(backend.error().contains(QStringLiteral("ignorée")));
        QVERIFY(responseSent);
        QVERIFY(!backend.busy());
    }
};

QTEST_GUILESS_MAIN(AssistantBackendTest)
#include "tst_assistantbackend.moc"
