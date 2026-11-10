#pragma once

#include <QAbstractListModel>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QVector>

class GitInfo;

// The entries of one folder, folders first, refreshed whenever the folder
// changes on disk.
class FileModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString directory READ directory NOTIFY directoryChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    // "auto", "name", "date", "size" or "type".
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY sortChanged)
    Q_PROPERTY(bool descending READ descending WRITE setDescending NOTIFY sortChanged)
    // What "auto" resolved to for this folder, and why, for the header to show.
    Q_PROPERTY(QString effectiveSort READ effectiveSort NOTIFY sortChanged)
    Q_PROPERTY(bool effectiveDescending READ effectiveDescending NOTIFY sortChanged)

public:
    enum Role { NameRole = Qt::UserRole + 1, PathRole, IsDirRole, SizeRole, ModifiedRole, KindRole, GitRole };

    explicit FileModel(GitInfo *git, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString directory() const { return m_directory; }
    bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool show);

    QString sortMode() const { return m_sortMode; }
    void setSortMode(const QString &mode);
    bool descending() const { return m_descending; }
    void setDescending(bool descending);
    QString effectiveSort() const;
    bool effectiveDescending() const;
    // Clicking a column: sort by it, or flip the order when it's already the sort.
    Q_INVOKABLE void sortBy(const QString &mode);
    Q_INVOKABLE void cycleSort();

    // The order "auto" picks for a folder: newest first where files arrive
    // over time (downloads, pictures, screenshots), names everywhere else.
    static QString autoSortFor(const QString &directory);
    static void sortEntries(QVector<QFileInfo> &entries, const QString &mode, bool descending);

    bool setDirectory(const QString &path);
    Q_INVOKABLE QString pathAt(int row) const;
    Q_INVOKABLE bool isDirAt(int row) const;
    Q_INVOKABLE int rowOf(const QString &path) const;
    void refresh();

signals:
    void directoryChanged();
    void showHiddenChanged();
    void countChanged();
    void sortChanged();

private:
    GitInfo *m_git;
    QString m_directory;
    bool m_showHidden = false;
    QString m_sortMode = "auto";
    bool m_descending = false;
    QVector<QFileInfo> m_entries;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};
