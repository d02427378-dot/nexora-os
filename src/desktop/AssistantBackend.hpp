#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QPointer>
#include <QString>

class AssistantBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString answer READ answer NOTIFY answerChanged)
    Q_PROPERTY(QString codeDraft READ codeDraft NOTIFY codeDraftChanged)
    Q_PROPERTY(QString actionType READ actionType NOTIFY actionChanged)
    Q_PROPERTY(QString actionValue READ actionValue NOTIFY actionChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit AssistantBackend(QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    QString answer() const { return m_answer; }
    QString codeDraft() const { return m_codeDraft; }
    QString actionType() const { return m_actionType; }
    QString actionValue() const { return m_actionValue; }
    QString error() const { return m_error; }

    Q_INVOKABLE bool ask(const QString &prompt,
                         const QString &endpoint,
                         const QString &model,
                         const QString &apiKey);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void clear();

signals:
    void busyChanged();
    void answerChanged();
    void codeDraftChanged();
    void actionChanged();
    void errorChanged();
    void requestCompleted(bool success);

private:
    static constexpr qsizetype kMaxPromptBytes = 16 * 1024;
    static constexpr qsizetype kMaxResponseBytes = 1024 * 1024;
    static constexpr qsizetype kMaxDraftBytes = 64 * 1024;

    bool validateEndpoint(const QString &endpoint, bool *isLoopback, QString *error) const;
    void consumeReply(QNetworkReply *reply);
    void finishReply(QNetworkReply *reply);
    void setBusy(bool value);
    void setAnswer(const QString &value);
    void setCodeDraft(const QString &value);
    void setAction(const QString &type, const QString &value);
    void setError(const QString &value);
    static bool validateAction(const QString &type, const QString &value);
    static QString boundedText(const QString &value, qsizetype limit);

    QNetworkAccessManager m_network;
    QPointer<QNetworkReply> m_reply;
    QByteArray m_responseData;
    QString m_answer;
    QString m_codeDraft;
    QString m_actionType;
    QString m_actionValue;
    QString m_error;
    bool m_busy = false;
    bool m_responseTooLarge = false;
};
