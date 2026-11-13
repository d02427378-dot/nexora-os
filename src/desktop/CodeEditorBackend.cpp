#include "CodeEditorBackend.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QUrl>

CodeEditorBackend::CodeEditorBackend(QObject *parent)
    : QObject(parent)
{
}

QString CodeEditorBackend::fileUrl() const
{
    return m_filePath.isEmpty()
            ? QString()
            : QUrl::fromLocalFile(m_filePath).toString(QUrl::FullyEncoded);
}

void CodeEditorBackend::setContent(const QString &content)
{
    if (m_content == content)
        return;
    const bool wasDirty = dirty();
    m_content = content;
    emit contentChanged();
    emitDirtyIfChanged(wasDirty);
}

void CodeEditorBackend::newDocument()
{
    const bool wasDirty = dirty();
    const bool pathChanged = !m_filePath.isEmpty();
    const bool contentChangedNow = !m_content.isEmpty() || !m_savedContent.isEmpty();
    m_filePath.clear();
    m_content.clear();
    m_savedContent.clear();
    if (pathChanged)
        emit filePathChanged();
    if (contentChangedNow)
        emit contentChanged();
    emitDirtyIfChanged(wasDirty);
    setStatusMessage(QStringLiteral("Nouveau document non enregistré."));
}

bool CodeEditorBackend::openFile(const QString &urlString)
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
            setStatusMessage(QStringLiteral("Le lien symbolique ne pointe vers aucun fichier existant."));
            return false;
        }
        path = canonical;
        info.setFile(path);
    }
    if (!info.exists() || !info.isFile()) {
        setStatusMessage(QStringLiteral("Le chemin sélectionné n’est pas un fichier ordinaire."));
        return false;
    }
    if (info.size() > kMaxFileBytes) {
        setStatusMessage(QStringLiteral("Fichier trop volumineux : limite de lecture de 2 Mio."));
        return false;
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        setStatusMessage(QStringLiteral("Lecture impossible : %1").arg(file.errorString()));
        return false;
    }
    const QByteArray bytes = file.read(kMaxFileBytes + 1);
    if (file.error() != QFileDevice::NoError) {
        setStatusMessage(QStringLiteral("Erreur pendant la lecture : %1").arg(file.errorString()));
        return false;
    }
    if (bytes.size() > kMaxFileBytes) {
        setStatusMessage(QStringLiteral("Fichier trop volumineux : limite de lecture de 2 Mio."));
        return false;
    }
    if (bytes.contains('\0')) {
        setStatusMessage(QStringLiteral("Ce fichier contient des octets nuls; l’éditeur texte refuse de l’ouvrir."));
        return false;
    }

    const QString decoded = QString::fromUtf8(bytes.constData(), bytes.size());
    if (decoded.toUtf8() != bytes) {
        setStatusMessage(QStringLiteral("Encodage non pris en charge : seuls les fichiers UTF-8 sont ouverts."));
        return false;
    }

    const bool wasDirty = dirty();
    const bool pathChanged = m_filePath != path;
    const bool contentChangedNow = m_content != decoded;
    m_filePath = path;
    m_content = decoded;
    m_savedContent = decoded;
    if (pathChanged)
        emit filePathChanged();
    if (contentChangedNow)
        emit contentChanged();
    emitDirtyIfChanged(wasDirty);
    setStatusMessage(QStringLiteral("Fichier UTF-8 chargé · %1 octets.").arg(bytes.size()));
    return true;
}

bool CodeEditorBackend::saveCurrent()
{
    if (m_filePath.isEmpty()) {
        setStatusMessage(QStringLiteral("Ce document n’a pas encore de chemin. Utilisez Enregistrer sous…"));
        return false;
    }
    return writeCurrentFile(m_filePath);
}

bool CodeEditorBackend::saveAsFile(const QString &urlString, bool allowOverwrite)
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
            setStatusMessage(QStringLiteral("La destination est un lien symbolique invalide."));
            return false;
        }
        path = canonical;
        info.setFile(path);
    }
    if (info.exists() && !info.isFile()) {
        setStatusMessage(QStringLiteral("La destination existe mais n’est pas un fichier ordinaire."));
        return false;
    }
    if (info.exists() && !allowOverwrite) {
        setStatusMessage(QStringLiteral("La destination existe déjà; confirmez son remplacement."));
        return false;
    }
    if (!QFileInfo(info.absolutePath()).isDir()) {
        setStatusMessage(QStringLiteral("Le dossier de destination n’existe pas."));
        return false;
    }

    const bool pathChanged = m_filePath != path;
    if (!writeCurrentFile(path))
        return false;
    m_filePath = path;
    if (pathChanged)
        emit filePathChanged();
    return true;
}

bool CodeEditorBackend::pathExists(const QString &urlString) const
{
    QString path;
    QString error;
    return localPathFromUrl(urlString, &path, &error) && QFileInfo::exists(path);
}

bool CodeEditorBackend::localPathFromUrl(const QString &urlString, QString *path, QString *error)
{
    const QUrl url(urlString);
    if (!url.isValid() || !url.isLocalFile()
            || (!url.host().isEmpty() && url.host() != QStringLiteral("localhost"))) {
        *error = QStringLiteral("Seuls les fichiers locaux file:// sont pris en charge.");
        return false;
    }
    const QString localPath = url.toLocalFile();
    if (localPath.isEmpty() || !QFileInfo(localPath).isAbsolute()) {
        *error = QStringLiteral("Le chemin local est vide ou invalide.");
        return false;
    }
    *path = QDir::cleanPath(localPath);
    return true;
}

void CodeEditorBackend::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message)
        return;
    m_statusMessage = message;
    emit statusMessageChanged();
}

void CodeEditorBackend::emitDirtyIfChanged(bool wasDirty)
{
    if (wasDirty != dirty())
        emit dirtyChanged();
}

bool CodeEditorBackend::writeCurrentFile(const QString &path)
{
    const QByteArray bytes = m_content.toUtf8();
    if (bytes.size() > kMaxFileBytes) {
        setStatusMessage(QStringLiteral("Document trop volumineux : limite d’enregistrement de 2 Mio."));
        return false;
    }

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        setStatusMessage(QStringLiteral("Enregistrement impossible : %1").arg(file.errorString()));
        return false;
    }
    if (file.write(bytes) != bytes.size()) {
        file.cancelWriting();
        setStatusMessage(QStringLiteral("Écriture incomplète : le fichier d’origine a été conservé."));
        return false;
    }
    if (!file.commit()) {
        setStatusMessage(QStringLiteral("Impossible de finaliser l’écriture atomique : %1").arg(file.errorString()));
        return false;
    }

    const bool wasDirty = dirty();
    m_savedContent = m_content;
    emitDirtyIfChanged(wasDirty);
    setStatusMessage(QStringLiteral("Enregistrement terminé."));
    return true;
}
