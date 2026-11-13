#include "ImageEditorBackend.hpp"
#include "ImagePreviewProvider.hpp"

#include <QFile>
#include <QImageReader>
#include <QTemporaryDir>
#include <QUrl>
#include <QtTest>

class ImageEditorBackendTest final : public QObject
{
    Q_OBJECT

private:
    static QImage fixtureImage()
    {
        QImage image(2, 3, QImage::Format_ARGB32);
        image.fill(Qt::transparent);
        image.setPixelColor(0, 0, QColor(230, 25, 35, 255));
        image.setPixelColor(1, 0, QColor(20, 210, 45, 220));
        image.setPixelColor(0, 1, QColor(30, 50, 220, 180));
        image.setPixelColor(1, 1, QColor(245, 190, 20, 255));
        image.setPixelColor(0, 2, QColor(80, 90, 100, 255));
        image.setPixelColor(1, 2, QColor(120, 130, 140, 255));
        return image;
    }

    static QByteArray readBytes(const QString &path)
    {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            return {};
        return file.readAll();
    }

private slots:
    void transformsUndoAndResetStayInMemory()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString input = dir.filePath(QStringLiteral("fixture.png"));
        const QImage fixture = fixtureImage();
        QVERIFY(fixture.save(input, "PNG"));

        ImageEditorBackend backend;
        QVERIFY(backend.openImage(QUrl::fromLocalFile(input).toString()));
        QCOMPARE(backend.imageWidth(), 2);
        QCOMPARE(backend.imageHeight(), 3);
        QVERIFY(!backend.dirty());
        QVERIFY(!backend.canUndo());

        backend.rotateRight();
        QCOMPARE(backend.imageWidth(), 3);
        QCOMPARE(backend.imageHeight(), 2);
        QVERIFY(backend.dirty());
        QVERIFY(backend.canUndo());

        backend.undo();
        QCOMPARE(backend.imageWidth(), 2);
        QCOMPARE(backend.imageHeight(), 3);
        QVERIFY(!backend.dirty());
        QVERIFY(!backend.canUndo());

        backend.convertToGrayscale();
        QVERIFY(backend.dirty());
        backend.resetToOriginal();
        QVERIFY(!backend.dirty());
        QVERIFY(backend.canUndo());
    }

    void previewProviderServesCurrentImage()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString input = dir.filePath(QStringLiteral("preview.png"));
        QVERIFY(fixtureImage().save(input, "PNG"));

        ImageEditorBackend backend;
        QVERIFY(backend.openImage(QUrl::fromLocalFile(input).toString()));
        const QUrl url(backend.previewUrl());
        const QString id = url.path().mid(1);
        ImagePreviewProvider provider;
        QSize originalSize;
        const QImage preview = provider.requestImage(id, &originalSize, QSize(100, 100));
        QVERIFY(!preview.isNull());
        QCOMPARE(originalSize, QSize(2, 3));
        QCOMPARE(preview.size(), QSize(2, 3));
        QCOMPARE(preview.pixelColor(0, 0), QColor(230, 25, 35, 255));
    }

    void exportWritesCopyAndRequiresOverwriteAuthorization()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString input = dir.filePath(QStringLiteral("source.png"));
        const QString output = dir.filePath(QStringLiteral("edited.png"));
        const QImage fixture = fixtureImage();
        QVERIFY(fixture.save(input, "PNG"));
        const QByteArray originalBytes = readBytes(input);
        QVERIFY(!originalBytes.isEmpty());

        ImageEditorBackend backend;
        QVERIFY(backend.openImage(QUrl::fromLocalFile(input).toString()));
        backend.convertToGrayscale();
        QVERIFY(backend.dirty());
        QVERIFY(backend.saveCopyAs(QUrl::fromLocalFile(output).toString(), false));
        QVERIFY(!backend.dirty());
        QCOMPARE(readBytes(input), originalBytes);

        QImage saved(output);
        QVERIFY(!saved.isNull());
        const QColor gray = saved.pixelColor(0, 0);
        QCOMPARE(gray.red(), gray.green());
        QCOMPARE(gray.green(), gray.blue());
        const QByteArray firstOutput = readBytes(output);

        backend.adjustBrightness(40);
        QVERIFY(backend.dirty());
        QVERIFY(!backend.saveCopyAs(QUrl::fromLocalFile(output).toString(), false));
        QCOMPARE(readBytes(output), firstOutput);
        QVERIFY(backend.saveCopyAs(QUrl::fromLocalFile(output).toString(), true));
        QVERIFY(!backend.dirty());
        QVERIFY(readBytes(output) != firstOutput);
        QCOMPARE(backend.imagePath(), output);
    }

    void rejectsRemoteLocationsAndUnsupportedExportFormats()
    {
        ImageEditorBackend backend;
        QVERIFY(!backend.openImage(QStringLiteral("https://example.invalid/photo.png")));
        QVERIFY(!backend.openImage(QStringLiteral("file://server/share/photo.png")));
        QVERIFY(backend.statusMessage().contains(QStringLiteral("locaux")));

        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString input = dir.filePath(QStringLiteral("fixture.png"));
        QVERIFY(fixtureImage().save(input, "PNG"));
        QVERIFY(backend.openImage(QUrl::fromLocalFile(input).toString()));
        QVERIFY(!backend.saveCopyAs(QUrl::fromLocalFile(dir.filePath(QStringLiteral("wrong.gif"))).toString(), false));
        QVERIFY(backend.statusMessage().contains(QStringLiteral("Format de sortie")));
    }

    void exportsEveryAdvertisedFormat()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString input = dir.filePath(QStringLiteral("fixture.png"));
        QVERIFY(fixtureImage().save(input, "PNG"));
        ImageEditorBackend backend;
        QVERIFY(backend.openImage(QUrl::fromLocalFile(input).toString()));

        const QStringList suffixes { QStringLiteral("png"), QStringLiteral("jpg"),
                                     QStringLiteral("webp"), QStringLiteral("bmp"),
                                     QStringLiteral("tiff") };
        for (const QString &suffix : suffixes) {
            const QString output = dir.filePath(QStringLiteral("copy.%1").arg(suffix));
            QVERIFY2(backend.saveCopyAs(QUrl::fromLocalFile(output).toString(), false),
                     qPrintable(backend.statusMessage()));
            QVERIFY2(QImageReader(output).canRead(), qPrintable(QStringLiteral("Cannot read %1 output").arg(suffix)));
        }
    }

    void refusesSymbolicLinkExportDestinations()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString input = dir.filePath(QStringLiteral("fixture.png"));
        const QString target = dir.filePath(QStringLiteral("target.png"));
        const QString link = dir.filePath(QStringLiteral("link.png"));
        QVERIFY(fixtureImage().save(input, "PNG"));
        QVERIFY(fixtureImage().save(target, "PNG"));
        QVERIFY(QFile::link(target, link));

        ImageEditorBackend backend;
        QVERIFY(backend.openImage(QUrl::fromLocalFile(input).toString()));
        QVERIFY(!backend.saveCopyAs(QUrl::fromLocalFile(link).toString(), true));
        QVERIFY(backend.statusMessage().contains(QStringLiteral("symbolique")));
        QImage unchanged(target);
        QVERIFY(!unchanged.isNull());
        QCOMPARE(unchanged.pixelColor(0, 0), QColor(230, 25, 35, 255));
    }
};

QTEST_GUILESS_MAIN(ImageEditorBackendTest)
#include "tst_imageeditorbackend.moc"
