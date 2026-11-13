#pragma once

#include <QByteArray>
#include <QImage>
#include <QObject>
#include <QString>
#include <QVector>

class ImageEditorBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString imagePath READ imagePath NOTIFY documentChanged)
    Q_PROPERTY(QString previewUrl READ previewUrl NOTIFY previewChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool hasImage READ hasImage NOTIFY documentChanged)
    Q_PROPERTY(bool dirty READ dirty NOTIFY documentChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY historyChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY documentChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY documentChanged)

public:
    explicit ImageEditorBackend(QObject *parent = nullptr);
    ~ImageEditorBackend() override;

    QString imagePath() const { return m_imagePath; }
    QString previewUrl() const;
    QString statusMessage() const { return m_statusMessage; }
    bool hasImage() const { return !m_image.isNull(); }
    bool dirty() const { return m_dirty; }
    bool canUndo() const { return !m_undoStack.isEmpty(); }
    int imageWidth() const { return m_image.width(); }
    int imageHeight() const { return m_image.height(); }

    Q_INVOKABLE bool openImage(const QString &urlString);
    Q_INVOKABLE void rotateLeft();
    Q_INVOKABLE void rotateRight();
    Q_INVOKABLE void flipHorizontal();
    Q_INVOKABLE void flipVertical();
    Q_INVOKABLE void convertToGrayscale();
    Q_INVOKABLE void adjustBrightness(int amount);
    Q_INVOKABLE void adjustContrast(int amount);
    Q_INVOKABLE bool resizeToFit(int maxWidth, int maxHeight);
    Q_INVOKABLE void undo();
    Q_INVOKABLE void resetToOriginal();
    Q_INVOKABLE bool pathExists(const QString &urlString) const;
    Q_INVOKABLE bool saveCopyAs(const QString &urlString, bool allowOverwrite);

signals:
    void documentChanged();
    void previewChanged();
    void historyChanged();
    void statusMessageChanged();

private:
    static constexpr qint64 kMaxInputBytes = 40 * 1024 * 1024;
    static constexpr qint64 kMaxPixels = 16 * 1024 * 1024;
    static constexpr int kUndoLimit = 4;

    static bool localPathFromUrl(const QString &urlString, QString *path, QString *error);
    static QByteArray formatForPath(const QString &path);
    void setStatusMessage(const QString &message);
    void applyTransform(const QImage &image, const QString &message);
    void updatePreview();
    bool saveImage(const QString &path, bool allowOverwrite);

    QString m_imagePath;
    QString m_statusMessage;
    QString m_previewKey;
    quint64 m_previewRevision = 0;
    QImage m_original;
    QImage m_image;
    QVector<QImage> m_undoStack;
    bool m_dirty = false;
};
