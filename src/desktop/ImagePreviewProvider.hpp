#pragma once

#include <QImage>
#include <QQuickImageProvider>
#include <QString>

class ImagePreviewProvider final : public QQuickImageProvider
{
public:
    ImagePreviewProvider();

    static void setImage(const QString &key, const QImage &image);
    static void removeImage(const QString &key);

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
