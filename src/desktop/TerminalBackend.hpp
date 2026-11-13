#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

class TerminalBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(QString workingDirectory READ workingDirectory NOTIFY workingDirectoryChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(int lastExitCode READ lastExitCode NOTIFY lastExitCodeChanged)

public:
    explicit TerminalBackend(QObject *parent = nullptr);
    ~TerminalBackend() override;

    QString output() const { return m_output; }
    QString workingDirectory() const { return m_workingDirectory; }
    bool running() const { return m_running; }
    int lastExitCode() const { return m_lastExitCode; }

    Q_INVOKABLE bool execute(const QString &command);
    Q_INVOKABLE void clearOutput();
    Q_INVOKABLE void cancel();

signals:
    void outputChanged();
    void workingDirectoryChanged();
    void runningChanged();
    void lastExitCodeChanged();

private slots:
    void collectOutput();
    void finishCommand(int exitCode, QProcess::ExitStatus exitStatus);
    void processError(QProcess::ProcessError error);

private:
    static QString shellQuote(const QString &value);
    static QString sanitize(const QString &value);
    void appendOutput(const QString &text);
    void setRunning(bool running);

    QProcess m_process;
    QString m_output;
    QString m_prefixBeforeCommand;
    QString m_commandPrompt;
    QString m_workingDirectory;
    QString m_activeToken;
    QByteArray m_pendingOutput;
    bool m_running = false;
    bool m_truncated = false;
    int m_lastExitCode = -1;
};
