#include "filemodel.h"

#include "gitinfo.h"
#include "textextract.h"

#include <QDateTime>
#include <QDir>
#include <QLocale>

FileModel::FileModel(GitInfo *git, QObject *parent) : QAbstractListModel(parent), m_git(git) {
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(150);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { m_debounce.start(); });
    connect(&m_debounce, &QTimer::timeout, this, [this] {
        refresh();
        m_git->refresh(m_directory);
    });
    connect(m_git, &GitInfo::changed, this, [this] {
        if (!m_entries.isEmpty())
            emit dataChanged(index(0), index(int(m_entries.size()) - 1), {GitRole});
    });
}

int FileModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : int(m_entries.size());
}

QVariant FileModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_entries.size())
        return {};
    const auto &info = m_entries[index.row()];
    switch (role) {
    case NameRole:
        return info.fileName();
    case PathRole:
        return info.absoluteFilePath();
    case IsDirRole:
        return info.isDir();
    case SizeRole:
        return info.isDir() ? QString() : TextExtract::humanSize(info.size());
    case ModifiedRole:
        return QLocale(QLocale::French).toString(info.lastModified(), "d MMM yyyy HH:mm");
    case KindRole:
        return TextExtract::category(info);
    case GitRole:
        return m_git->statusFor(info.absoluteFilePath());
    }
    return {};
}

QHash<int, QByteArray> FileModel::roleNames() const {
    return {{NameRole, "name"},     {PathRole, "path"}, {IsDirRole, "isDir"}, {SizeRole, "size"},
            {ModifiedRole, "modified"}, {KindRole, "kind"}, {GitRole, "git"}};
}

void FileModel::setShowHidden(bool show) {
    if (show == m_showHidden)
        return;
    m_showHidden = show;
    emit showHiddenChanged();
    refresh();
}

bool FileModel::setDirectory(const QString &path) {
    const QFileInfo info(path);
    if (!info.isDir() || !info.isReadable())
        return false;
    const auto clean = QDir::cleanPath(info.absoluteFilePath());
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());
    m_watcher.addPath(clean);
    if (clean != m_directory) {
        m_directory = clean;
        emit directoryChanged();
    }
    refresh();
    m_git->refresh(m_directory);
    return true;
}

void FileModel::refresh() {
    QDir dir(m_directory);
    auto filters = QDir::AllEntries | QDir::NoDotAndDotDot;
    if (m_showHidden)
        filters |= QDir::Hidden;
    beginResetModel();
    m_entries = dir.entryInfoList(filters, QDir::DirsFirst | QDir::Name | QDir::IgnoreCase).toVector();
    endResetModel();
    emit countChanged();
}

QString FileModel::pathAt(int row) const {
    return row >= 0 && row < m_entries.size() ? m_entries[row].absoluteFilePath() : QString();
}

bool FileModel::isDirAt(int row) const {
    return row >= 0 && row < m_entries.size() && m_entries[row].isDir();
}

int FileModel::rowOf(const QString &path) const {
    for (int i = 0; i < m_entries.size(); ++i)
        if (m_entries[i].absoluteFilePath() == path)
            return i;
    return -1;
}
