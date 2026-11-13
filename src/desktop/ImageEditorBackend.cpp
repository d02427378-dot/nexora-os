#include "ImageEditorBackend.hpp"

#include "ImagePreviewProvider.hpp"

#include <QDir>
#include <QFileInfo>
#include <QImageReader>
#include <QImageWriter>
#include <QMutex>
#include <QSaveFile>
#include <QTransform>
#include <QUrl>
#include <algorithm>
#include <atomic>

namespace {
std::atomic<quint64> nextPreviewId { 1 };

int boundedAmount(int amount)
{
    return std::clamp(amount, -100, 100);
}
}

ImageEditorBackend::ImageEditorBackend(QObject *parent)
    : QObject(parent),
      m_previewKey(QStringLiteral("image-%1").arg(nextPreviewId.fetch_add(1)))
{
}

ImageEditorBackend::~ImageEditorBackend()
{
    ImagePreviewProvider::removeImage(m_previewKey);
}

QString ImageEditorBackend::previewUrl() const
{
    return hasImage()
            ? QStringLiteral("image://nexora-image/%1/%2").arg(m_previewKey).arg(m_previewRevision)
            : QString();
}

bool ImageEditorBackend::openImage(const QString &urlString)
{
    QString path;
    QString error;
    if (!localPathFromUrl(urlString, &path, &error)) {
        setStatusMessage(error);
        return false;
    }

    QFileInfo info(path);
    if (info.isSymLink()) {
        const QString canonical = info.canonicalFilePath();
        if (canonical.isEmpty()) {
            setStatusMessage(QStringLiteral("Le lien symbolique ne pointe vers aucune image."));
            return false;
        }
        path = canonical;
        info.setFile(path);
    }
    if (!info.exists() || !info.isFile()) {
        setStatusMessage(QStringLiteral("Le chemin sélectionné n’est pas un fichier ordinaire."));
        return false;
    }
    if (info.size() > kMaxInputBytes) {
        setStatusMessage(QStringLiteral("Image compressée trop volumineuse : limite de 40 Mio."));
        return false;
    }

    QImageReader::setAllocationLimit(256);
    QImageReader reader(path);
    reader.setAutoTransform(true);
    const QSize sourceSize = reader.size();
    if (sourceSize.isValid()
            && (sourceSize.width() > kMaxPixels / sourceSize.height()
                || qint64(sourceSize.width()) * sourceSize.height() > kMaxPixels)) {
        setStatusMessage(QStringLiteral("Image trop grande : limite de 16 mégapixels."));
        return false;
    }

    QImage loaded = reader.read();
    if (loaded.isNull()) {
        setStatusMessage(QStringLiteral("Impossible de décoder cette image : %1").arg(reader.errorString()));
        return false;
    }
    if (loaded.width() <= 0 || loaded.height() <= 0
            || qint64(loaded.width()) * loaded.height() > kMaxPixels) {
        setStatusMessage(QStringLiteral("Image trop grande : limite de 16 mégapixels."));
        return false;
    }

    m_imagePath = path;
    m_original = loaded;
    m_image = loaded;
    m_undoStack.clear();
    m_dirty = false;
    updatePreview();
    emit documentChanged();
    emit historyChanged();
    QString details = QStringLiteral("Image chargée · %1 × %2 · %3")
                              .arg(loaded.width()).arg(loaded.height()).arg(reader.format().toUpper());
    if (reader.supportsAnimation())
        details += QStringLiteral(" · première image uniquement");
    setStatusMessage(details);
    return true;
}

void ImageEditorBackend::rotateLeft()
{
    if (!hasImage())
        return;
    QTransform transform;
    transform.rotate(-90);
    applyTransform(m_image.transformed(transform, Qt::SmoothTransformation), QStringLiteral("Rotation 90° gauche prête en mémoire."));
}

void ImageEditorBackend::rotateRight()
{
    if (!hasImage())
        return;
    QTransform transform;
    transform.rotate(90);
    applyTransform(m_image.transformed(transform, Qt::SmoothTransformation), QStringLiteral("Rotation 90° droite prête en mémoire."));
}

void ImageEditorBackend::flipHorizontal()
{
    if (hasImage())
        applyTransform(m_image.mirrored(true, false), QStringLiteral("Retournement horizontal prêt en mémoire."));
}

void ImageEditorBackend::flipVertical()
{
    if (hasImage())
        applyTransform(m_image.mirrored(false, true), QStringLiteral("Retournement vertical prêt en mémoire."));
}

void ImageEditorBackend::convertToGrayscale()
{
    if (!hasImage())
        return;
    QImage result = m_image.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < result.height(); ++y) {
        auto *line = reinterpret_cast<QRgb *>(result.scanLine(y));
        for (int x = 0; x < result.width(); ++x) {
            const QRgb pixel = line[x];
            const int gray = qGray(pixel);
            line[x] = qRgba(gray, gray, gray, qAlpha(pixel));
        }
    }
    applyTransform(result, QStringLiteral("Noir et blanc prêt en mémoire."));
}

void ImageEditorBackend::adjustBrightness(int amount)
{
    if (!hasImage())
        return;
    const int delta = boundedAmount(amount) * 255 / 100;
    QImage result = m_image.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < result.height(); ++y) {
        auto *line = reinterpret_cast<QRgb *>(result.scanLine(y));
        for (int x = 0; x < result.width(); ++x) {
            const QRgb pixel = line[x];
            line[x] = qRgba(qBound(0, qRed(pixel) + delta, 255),
                            qBound(0, qGreen(pixel) + delta, 255),
                            qBound(0, qBlue(pixel) + delta, 255),
                            qAlpha(pixel));
        }
    }
    applyTransform(result, QStringLiteral("Luminosité appliquée en mémoire."));
}

void ImageEditorBackend::adjustContrast(int amount)
{
    if (!hasImage())
        return;
    const qreal contrast = boundedAmount(amount);
    const qreal factor = (259.0 * (contrast + 255.0)) / (255.0 * (259.0 - contrast));
    QImage result = m_image.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < result.height(); ++y) {
        auto *line = reinterpret_cast<QRgb *>(result.scanLine(y));
        for (int x = 0; x < result.width(); ++x) {
            const QRgb pixel = line[x];
            const auto apply = [factor](int value) {
                return qBound(0, qRound(factor * (value - 128) + 128), 255);
            };
            line[x] = qRgba(apply(qRed(pixel)), apply(qGreen(pixel)), apply(qBlue(pixel)), qAlpha(pixel));
        }
    }
    applyTransform(result, QStringLiteral("Contraste appliqué en mémoire."));
}

bool ImageEditorBackend::resizeToFit(int maxWidth, int maxHeight)
{
    if (!hasImage()) {
        setStatusMessage(QStringLiteral("Ouvrez d’abord une image."));
        return false;
    }
    if (maxWidth < 1 || maxHeight < 1 || maxWidth > 8192 || maxHeight > 8192) {
        setStatusMessage(QStringLiteral("Dimensions invalides (1 à 8192 pixels)."));
        return false;
    }
    const QImage scaled = m_image.scaled(maxWidth, maxHeight, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    if (scaled.isNull() || scaled.size() == m_image.size()) {
        setStatusMessage(QStringLiteral("L’image a déjà ces dimensions ou ne peut pas être redimensionnée."));
        return false;
    }
    if (qint64(scaled.width()) * scaled.height() > kMaxPixels) {
        setStatusMessage(QStringLiteral("Le résultat dépasserait la limite de 16 mégapixels."));
        return false;
    }
    applyTransform(scaled, QStringLiteral("Redimensionnement proportionnel prêt en mémoire."));
    return true;
}

void ImageEditorBackend::undo()
{
    if (m_undoStack.isEmpty())
        return;
    m_image = m_undoStack.takeLast();
    m_dirty = m_image != m_original;
    updatePreview();
    emit documentChanged();
    emit historyChanged();
    setStatusMessage(QStringLiteral("Dernière transformation annulée."));
}

void ImageEditorBackend::resetToOriginal()
{
    if (!hasImage())
        return;
    if (m_image == m_original) {
        setStatusMessage(QStringLiteral("L’image est déjà dans son état d’origine."));
        return;
    }
    applyTransform(m_original, QStringLiteral("Retour à l’image d’origine; aucune sauvegarde effectuée."));
}

bool ImageEditorBackend::pathExists(const QString &urlString) const
{
    QString path;
    QString error;
    return localPathFromUrl(urlString, &path, &error) && QFileInfo::exists(path);
}

bool ImageEditorBackend::saveCopyAs(const QString &urlString, bool allowOverwrite)
{
    QString path;
    QString error;
    if (!localPathFromUrl(urlString, &path, &error)) {
        setStatusMessage(error);
        return false;
    }
    return saveImage(path, allowOverwrite);
}

bool ImageEditorBackend::localPathFromUrl(const QString &urlString, QString *path, QString *error)
{
    const QUrl url(urlString);
    if (!url.isValid() || !url.isLocalFile()
            || (!url.host().isEmpty() && url.host() != QStringLiteral("localhost"))) {
        *error = QStringLiteral("Seuls les fichiers image locaux sont acceptés.");
        return false;
    }
    const QString localPath = url.toLocalFile();
    if (localPath.isEmpty() || !QFileInfo(localPath).isAbsolute()) {
        *error = QStringLiteral("Le chemin local est invalide.");
        return false;
    }
    *path = QDir::cleanPath(localPath);
    return true;
}

QByteArray ImageEditorBackend::formatForPath(const QString &path)
{
    const QString suffix = QFileInfo(path).suffix().toLower();
    if (suffix == QStringLiteral("jpg") || suffix == QStringLiteral("jpeg"))
        return QByteArrayLiteral("jpeg");
    if (suffix == QStringLiteral("tif") || suffix == QStringLiteral("tiff"))
        return QByteArrayLiteral("tiff");
    if (suffix == QStringLiteral("png") || suffix == QStringLiteral("bmp")
            || suffix == QStringLiteral("webp"))
        return suffix.toLatin1();
    return {};
}

void ImageEditorBackend::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message)
        return;
    m_statusMessage = message;
    emit statusMessageChanged();
}

void ImageEditorBackend::applyTransform(const QImage &image, const QString &message)
{
    if (image.isNull() || image == m_image)
        return;
    if (m_undoStack.size() == kUndoLimit)
        m_undoStack.removeFirst();
    m_undoStack.append(m_image);
    m_image = image;
    m_dirty = m_image != m_original;
    updatePreview();
    emit documentChanged();
    emit historyChanged();
    setStatusMessage(message);
}

void ImageEditorBackend::updatePreview()
{
    ImagePreviewProvider::setImage(m_previewKey, m_image);
    ++m_previewRevision;
    emit previewChanged();
}

bool ImageEditorBackend::saveImage(const QString &path, bool allowOverwrite)
{
    if (!hasImage()) {
        setStatusMessage(QStringLiteral("Ouvrez d’abord une image."));
        return false;
    }

    QFileInfo info(path);
    if (info.isSymLink()) {
        setStatusMessage(QStringLiteral("La destination est un lien symbolique; choisissez un fichier ordinaire pour éviter d’écrire dans une autre cible."));
        return false;
    }
    const QByteArray format = formatForPath(path);
    if (format.isEmpty()) {
        setStatusMessage(QStringLiteral("Format de sortie non pris en charge; utilisez PNG, JPEG, WebP, BMP ou TIFF."));
        return false;
    }
    if (info.exists() && !info.isFile()) {
        setStatusMessage(QStringLiteral("La destination existe mais n’est pas un fichier ordinaire."));
        return false;
    }
    if (info.exists() && !allowOverwrite) {
        setStatusMessage(QStringLiteral("Cette destination existe déjà; confirmez son remplacement."));
        return false;
    }
    if (!QFileInfo(info.absolutePath()).isDir()) {
        setStatusMessage(QStringLiteral("Le dossier de destination n’existe pas."));
        return false;
    }

    const QString finalPath = info.absoluteFilePath();
    QSaveFile file(finalPath);
    if (!file.open(QIODevice::WriteOnly)) {
        setStatusMessage(QStringLiteral("Impossible d’écrire la copie : %1").arg(file.errorString()));
        return false;
    }
    QImageWriter writer(&file, format);
    if (format == QByteArrayLiteral("jpeg") || format == QByteArrayLiteral("webp"))
        writer.setQuality(92);
    if (!writer.write(m_image)) {
        const QString reason = writer.errorString();
        file.cancelWriting();
        setStatusMessage(QStringLiteral("Encodage impossible : %1").arg(reason));
        return false;
    }
    if (!file.commit()) {
        setStatusMessage(QStringLiteral("Impossible de finaliser la copie : %1").arg(file.errorString()));
        return false;
    }

    m_imagePath = finalPath;
    m_original = m_image;
    m_dirty = false;
    m_undoStack.clear();
    emit documentChanged();
    emit historyChanged();
    setStatusMessage(QStringLiteral("Copie enregistrée atomiquement · %1").arg(finalPath));
    return true;
}
