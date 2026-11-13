#include "TerminalBackend.hpp"

#include <QDir>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QTimer>
#include <QUuid>
#include <csignal>
#include <sys/types.h>
#include <unistd.h>

namespace {
constexpr qsizetype kMaxOutputCharacters = 120000;
constexpr qsizetype kMaxPendingBytes = 512 * 1024;
}

TerminalBackend::TerminalBackend(QObject *parent)
    : QObject(parent), m_workingDirectory(QDir::homePath())
{
    m_process.setProcessChannelMode(QProcess::MergedChannels);
    m_process.setChildProcessModifier([] { ::setpgid(0, 0); });

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("TERM"), QStringLiteral("dumb"));
    environment.insert(QStringLiteral("NO_COLOR"), QStringLiteral("1"));
    environment.insert(QStringLiteral("CLICOLOR"), QStringLiteral("0"));
    environment.insert(QStringLiteral("PAGER"), QStringLiteral("cat"));
    environment.insert(QStringLiteral("GIT_PAGER"), QStringLiteral("cat"));
    environment.insert(QStringLiteral("GIT_TERMINAL_PROMPT"), QStringLiteral("0"));
    m_process.setProcessEnvironment(environment);

    connect(&m_process, &QProcess::readyReadStandardOutput,
            this, &TerminalBackend::collectOutput);
    connect(&m_process, &QProcess::finished,
            this, &TerminalBackend::finishCommand);
    connect(&m_process, &QProcess::errorOccurred,
            this, &TerminalBackend::processError);
}

TerminalBackend::~TerminalBackend()
{
    if (m_process.state() != QProcess::NotRunning) {
        const auto pid = static_cast<pid_t>(m_process.processId());
        if (pid > 0)
            ::kill(-pid, SIGKILL);
        m_process.kill();
        m_process.waitForFinished(500);
    }
}

bool TerminalBackend::execute(const QString &command)
{
    const QString trimmed = command.trimmed();
    if (trimmed.isEmpty() || m_running || m_process.state() != QProcess::NotRunning)
        return false;

    m_pendingOutput.clear();
    m_truncated = false;
    m_activeToken = QUuid::createUuid().toString(QUuid::WithoutBraces).remove(QLatin1Char('-'));
    m_lastExitCode = -1;
    emit lastExitCodeChanged();
    m_prefixBeforeCommand = m_output;
    m_commandPrompt = QStringLiteral("%1$ %2\n").arg(m_workingDirectory, trimmed);
    appendOutput(m_commandPrompt);
    setRunning(true);

    const QString exitMarker = QStringLiteral("__NEXORA_%1_EXIT__").arg(m_activeToken);
    const QString pwdMarker = QStringLiteral("__NEXORA_%1_PWD__").arg(m_activeToken);
    QString wrapper = QStringLiteral("cd -- ") + shellQuote(m_workingDirectory)
            + QStringLiteral(" || exit 125\n") + trimmed
            + QStringLiteral("\n__nexora_exit=$?\nprintf '\\n") + exitMarker
            + QStringLiteral("%d\\n' \"$__nexora_exit\"\nprintf '") + pwdMarker
            + QStringLiteral("%s\\n' \"$PWD\"\n");

    m_process.start(QStringLiteral("/bin/bash"),
                    { QStringLiteral("--noprofile"), QStringLiteral("--norc"),
                      QStringLiteral("-c"), wrapper });
    m_process.closeWriteChannel();
    return true;
}

void TerminalBackend::clearOutput()
{
    if (m_output.isEmpty())
        return;
    m_output.clear();
    emit outputChanged();
}

void TerminalBackend::cancel()
{
    if (m_process.state() == QProcess::NotRunning)
        return;

    const auto pid = static_cast<pid_t>(m_process.processId());
    if (pid > 0)
        ::kill(-pid, SIGTERM);
    else
        m_process.terminate();

    QTimer::singleShot(750, this, [this, pid] {
        if (m_process.state() != QProcess::NotRunning && pid > 0
                && static_cast<pid_t>(m_process.processId()) == pid) {
            ::kill(-pid, SIGKILL);
        }
    });
}

void TerminalBackend::collectOutput()
{
    const QByteArray chunk = m_process.readAllStandardOutput();
    if (chunk.isEmpty())
        return;

    m_pendingOutput += chunk;
    if (m_pendingOutput.size() > kMaxPendingBytes) {
        m_pendingOutput.remove(0, m_pendingOutput.size() - kMaxPendingBytes);
        m_truncated = true;
    }
    appendOutput(sanitize(QString::fromLocal8Bit(chunk)));
}

void TerminalBackend::finishCommand(int exitCode, QProcess::ExitStatus exitStatus)
{
    collectOutput();
    QString text = QString::fromLocal8Bit(m_pendingOutput);
    const QString exitMarker = QStringLiteral("__NEXORA_%1_EXIT__").arg(m_activeToken);
    const QString pwdMarker = QStringLiteral("__NEXORA_%1_PWD__").arg(m_activeToken);

    const qsizetype exitPosition = text.lastIndexOf(exitMarker);
    if (exitPosition >= 0) {
        const qsizetype exitLineEnd = text.indexOf(QLatin1Char('\n'), exitPosition);
        if (exitLineEnd >= 0) {
            bool parsed = false;
            const int shellExitCode = text.mid(exitPosition + exitMarker.size(),
                                               exitLineEnd - exitPosition - exitMarker.size()).trimmed().toInt(&parsed);
            if (parsed)
                exitCode = shellExitCode;

            const qsizetype pwdPosition = text.indexOf(pwdMarker, exitLineEnd);
            if (pwdPosition >= 0) {
                qsizetype pwdLineEnd = text.indexOf(QLatin1Char('\n'), pwdPosition);
                if (pwdLineEnd < 0)
                    pwdLineEnd = text.size();
                const QString pwd = text.mid(pwdPosition + pwdMarker.size(),
                                             pwdLineEnd - pwdPosition - pwdMarker.size()).trimmed();
                if (!pwd.isEmpty() && QFileInfo(pwd).isDir() && m_workingDirectory != pwd) {
                    m_workingDirectory = QDir::cleanPath(pwd);
                    emit workingDirectoryChanged();
                }
            }
            text = text.left(exitPosition);
        }
    }

    QString visibleTail = sanitize(text);
    m_output = m_prefixBeforeCommand;
    if (m_truncated)
        appendOutput(QStringLiteral("[sortie tronquée à 512 Kio]\n"));
    appendOutput(m_commandPrompt);
    appendOutput(visibleTail);
    appendOutput(QStringLiteral("\n[code de sortie : %1%2]\n")
                 .arg(exitCode)
                 .arg(exitStatus == QProcess::CrashExit ? QStringLiteral(" · processus interrompu") : QString()));

    if (m_lastExitCode != exitCode) {
        m_lastExitCode = exitCode;
        emit lastExitCodeChanged();
    }
    setRunning(false);
    m_activeToken.clear();
    m_prefixBeforeCommand.clear();
    m_commandPrompt.clear();
}

void TerminalBackend::processError(QProcess::ProcessError error)
{
    if (error == QProcess::FailedToStart) {
        appendOutput(QStringLiteral("Impossible de démarrer /bin/bash.\n"));
        if (m_lastExitCode != 127) {
            m_lastExitCode = 127;
            emit lastExitCodeChanged();
        }
        setRunning(false);
    }
}

QString TerminalBackend::shellQuote(const QString &value)
{
    QString escaped = value;
    escaped.replace(QLatin1Char('\''), QStringLiteral("'\\''"));
    return QLatin1Char('\'') + escaped + QLatin1Char('\'');
}

QString TerminalBackend::sanitize(const QString &value)
{
    QString text = value;
    static const QRegularExpression ansi(QStringLiteral("\\x1B\\[[0-?]*[ -/]*[@-~]"));
    static const QRegularExpression controls(QStringLiteral("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]"));
    text.remove(ansi);
    text.remove(controls);
    return text;
}

void TerminalBackend::appendOutput(const QString &text)
{
    if (text.isEmpty())
        return;
    m_output += text;
    if (m_output.size() > kMaxOutputCharacters) {
        m_output.remove(0, m_output.size() - kMaxOutputCharacters);
        const QString notice = QStringLiteral("[…début de la sortie retiré…]\n");
        if (!m_output.startsWith(notice))
            m_output.prepend(notice);
    }
    emit outputChanged();
}

void TerminalBackend::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    emit runningChanged();
}
