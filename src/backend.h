#pragma once

#include "plan.h"

#include <QObject>
#include <QVariantList>
#include <QVector>

class AiClient;
class FileModel;
class GitInfo;
class GitHubRepos;
class Indexer;
class Settings;

// Everything the window can ask for: browsing, and the AI work done on the
// folder being browsed. Every AI result lands in one of four panels: preview,
// search, chat, or plan.
class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentPathChanged)
    Q_PROPERTY(QString panel READ panel WRITE setPanel NOTIFY panelChanged)
    // "files" or "github": what the middle column shows.
    Q_PROPERTY(QString view READ view NOTIFY viewChanged)
    Q_PROPERTY(QVariantList places READ places CONSTANT)
    Q_PROPERTY(QStringList breadcrumb READ breadcrumb NOTIFY currentPathChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString error READ error NOTIFY statusChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

    Q_PROPERTY(QString previewTitle READ previewTitle NOTIFY previewChanged)
    Q_PROPERTY(QString previewMeta READ previewMeta NOTIFY previewChanged)
    Q_PROPERTY(QString previewText READ previewText NOTIFY previewChanged)
    Q_PROPERTY(QString previewEngine READ previewEngine NOTIFY previewChanged)

    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery NOTIFY searchChanged)

    Q_PROPERTY(QVariantList chatLog READ chatLog NOTIFY chatChanged)
    Q_PROPERTY(QString chatFolder READ chatFolder NOTIFY chatChanged)

    Q_PROPERTY(QString planExplanation READ planExplanation NOTIFY planChanged)
    Q_PROPERTY(QVariantList planItems READ planItems NOTIFY planChanged)
    Q_PROPERTY(QStringList planSkipped READ planSkipped NOTIFY planChanged)
    Q_PROPERTY(QString planRequest READ planRequest NOTIFY planChanged)

    Q_PROPERTY(bool canUndo READ canUndo NOTIFY historyChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY historyChanged)

    Q_PROPERTY(bool localOnline READ localOnline NOTIFY enginesChanged)
    Q_PROPERTY(QStringList localModels READ localModels NOTIFY enginesChanged)
    Q_PROPERTY(bool claudeReady READ claudeReady NOTIFY enginesChanged)

public:
    Backend(Settings *settings, AiClient *ai, FileModel *files, GitInfo *git, Indexer *indexer,
            GitHubRepos *github, QObject *parent = nullptr);

    QString currentPath() const;
    QString panel() const { return m_panel; }
    QString view() const { return m_view; }
    QVariantList places() const;
    // Absolute path of each level of the current folder, root first.
    QStringList breadcrumb() const;
    void setPanel(const QString &panel);
    QString status() const { return m_status; }
    QString error() const { return m_error; }
    bool busy() const { return m_busy > 0; }

    QString previewTitle() const { return m_previewTitle; }
    QString previewMeta() const { return m_previewMeta; }
    QString previewText() const { return m_previewText; }
    QString previewEngine() const { return m_previewEngine; }
    QVariantList searchResults() const { return m_searchResults; }
    QString searchQuery() const { return m_searchQuery; }
    QVariantList chatLog() const { return m_chatLog; }
    QString chatFolder() const { return m_chatFolder; }
    QString planExplanation() const { return m_plan.explanation; }
    QVariantList planItems() const;
    QStringList planSkipped() const { return m_plan.skipped; }
    QString planRequest() const { return m_planRequest; }
    bool canUndo() const { return !m_undo.isEmpty(); }
    bool canRedo() const { return !m_redo.isEmpty(); }
    bool localOnline() const { return m_localOnline; }
    QStringList localModels() const { return m_localModels; }
    bool claudeReady() const;

    // Browsing
    Q_INVOKABLE bool navigate(const QString &path);
    Q_INVOKABLE void activate(int row);
    Q_INVOKABLE void goUp();
    Q_INVOKABLE void openExternally(const QString &path);
    // Opens a file or folder in the code editor chosen in the settings.
    Q_INVOKABLE void openInEditor(const QString &path);
    // Whether activating this file sends it to the editor rather than the default app.
    bool opensInEditor(const QString &path) const;
    Q_INVOKABLE void reveal(const QString &path);

    // AI
    Q_INVOKABLE void summarize(const QString &path);
    Q_INVOKABLE void search(const QString &query);
    Q_INVOKABLE void buildIndex();
    Q_INVOKABLE void command(const QString &request);
    Q_INVOKABLE void autoSort();
    Q_INVOKABLE void smartSort();
    Q_INVOKABLE void applyPlan();
    Q_INVOKABLE void discardPlan();
    Q_INVOKABLE void ask(const QString &question);
    Q_INVOKABLE void resetChat();
    Q_INVOKABLE void explainChanges();
    Q_INVOKABLE void cancel();

    // Files
    Q_INVOKABLE void undo();
    Q_INVOKABLE void redo();

    // GitHub
    Q_INVOKABLE void openOnWeb();
    Q_INVOKABLE void clone(const QString &repository);
    Q_INVOKABLE void showGitHub();
    Q_INVOKABLE void showFiles();
    // Opens a repository's local clone, cloning it first when there is none.
    Q_INVOKABLE void activateRepo(int row);
    Q_INVOKABLE void summarizeRepo(int row);
    Q_INVOKABLE void openRepoOnWeb(int row);

    Q_INVOKABLE void probeEngines();
    Q_INVOKABLE void clearError();

    // A text outline of a folder tree for the model: names, sizes, dates.
    static QString outline(const QString &root, int depth, int limit);

signals:
    void currentPathChanged();
    void panelChanged();
    void viewChanged();
    void statusChanged();
    void busyChanged();
    void previewChanged();
    void searchChanged();
    void chatChanged();
    void planChanged();
    void historyChanged();
    void enginesChanged();
    // Asks the view to put the cursor on a path after it moves there.
    void selectPath(const QString &path);

private:
    struct Batch {
        QString label;
        QVector<PlanAction> applied;
    };

    void setStatus(const QString &status);
    void setError(const QString &error);
    void begin();
    void end();
    void requestPlan(const QString &request, const QString &instructions);
    void sendChat(const QString &context);
    void setView(const QString &view);
    void cloneInto(const QString &repository, const QString &parent, bool open);
    void summarizeText(const QString &title, const QString &meta, const QString &prompt);

    Settings *m_settings;
    AiClient *m_ai;
    FileModel *m_files;
    GitInfo *m_git;
    Indexer *m_indexer;
    GitHubRepos *m_github;
    QString m_view = "files";

    QString m_panel = "preview";
    QString m_status;
    QString m_error;
    int m_busy = 0;

    QString m_previewTitle, m_previewMeta, m_previewText, m_previewEngine;
    QVariantList m_searchResults;
    QString m_searchQuery;
    QVariantList m_chatLog;
    QString m_chatFolder;
    QString m_chatSystem;
    Plan m_plan;
    QString m_planRequest;
    QVector<Batch> m_undo, m_redo;
    bool m_localOnline = false;
    QStringList m_localModels;

    // Each kind of request carries a generation; a reply from an older
    // generation arrived too late and is dropped.
    int m_previewGeneration = 0, m_searchGeneration = 0, m_chatGeneration = 0, m_planGeneration = 0;
};
