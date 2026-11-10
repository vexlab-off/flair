#pragma once

#include <QDBusAbstractAdaptor>
#include <QStringList>

class Backend;

// org.freedesktop.FileManager1: what browsers, editors and download
// managers call for "Show in folder". Answering it is what makes flair the
// system's file manager rather than an app that happens to list files.
class FileManager1 : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.FileManager1")

public:
    explicit FileManager1(Backend *backend, QObject *parent);

    // Claims the bus name; false when another file manager holds it.
    static bool registerOn(QObject *object);

public slots:
    void ShowFolders(const QStringList &uris, const QString &startupId);
    void ShowItems(const QStringList &uris, const QString &startupId);
    void ShowItemProperties(const QStringList &uris, const QString &startupId);

signals:
    // The window should come to the front.
    void raiseRequested();

private:
    Backend *m_backend;
};
