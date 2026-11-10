// flair — a file explorer that reads, finds, sorts, and answers with AI.

#include <QDir>
#include <QFont>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>

#include "ai.h"
#include "backend.h"
#include "filemodel.h"
#include "github.h"
#include "gitinfo.h"
#include "indexer.h"
#include "settings.h"
#include "theme.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("flair");
    app.setApplicationVersion("0.1.0");

    // Matches the window to flair.desktop, so the compositor (Wayland app_id)
    // and the launcher pick up the installed icon.
    app.setDesktopFileName("flair");
    app.setWindowIcon(QIcon::fromTheme("flair"));

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

    const auto args = app.arguments();
    const QString start = args.size() > 1 ? args.at(1) : QDir::currentPath();
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
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    return app.exec();
}
