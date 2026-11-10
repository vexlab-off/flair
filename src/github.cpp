#include "github.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QVariantMap>
#include <algorithm>

GitHubRepos::GitHubRepos(QObject *parent) : QAbstractListModel(parent) {}

GitHubRepos::~GitHubRepos() {
    for (auto *process : findChildren<QProcess *>()) {
        process->disconnect();
        process->kill();
        process->waitForFinished(500);
    }
}

int GitHubRepos::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : int(m_visible.size());
}

QVariant GitHubRepos::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_visible.size())
        return {};
    const auto &r = m_all[m_visible[index.row()]];
    switch (role) {
    case NameRole: return r.name;
    case FullNameRole: return r.fullName;
    case DescriptionRole: return r.description;
    case LanguageRole: return r.language;
    case UrlRole: return r.url;
    case PrivateRole: return r.isPrivate;
    case ForkRole: return r.isFork;
    case StarsRole: return r.stars;
    case UpdatedRole: return relativeTime(r.updated);
    case LocalPathRole: return r.localPath;
    }
    return {};
}

QHash<int, QByteArray> GitHubRepos::roleNames() const {
    return {{NameRole, "name"},       {FullNameRole, "fullName"}, {DescriptionRole, "description"},
            {LanguageRole, "language"}, {UrlRole, "url"},         {PrivateRole, "isPrivate"},
            {ForkRole, "isFork"},     {StarsRole, "stars"},       {UpdatedRole, "updated"},
            {LocalPathRole, "localPath"}};
}

QVariantMap GitHubRepos::at(int row) const {
    if (row < 0 || row >= m_visible.size())
        return {};
    const auto &r = m_all[m_visible[row]];
    return {{"name", r.name}, {"fullName", r.fullName}, {"description", r.description}, {"url", r.url},
            {"localPath", r.localPath}, {"language", r.language}, {"isPrivate", r.isPrivate}};
}

void GitHubRepos::setState(const QString &state, const QString &error) {
    m_state = state;
    m_error = error;
    emit stateChanged();
}

void GitHubRepos::setFilter(const QString &filter) {
    if (filter == m_filter)
        return;
    m_filter = filter;
    applyFilter();
}

void GitHubRepos::applyFilter() {
    beginResetModel();
    m_visible.clear();
    const auto words = m_filter.toLower().split(' ', Qt::SkipEmptyParts);
    for (int i = 0; i < m_all.size(); ++i) {
        const auto hay = (m_all[i].fullName + " " + m_all[i].description + " " + m_all[i].language).toLower();
        bool all = true;
        for (const auto &w : words)
            all = all && hay.contains(w);
        if (all)
            m_visible.append(i);
    }
    endResetModel();
    emit countChanged();
}

QVector<GitHubRepos::Repo> GitHubRepos::parse(const QByteArray &json) {
    QVector<Repo> repos;
    for (const auto &value : QJsonDocument::fromJson(json).array()) {
        const auto o = value.toObject();
        Repo r;
        r.name = o.value("name").toString();
        r.fullName = o.value("nameWithOwner").toString();
        r.description = o.value("description").toString();
        r.language = o.value("primaryLanguage").toObject().value("name").toString();
        r.url = o.value("url").toString();
        r.isPrivate = o.value("isPrivate").toBool();
        r.isFork = o.value("isFork").toBool();
        r.stars = o.value("stargazerCount").toInt();
        r.updated = QDateTime::fromString(o.value("updatedAt").toString(), Qt::ISODate);
        if (!r.fullName.isEmpty())
            repos.append(r);
    }
    std::sort(repos.begin(), repos.end(), [](const Repo &a, const Repo &b) { return a.updated > b.updated; });
    return repos;
}

QString GitHubRepos::repoFromRemote(const QString &url) {
    static const QRegularExpression expression(
        R"(github\.com[:/]([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+?)(?:\.git)?/?$)");
    const auto match = expression.match(url.trimmed());
    return match.hasMatch() ? (match.captured(1) + "/" + match.captured(2)).toLower() : QString();
}

QHash<QString, QString> GitHubRepos::findClones(const QStringList &roots) {
    QHash<QString, QString> clones;
    static const QRegularExpression urlLine(R"(^\s*url\s*=\s*(\S+))", QRegularExpression::MultilineOption);
    auto inspect = [&](const QString &dir) {
        QFile config(dir + "/.git/config");
        if (!config.open(QIODevice::ReadOnly))
            return false;
        auto it = urlLine.globalMatch(QString::fromUtf8(config.readAll()));
        while (it.hasNext()) {
            const auto repo = repoFromRemote(it.next().captured(1));
            if (!repo.isEmpty() && !clones.contains(repo))
                clones.insert(repo, dir);
        }
        return true;
    };
    for (const auto &root : roots) {
        for (const auto &first : QDir(root).entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            if (inspect(first.absoluteFilePath()))
                continue;
            for (const auto &second : QDir(first.absoluteFilePath()).entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot))
                inspect(second.absoluteFilePath());
        }
    }
    return clones;
}

QString GitHubRepos::relativeTime(const QDateTime &when, const QDateTime &now) {
    if (!when.isValid())
        return {};
    const qint64 seconds = when.secsTo(now);
    if (seconds < 3600)
        return QObject::tr("à l'instant");
    if (seconds < 86400)
        return QObject::tr("il y a %1 h").arg(seconds / 3600);
    const qint64 days = seconds / 86400;
    if (days < 30)
        return QObject::tr("il y a %1 j").arg(days);
    if (days < 365)
        return QObject::tr("il y a %1 mois").arg(days / 30);
    return QObject::tr("il y a %1 an%2").arg(days / 365).arg(days >= 730 ? "s" : "");
}

void GitHubRepos::rescanClones() {
    const auto clones = findClones(m_cloneRoots);
    for (auto &r : m_all)
        r.localPath = clones.value(r.fullName.toLower());
    if (!m_visible.isEmpty())
        emit dataChanged(index(0), index(int(m_visible.size()) - 1), {LocalPathRole});
}

void GitHubRepos::refresh() {
    if (m_state == "loading")
        return;
    if (QStandardPaths::findExecutable("gh").isEmpty()) {
        setState("error", tr("L'outil gh n'est pas installé. Installe github-cli puis lance « gh auth login »."));
        return;
    }
    setState("loading");

    auto *user = new QProcess(this);
    connect(user, &QProcess::finished, this, [this, user](int code, QProcess::ExitStatus) {
        if (code == 0)
            m_login = QString::fromUtf8(user->readAllStandardOutput()).trimmed();
        user->deleteLater();
        emit stateChanged();
    });
    user->start("gh", {"api", "user", "--jq", ".login"});

    auto *list = new QProcess(this);
    connect(list, &QProcess::finished, this, [this, list](int code, QProcess::ExitStatus) {
        const auto out = list->readAllStandardOutput();
        const auto err = QString::fromUtf8(list->readAllStandardError()).trimmed();
        list->deleteLater();
        if (code != 0) {
            const bool auth = err.contains("auth login") || err.contains("not logged");
            setState("error", auth ? tr("gh n'est pas connecté à GitHub. Lance « gh auth login » dans un terminal.")
                                   : tr("GitHub n'a pas répondu : %1").arg(err.right(300)));
            return;
        }
        m_all = parse(out);
        const auto clones = findClones(m_cloneRoots);
        for (auto &r : m_all)
            r.localPath = clones.value(r.fullName.toLower());
        applyFilter();
        setState("ready");
    });
    list->start("gh", {"repo", "list", "--limit", "300", "--json",
                       "name,nameWithOwner,description,isPrivate,isFork,primaryLanguage,updatedAt,stargazerCount,url"});
}
