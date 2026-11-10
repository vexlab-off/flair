// flair — a file explorer that reads, finds, sorts, and answers with AI.

#include <QDir>
#include <QFileInfo>
#include <QFont>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#include "ai.h"
#include "backend.h"
#include "filemanager1.h"
#include "filemodel.h"
#include "github.h"
#include "gitinfo.h"
#include "indexer.h"
#include "settings.h"
#include "theme.h"

int main(int argc, char *argv[]) {
    // The HTML preview runs Chromium, which has to be set up before the app.
    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);
    app.setApplicationName("flair");
    app.setApplicationVersion("0.1.0");

    // Matches the window to flair.desktop, so the compositor (Wayland app_id)
    // and the launcher pick up the installed icon.
    app.setDesktopFileName("flair");
    app.setWindowIcon(QIcon::fromTheme("flair"));

    // Compact Material controls, so fields and buttons match the dense lists.
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
    QQuickStyle::setStyle("Material");
    // Inter where installed; Qt falls back to the system sans otherwise.
    QFont font("Inter");
    font.setPixelSize(13);
    font.setHintingPreference(QFont::PreferNoHinting);
    app.setFont(font);

    Theme theme;
    Settings settings;
    theme.setOverride(settings.accentColor());
    QObject::connect(&settings, &Settings::changed, &theme, [&] { theme.setOverride(settings.accentColor()); });
    AiClient ai(&settings);
    GitInfo git;
    FileModel files(&git);
    Indexer indexer(&ai);
    GitHubRepos github;
    Backend backend(&settings, &ai, &files, &git, &indexer, &github);

    // Started by D-Bus for "Show in folder" (--dbus), or with a path or file:// URL.
    QStringList args = app.arguments().mid(1);
    args.removeAll("--dbus");
    QString start = args.isEmpty() ? QDir::currentPath() : args.first();
    if (start.startsWith("file://"))
        start = QUrl(start).toLocalFile();
    if (!backend.navigate(start))
        backend.navigate(QDir::homePath());

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.rootContext()->setContextProperty("files", &files);
    engine.rootContext()->setContextProperty("git", &git);
    engine.rootContext()->setContextProperty("indexer", &indexer);
    engine.rootContext()->setContextProperty("settings", &settings);
    engine.rootContext()->setContextProperty("github", &github);
    // Answer "Show in folder" from other apps while flair is open. When another
    // file manager already holds the name this quietly does nothing.
    auto *fileManager = new FileManager1(&backend, &backend);
    FileManager1::registerOn(&backend);
    engine.rootContext()->setContextProperty("fileManagerBus", fileManager);
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    // `flair page.html` opens its folder with the page selected and previewed.
    if (QFileInfo(start).isFile()) {
        backend.navigate(start);
        if (Backend::isHtml(start) || !Backend::mediaKind(start).isEmpty())
            backend.summarize(QFileInfo(start).absoluteFilePath());
    }

    // Development aid: FLAIR_SNAPSHOT=out.png [FLAIR_SNAPSHOT_DELAY=ms] renders
    // the window to an image and quits; works offscreen.
    const auto snapshot = qEnvironmentVariable("FLAIR_SNAPSHOT");
    if (!snapshot.isEmpty()) {
        const int delay = qEnvironmentVariableIntValue("FLAIR_SNAPSHOT_DELAY");
        QTimer::singleShot(delay > 0 ? delay : 2500, &app, [&engine, snapshot] {
            if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first()))
                window->grabWindow().save(snapshot);
            QCoreApplication::quit();
        });
    }
    return app.exec();
}
