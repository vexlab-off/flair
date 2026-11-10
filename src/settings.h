#pragma once

#include <QObject>
#include <QSettings>
#include <QVariantList>

// Where the AI lives and which engine each kind of work goes to. Stored in
// ~/.config/flair/flair.conf (mode 0600, since it may hold an API key).
class Settings : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString localUrl READ localUrl WRITE setLocalUrl NOTIFY changed)
    Q_PROPERTY(QString localModel READ localModel WRITE setLocalModel NOTIFY changed)
    Q_PROPERTY(QString embedModel READ embedModel WRITE setEmbedModel NOTIFY changed)
    Q_PROPERTY(QString claudeModel READ claudeModel WRITE setClaudeModel NOTIFY changed)
    Q_PROPERTY(QString anthropicKey READ storedKey WRITE setAnthropicKey NOTIFY changed)
    Q_PROPERTY(bool keyFromEnvironment READ keyFromEnvironment CONSTANT)
    Q_PROPERTY(QString summaryEngine READ summaryEngine WRITE setSummaryEngine NOTIFY changed)
    Q_PROPERTY(QString heavyEngine READ heavyEngine WRITE setHeavyEngine NOTIFY changed)
    Q_PROPERTY(QString cloneDirectory READ cloneDirectory WRITE setCloneDirectory NOTIFY changed)
    Q_PROPERTY(QString accentColor READ accentColor WRITE setAccentColor NOTIFY changed)
    Q_PROPERTY(QString logoStyle READ logoStyle WRITE setLogoStyle NOTIFY changed)
    Q_PROPERTY(bool launcherFollowsAccent READ launcherFollowsAccent WRITE setLauncherFollowsAccent NOTIFY changed)
    Q_PROPERTY(QString editorCommand READ editorCommand WRITE setEditorCommand NOTIFY changed)
    // What Enter does on an HTML file: "preview", "editor" or "browser".
    Q_PROPERTY(QString htmlOpenMode READ htmlOpenMode WRITE setHtmlOpenMode NOTIFY changed)
    Q_PROPERTY(bool openCodeInEditor READ openCodeInEditor WRITE setOpenCodeInEditor NOTIFY changed)

public:
    explicit Settings(const QString &file = {}, QObject *parent = nullptr);

    QString localUrl() const;
    QString localModel() const;
    QString embedModel() const;
    QString claudeModel() const;
    QString storedKey() const;
    // The key actually used: ANTHROPIC_API_KEY wins over the stored one.
    QString anthropicKey() const;
    bool keyFromEnvironment() const;
    // "local" or "claude".
    QString summaryEngine() const;
    QString heavyEngine() const;
    // Where repositories opened from the GitHub view get cloned.
    QString cloneDirectory() const;
    // "theme" to follow Vex, or a #rrggbb colour.
    QString accentColor() const;
    QString logoStyle() const { return get("appearance/logoStyle", "plein"); }
    void setLogoStyle(const QString &v) { put("appearance/logoStyle", v); }
    bool launcherFollowsAccent() const { return get("appearance/launcherIcon", "true") == "true"; }
    void setLauncherFollowsAccent(bool v) { put("appearance/launcherIcon", v ? "true" : "false"); }
    // The program files open in: a command name such as code, codium or zed.
    QString editorCommand() const;
    QString htmlOpenMode() const;
    bool openCodeInEditor() const;

    void setLocalUrl(const QString &v);
    void setLocalModel(const QString &v);
    void setEmbedModel(const QString &v);
    void setClaudeModel(const QString &v);
    void setAnthropicKey(const QString &v);
    void setSummaryEngine(const QString &v);
    void setHeavyEngine(const QString &v);
    void setCloneDirectory(const QString &v);
    void setAccentColor(const QString &v);
    void setEditorCommand(const QString &v);
    void setHtmlOpenMode(const QString &v);
    void setOpenCodeInEditor(bool v);

    // The file manager to restore when flair stops being the default.
    QString previousFileManager() const { return m_settings.value("system/previousFileManager").toString(); }
    void setPreviousFileManager(const QString &v) { put("system/previousFileManager", v); }

    // Code editors installed on this machine, as {command, name} maps.
    Q_INVOKABLE QVariantList installedEditors() const;

signals:
    void changed();

private:
    QString get(const QString &key, const QString &fallback) const;
    void put(const QString &key, const QString &value);

    QSettings m_settings;
};
