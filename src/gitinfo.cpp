#include "gitinfo.h"

#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>

GitInfo::GitInfo(QObject *parent) : QObject(parent) {}

// A git status still running at quit is of no use; stop it rather than leave
// Qt to complain about destroying a live process.
GitInfo::~GitInfo() {
    for (auto *process : findChildren<QProcess *>()) {
        process->disconnect();
        process->kill();
        process->waitForFinished(500);
    }
}

void GitInfo::clear() {
    const bool had = isRepo();
    m_top.clear();
    m_branch.clear();
    m_webUrl.clear();
    m_statuses.clear();
    if (had)
        emit changed();
}

// Runs git and hands its stdout to `then`, unless a newer refresh started.
static void runGit(QObject *owner, const QStringList &args, std::function<void(int, const QByteArray &)> then) {
    auto *process = new QProcess(owner);
    QObject::connect(process, &QProcess::finished, owner, [process, then](int code, QProcess::ExitStatus) {
        then(code, process->readAllStandardOutput());
        process->deleteLater();
    });
    QObject::connect(process, &QProcess::errorOccurred, owner, [process, then](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) {
            then(-1, {});
            process->deleteLater();
        }
    });
    process->start("git", args);
}

void GitInfo::refresh(const QString &directory) {
    const int generation = ++m_generation;
    if (QStandardPaths::findExecutable("git").isEmpty()) {
        clear();
        return;
    }
    runGit(this, {"-C", directory, "rev-parse", "--show-toplevel"}, [=](int code, const QByteArray &out) {
        if (generation != m_generation)
            return;
        if (code != 0) {
            clear();
            return;
        }
        const auto top = QString::fromUtf8(out).trimmed();
        runGit(this, {"-C", top, "status", "--porcelain=v1", "-b", "-z"}, [=](int code, const QByteArray &status) {
            if (generation != m_generation || code != 0)
                return;
            runGit(this, {"-C", top, "remote", "get-url", "origin"}, [=](int, const QByteArray &remote) {
                if (generation != m_generation)
                    return;
                m_top = top;
                m_statuses.clear();
                parsePorcelain(status, &m_branch, &m_statuses);
                m_webUrl = webUrlFromRemote(QString::fromUtf8(remote).trimmed());
                emit changed();
            });
        });
    });
}

void GitInfo::parsePorcelain(const QByteArray &output, QString *branch, QHash<QString, QString> *statuses) {
    const auto records = output.split('\0');
    for (int i = 0; i < records.size(); ++i) {
        const auto record = QString::fromUtf8(records[i]);
        if (record.isEmpty())
            continue;
        if (record.startsWith("## ")) {
            // "## main...origin/main [ahead 1]" or "## No commits yet on main"
            auto name = record.mid(3);
            name = name.section("...", 0, 0).section(' ', 0, 0);
            if (record.startsWith("## No commits yet on "))
                name = record.mid(QString("## No commits yet on ").size());
            if (branch)
                *branch = name;
            continue;
        }
        if (record.size() < 4)
            continue;
        const auto code = record.left(2);
        const auto path = record.mid(3);
        QString shortCode = code.trimmed();
        if (code == "??")
            shortCode = "?";
        else if (shortCode.size() > 1)
            shortCode = shortCode.left(1);
        if (statuses)
            statuses->insert(path.endsWith('/') ? path.chopped(1) : path, shortCode);
        // Renames and copies carry the original path as the next record.
        if (code.contains('R') || code.contains('C'))
            ++i;
    }
}

QString GitInfo::webUrlFromRemote(const QString &remote) {
    static const QRegularExpression ssh(R"(^(?:ssh://)?git@(github\.com|gitlab\.com)[:/](.+?)(?:\.git)?/?$)");
    static const QRegularExpression https(R"(^https?://(?:[^@/]+@)?(github\.com|gitlab\.com)/(.+?)(?:\.git)?/?$)");
    for (const auto *expression : {&ssh, &https}) {
        const auto match = expression->match(remote);
        if (match.hasMatch())
            return "https://" + match.captured(1) + "/" + match.captured(2);
    }
    return {};
}

QString GitInfo::statusFor(const QString &absolutePath) const {
    if (m_top.isEmpty() || !absolutePath.startsWith(m_top + "/"))
        return {};
    const auto rel = absolutePath.mid(m_top.size() + 1);
    const auto direct = m_statuses.value(rel);
    if (!direct.isEmpty())
        return direct;
    const auto prefix = rel + "/";
    for (auto it = m_statuses.cbegin(); it != m_statuses.cend(); ++it)
        if (it.key().startsWith(prefix))
            return QStringLiteral("•");
    return {};
}
