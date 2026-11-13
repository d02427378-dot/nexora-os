#include "ImagePreviewProvider.hpp"

#include <QHash>
#include <QMutex>
#include <QMutexLocker>

namespace {
QHash<QString, QImage> &imageStore()
{
    static QHash<QString, QImage> store;
    return store;
}

QMutex &imageStoreMutex()
{
    static QMutex mutex;
    return mutex;
}
}

ImagePreviewProvider::ImagePreviewProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

void ImagePreviewProvider::setImage(const QString &key, const QImage &image)
{
    QMutexLocker locker(&imageStoreMutex());
    if (image.isNull())
        imageStore().remove(key);
    else
        imageStore().insert(key, image);
}

void ImagePreviewProvider::removeImage(const QString &key)
{
    QMutexLocker locker(&imageStoreMutex());
    imageStore().remove(key);
}

QImage ImagePreviewProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    const QString key = id.section(QLatin1Char('/'), 0, 0);
    QImage image;
    {
        QMutexLocker locker(&imageStoreMutex());
        image = imageStore().value(key);
    }
    if (image.isNull())
        return {};

    if (size)
        *size = image.size();
    if (requestedSize.isValid() && requestedSize.width() > 0 && requestedSize.height() > 0) {
        const bool exceedsRequest = image.width() > requestedSize.width() || image.height() > requestedSize.height();
        if (exceedsRequest)
            return image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    return image;
}
