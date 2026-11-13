#pragma once

#include <QObject>
#include <QString>

class CodeEditorBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString content READ content NOTIFY contentChanged)
    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(QString fileUrl READ fileUrl NOTIFY filePathChanged)
    Q_PROPERTY(bool dirty READ dirty NOTIFY dirtyChanged)
    Q_PROPERTY(bool hasDocument READ hasDocument NOTIFY filePathChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit CodeEditorBackend(QObject *parent = nullptr);

    QString content() const { return m_content; }
    QString filePath() const { return m_filePath; }
    QString fileUrl() const;
    bool dirty() const { return m_content != m_savedContent; }
    bool hasDocument() const { return !m_filePath.isEmpty(); }
    QString statusMessage() const { return m_statusMessage; }

    Q_INVOKABLE void setContent(const QString &content);
    Q_INVOKABLE void newDocument();
    Q_INVOKABLE bool openFile(const QString &urlString);
    Q_INVOKABLE bool saveCurrent();
    Q_INVOKABLE bool saveAsFile(const QString &urlString, bool allowOverwrite);
    Q_INVOKABLE bool pathExists(const QString &urlString) const;

signals:
    void contentChanged();
    void filePathChanged();
    void dirtyChanged();
    void statusMessageChanged();

private:
    static constexpr qint64 kMaxFileBytes = 2 * 1024 * 1024;
    static bool localPathFromUrl(const QString &urlString, QString *path, QString *error);
    void setStatusMessage(const QString &message);
    void emitDirtyIfChanged(bool wasDirty);
    bool writeCurrentFile(const QString &path);

    QString m_content;
    QString m_savedContent;
    QString m_filePath;
    QString m_statusMessage;
};
