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

public:
    enum Role { NameRole = Qt::UserRole + 1, PathRole, IsDirRole, SizeRole, ModifiedRole, KindRole, GitRole };

    explicit FileModel(GitInfo *git, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString directory() const { return m_directory; }
    bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool show);

    bool setDirectory(const QString &path);
    Q_INVOKABLE QString pathAt(int row) const;
    Q_INVOKABLE bool isDirAt(int row) const;
    Q_INVOKABLE int rowOf(const QString &path) const;
    void refresh();

signals:
    void directoryChanged();
    void showHiddenChanged();
    void countChanged();

private:
    GitInfo *m_git;
    QString m_directory;
    bool m_showHidden = false;
    QVector<QFileInfo> m_entries;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};
