#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QHash>
#include <QVector>

// The user's GitHub repositories, shown like the entries of a folder. Listed
// through the gh command-line tool, so its login is the only credential, and
// matched to the clones already on this machine.
class GitHubRepos : public QAbstractListModel {
    Q_OBJECT
    // idle, loading, ready, error
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(QString login READ login NOTIFY stateChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int total READ total NOTIFY countChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY countChanged)

public:
    struct Repo {
        QString name;
        QString fullName;
        QString description;
        QString language;
        QString url;
        bool isPrivate = false;
        bool isFork = false;
        int stars = 0;
        QDateTime updated;
        QString localPath;
    };

    enum Role {
        NameRole = Qt::UserRole + 1, FullNameRole, DescriptionRole, LanguageRole, UrlRole, PrivateRole, ForkRole,
        StarsRole, UpdatedRole, LocalPathRole
    };

    explicit GitHubRepos(QObject *parent = nullptr);
    ~GitHubRepos() override;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString state() const { return m_state; }
    QString error() const { return m_error; }
    QString login() const { return m_login; }
    int total() const { return int(m_all.size()); }
    QString filter() const { return m_filter; }
    void setFilter(const QString &filter);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantMap at(int row) const;
    // Re-matches repositories to local clones, e.g. after a clone finished.
    void rescanClones();

    void setCloneRoots(const QStringList &roots) { m_cloneRoots = roots; }

    static QVector<Repo> parse(const QByteArray &json);
    // "owner/name" (lower case) for a GitHub remote URL, or empty.
    static QString repoFromRemote(const QString &url);
    // owner/name (lower case) → local path, for git repositories up to two
    // levels under each root.
    static QHash<QString, QString> findClones(const QStringList &roots);
    static QString relativeTime(const QDateTime &when, const QDateTime &now = QDateTime::currentDateTimeUtc());

signals:
    void stateChanged();
    void countChanged();

private:
    void applyFilter();
    void setState(const QString &state, const QString &error = {});

    QString m_state = "idle";
    QString m_error;
    QString m_login;
    QString m_filter;
    QStringList m_cloneRoots;
    QVector<Repo> m_all;
    QVector<int> m_visible;
};
