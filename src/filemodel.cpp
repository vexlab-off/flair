#include "filemodel.h"

#include "gitinfo.h"
#include "textextract.h"

#include <QCollator>
#include <QDateTime>
#include <QDir>
#include <QLocale>
#include <QStandardPaths>
#include <algorithm>

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
        if (m_sortMode == "auto")
            emit sortChanged();
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
    m_entries = dir.entryInfoList(filters, QDir::NoSort).toVector();
    sortEntries(m_entries, effectiveSort(), effectiveDescending());
    endResetModel();
    emit countChanged();
}

QString FileModel::autoSortFor(const QString &directory) {
    const auto clean = QDir::cleanPath(directory);
    const QStringList byDate{QStandardPaths::writableLocation(QStandardPaths::DownloadLocation),
                             QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
                             QStandardPaths::writableLocation(QStandardPaths::MoviesLocation),
                             QStandardPaths::writableLocation(QStandardPaths::DesktopLocation)};
    for (const auto &root : byDate)
        if (!root.isEmpty() && root != QDir::homePath() && (clean == root || clean.startsWith(root + "/")))
            return "date";
    const auto name = QFileInfo(clean).fileName().toLower();
    static const QStringList datedNames{"screenshots", "captures", "téléchargements", "downloads", "photos",
                                        "camera", "dcim", "enregistrements", "recordings"};
    if (datedNames.contains(name))
        return "date";
    return "name";
}

QString FileModel::effectiveSort() const {
    return m_sortMode == "auto" ? autoSortFor(m_directory) : m_sortMode;
}

bool FileModel::effectiveDescending() const {
    // Auto shows the newest first when it sorts by date.
    if (m_sortMode == "auto")
        return effectiveSort() == "date";
    return m_descending;
}

void FileModel::sortEntries(QVector<QFileInfo> &entries, const QString &mode, bool descending) {
    QCollator collator(QLocale(QLocale::French));
    collator.setNumericMode(true); // "photo 2" before "photo 10"
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    std::stable_sort(entries.begin(), entries.end(), [&](const QFileInfo &a, const QFileInfo &b) {
        // Folders stay above files whatever the order.
        if (a.isDir() != b.isDir())
            return a.isDir();
        int c = 0;
        if (mode == "date")
            c = a.lastModified() < b.lastModified() ? -1 : (a.lastModified() > b.lastModified() ? 1 : 0);
        else if (mode == "size")
            c = a.size() < b.size() ? -1 : (a.size() > b.size() ? 1 : 0);
        else if (mode == "type")
            c = collator.compare(TextExtract::category(a) + "/" + a.suffix().toLower(),
                                 TextExtract::category(b) + "/" + b.suffix().toLower());
        if (c != 0)
            return descending ? c > 0 : c < 0;
        // Ties, and the name sort itself, fall back to the name.
        const int n = collator.compare(a.fileName(), b.fileName());
        return mode == "name" && descending ? n > 0 : n < 0;
    });
}

void FileModel::setSortMode(const QString &mode) {
    static const QStringList modes{"auto", "name", "date", "size", "type"};
    if (!modes.contains(mode) || mode == m_sortMode)
        return;
    m_sortMode = mode;
    // Dates and sizes read best biggest/newest first.
    m_descending = mode == "date" || mode == "size";
    emit sortChanged();
    refresh();
}

void FileModel::setDescending(bool descending) {
    if (descending == m_descending)
        return;
    m_descending = descending;
    emit sortChanged();
    refresh();
}

void FileModel::sortBy(const QString &mode) {
    if (mode == m_sortMode && mode != "auto")
        setDescending(!m_descending);
    else
        setSortMode(mode);
}

void FileModel::cycleSort() {
    static const QStringList order{"auto", "name", "date", "size", "type"};
    setSortMode(order[(order.indexOf(m_sortMode) + 1) % order.size()]);
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
