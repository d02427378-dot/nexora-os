#include "CodeEditorBackend.hpp"

#include <QFile>
#include <QTemporaryDir>
#include <QtTest>
#include <QUrl>

class CodeEditorBackendTest final : public QObject
{
    Q_OBJECT

private:
    static bool writeFile(const QString &path, const QByteArray &bytes)
    {
        QFile file(path);
        return file.open(QIODevice::WriteOnly) && file.write(bytes) == bytes.size();
    }

    static QByteArray readFile(const QString &path)
    {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            return {};
        return file.readAll();
    }

private slots:
    void opensEditsAndSavesOnlyWhenRequested()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString path = dir.filePath(QStringLiteral("hello.qml"));
        QVERIFY(writeFile(path, QByteArray("Item {\n    width: 320\n}\n")));

        CodeEditorBackend backend;
        QVERIFY(backend.openFile(QUrl::fromLocalFile(path).toString()));
        QCOMPARE(backend.content(), QStringLiteral("Item {\n    width: 320\n}\n"));
        QVERIFY(!backend.dirty());
        QCOMPARE(backend.filePath(), path);

        backend.setContent(QStringLiteral("Item {\n    width: 640\n}\n"));
        QVERIFY(backend.dirty());
        QVERIFY(backend.saveCurrent());
        QVERIFY(!backend.dirty());
        QCOMPARE(readFile(path), QByteArray("Item {\n    width: 640\n}\n"));
    }

    void saveAsRequiresOverwriteAuthorization()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString path = dir.filePath(QStringLiteral("existing.txt"));
        QVERIFY(writeFile(path, QByteArray("keep this until confirmed\n")));

        CodeEditorBackend backend;
        backend.newDocument();
        backend.setContent(QStringLiteral("replacement\n"));
        const QString url = QUrl::fromLocalFile(path).toString();
        QVERIFY(!backend.saveAsFile(url, false));
        QCOMPARE(readFile(path), QByteArray("keep this until confirmed\n"));
        QVERIFY(backend.saveAsFile(url, true));
        QCOMPARE(readFile(path), QByteArray("replacement\n"));
        QVERIFY(!backend.dirty());
    }

    void rejectsRemoteUrlsAndBinaryFiles()
    {
        CodeEditorBackend backend;
        QVERIFY(!backend.openFile(QStringLiteral("https://example.invalid/code.qml")));
        QVERIFY(backend.statusMessage().contains(QStringLiteral("locaux")));
        QVERIFY(!backend.openFile(QStringLiteral("file://server/share/code.qml")));

        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString path = dir.filePath(QStringLiteral("binary.dat"));
        QVERIFY(writeFile(path, QByteArray("text\0binary", 11)));
        QVERIFY(!backend.openFile(QUrl::fromLocalFile(path).toString()));
        QVERIFY(backend.statusMessage().contains(QStringLiteral("octets nuls")));
    }
};

QTEST_GUILESS_MAIN(CodeEditorBackendTest)
#include "tst_codeeditorbackend.moc"
