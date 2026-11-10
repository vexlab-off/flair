#include "filemanager1.h"

#include "backend.h"

#include <QDBusConnection>
#include <QFileInfo>
#include <QUrl>

static QString localPath(const QString &uri) {
    const QUrl url(uri);
    return url.isLocalFile() ? url.toLocalFile() : uri;
}

FileManager1::FileManager1(Backend *backend, QObject *parent) : QDBusAbstractAdaptor(parent), m_backend(backend) {}

bool FileManager1::registerOn(QObject *object) {
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected())
        return false;
    if (!bus.registerObject("/org/freedesktop/FileManager1", object))
        return false;
    return bus.registerService("org.freedesktop.FileManager1");
}

void FileManager1::ShowFolders(const QStringList &uris, const QString &) {
    if (!uris.isEmpty())
        m_backend->navigate(localPath(uris.first()));
    emit raiseRequested();
}

void FileManager1::ShowItems(const QStringList &uris, const QString &) {
    // navigate() on a file opens its folder with the cursor on it.
    if (!uris.isEmpty())
        m_backend->navigate(localPath(uris.first()));
    emit raiseRequested();
}

void FileManager1::ShowItemProperties(const QStringList &uris, const QString &) {
    if (!uris.isEmpty()) {
        const auto path = localPath(uris.first());
        m_backend->navigate(path);
        m_backend->requestProperties(QFileInfo(path).absoluteFilePath());
    }
    emit raiseRequested();
}
