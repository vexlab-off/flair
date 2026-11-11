#include "mediafolder.h"

#include "textextract.h"

#include <QClipboard>
#include <QCollator>
#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QLocale>
#include <QProcess>
#include <QUrl>
#include <algorithm>

MediaFolder::MediaFolder(const QString &kind, QObject *parent) : QObject(parent), m_kind(kind) {}

QString MediaFolder::name() const { return QFileInfo(path()).fileName(); }

void MediaFolder::setMessage(const QString &message) {
    m_message = message;
    emit messageChanged();
}

bool MediaFolder::matches(const QString &kind, const QString &path) {
    const QFileInfo info(path);
    if (!info.isFile())
        return false;
    const auto category = TextExtract::category(info);
    const auto suffix = info.suffix().toLower();
    if (kind == "image")
        return category == "image" && suffix != "psd" && suffix != "xcf" && suffix != "kra" && suffix != "raw" &&
               suffix != "cr2" && suffix != "nef";
    return category == "video" || category == "audio";
}

QStringList MediaFolder::siblings(const QString &kind, const QString &directory) {
    QStringList files;
    for (const auto &info : QDir(directory).entryInfoList(QDir::Files))
        if (matches(kind, info.absoluteFilePath()))
            files << info.absoluteFilePath();
    QCollator collator(QLocale(QLocale::French));
    collator.setNumericMode(true);
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    std::sort(files.begin(), files.end(), [&](const QString &a, const QString &b) {
        return collator.compare(QFileInfo(a).fileName(), QFileInfo(b).fileName()) < 0;
    });
    return files;
}

bool MediaFolder::open(const QString &pathIn) {
    QString target = pathIn;
    if (target.startsWith("file://"))
        target = QUrl(target).toLocalFile();
    const QFileInfo info(target);
    const auto directory = info.isDir() ? info.absoluteFilePath() : info.absolutePath();
    m_files = siblings(m_kind, directory);
    m_index = info.isDir() ? (m_files.isEmpty() ? -1 : 0) : int(m_files.indexOf(info.absoluteFilePath()));
    if (m_index < 0 && !info.isDir() && info.isFile()) {
        // A file of an unusual type given explicitly is still shown.
        m_files.prepend(info.absoluteFilePath());
        m_index = 0;
    }
    emit changed();
    if (m_files.isEmpty())
        setMessage(m_kind == "image" ? tr("Aucune image dans ce dossier.") : tr("Aucune vidéo ni musique dans ce dossier."));
    return m_index >= 0;
}

void MediaFolder::go(int index) {
    if (m_files.isEmpty())
        return;
    const int n = int(m_files.size());
    const int next = ((index % n) + n) % n;
    if (next == m_index)
        return;
    m_index = next;
    emit changed();
}

void MediaFolder::next() { go(m_index + 1); }
void MediaFolder::previous() { go(m_index - 1); }

bool MediaFolder::trashCurrent() {
    const auto current = path();
    if (current.isEmpty())
        return false;
    if (!QFile::moveToTrash(current)) {
        setMessage(tr("Impossible de mettre « %1 » à la corbeille.").arg(name()));
        return false;
    }
    setMessage(tr("« %1 » est dans la corbeille (récupérable depuis la corbeille du système).").arg(QFileInfo(current).fileName()));
    m_files.removeAt(m_index);
    if (m_index >= m_files.size())
        m_index = int(m_files.size()) - 1;
    emit changed();
    return true;
}

void MediaFolder::copyPath() {
    QGuiApplication::clipboard()->setText(path());
    setMessage(tr("Chemin copié."));
}

void MediaFolder::revealInFlair() {
    QProcess::startDetached(QCoreApplication::applicationFilePath(), {path()});
}

void MediaFolder::openWithSystem() {
    QDesktopServices::openUrl(QUrl::fromLocalFile(path()));
}

QVariantMap MediaFolder::info() const {
    const QFileInfo info(path());
    if (!info.exists())
        return {};
    const QLocale fr(QLocale::French);
    return {{"name", info.fileName()},
            {"folder", info.absolutePath()},
            {"size", TextExtract::humanSize(info.size())},
            {"modified", fr.toString(info.lastModified(), "d MMMM yyyy à HH:mm")},
            {"type", info.suffix().toUpper()}};
}
