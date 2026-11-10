#pragma once

#include <QHash>
#include <QObject>

// Git state of the folder being shown: branch, remote, and per-file status,
// read in the background so a slow repository never blocks the window.
class GitInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRepo READ isRepo NOTIFY changed)
    Q_PROPERTY(QString branch READ branch NOTIFY changed)
    Q_PROPERTY(QString webUrl READ webUrl NOTIFY changed)
    Q_PROPERTY(int changedCount READ changedCount NOTIFY changed)

public:
    explicit GitInfo(QObject *parent = nullptr);
    ~GitInfo() override;

    bool isRepo() const { return !m_top.isEmpty(); }
    QString branch() const { return m_branch; }
    QString webUrl() const { return m_webUrl; }
    QString top() const { return m_top; }
    int changedCount() const { return m_statuses.size(); }

    void refresh(const QString &directory);
    // Short status for a path ("M", "A", "?", …); a folder holding changes gets "•".
    QString statusFor(const QString &absolutePath) const;

    // `git status --porcelain=v1 -b -z` output, split into a branch name and
    // status codes keyed by path relative to the repository.
    static void parsePorcelain(const QByteArray &output, QString *branch, QHash<QString, QString> *statuses);
    // https URL for a GitHub/GitLab remote, empty for anything else.
    static QString webUrlFromRemote(const QString &remote);

signals:
    void changed();

private:
    void clear();

    int m_generation = 0;
    QString m_top;
    QString m_branch;
    QString m_webUrl;
    QHash<QString, QString> m_statuses;
};
