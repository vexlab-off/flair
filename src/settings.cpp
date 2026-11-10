#include "settings.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QVariantMap>

static QString defaultFile() {
    return QDir::homePath() + "/.config/flair/flair.conf";
}

Settings::Settings(const QString &file, QObject *parent)
    : QObject(parent), m_settings(file.isEmpty() ? defaultFile() : file, QSettings::IniFormat) {}

QString Settings::get(const QString &key, const QString &fallback) const {
    const auto value = m_settings.value(key).toString().trimmed();
    return value.isEmpty() ? fallback : value;
}

void Settings::put(const QString &key, const QString &value) {
    if (m_settings.value(key).toString() == value)
        return;
    m_settings.setValue(key, value);
    m_settings.sync();
    // The file can hold an API key, so keep it readable by the user only.
    QFile::setPermissions(m_settings.fileName(), QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    emit changed();
}

// LM Studio's server listens on 1234; Ollama's OpenAI-compatible API on 11434.
QString Settings::localUrl() const { return get("local/url", "http://localhost:1234"); }
// Empty means "ask the server which chat model is loaded".
QString Settings::localModel() const { return m_settings.value("local/model").toString().trimmed(); }
QString Settings::embedModel() const { return get("local/embedModel", "text-embedding-nomic-embed-text-v1.5"); }
QString Settings::claudeModel() const { return get("claude/model", "claude-opus-5-5"); }
QString Settings::storedKey() const { return m_settings.value("claude/apiKey").toString().trimmed(); }

QString Settings::anthropicKey() const {
    const auto env = qEnvironmentVariable("ANTHROPIC_API_KEY").trimmed();
    return env.isEmpty() ? storedKey() : env;
}

bool Settings::keyFromEnvironment() const { return !qEnvironmentVariable("ANTHROPIC_API_KEY").trimmed().isEmpty(); }

// Summaries are frequent and short, so they default to the local model; plans
// and chat need stronger reasoning and default to Claude.
QString Settings::summaryEngine() const { return get("routing/summary", "local"); }
QString Settings::heavyEngine() const { return get("routing/heavy", "claude"); }

void Settings::setLocalUrl(const QString &v) { put("local/url", v.trimmed()); }
void Settings::setLocalModel(const QString &v) { put("local/model", v.trimmed()); }
void Settings::setEmbedModel(const QString &v) { put("local/embedModel", v.trimmed()); }
void Settings::setClaudeModel(const QString &v) { put("claude/model", v.trimmed()); }
void Settings::setAnthropicKey(const QString &v) { put("claude/apiKey", v.trimmed()); }
void Settings::setSummaryEngine(const QString &v) { put("routing/summary", v == "claude" ? "claude" : "local"); }
void Settings::setHeavyEngine(const QString &v) { put("routing/heavy", v == "local" ? "local" : "claude"); }

QString Settings::cloneDirectory() const {
    const auto work = QDir::homePath() + "/Work";
    return get("github/cloneDirectory", QFileInfo(work).isDir() ? work : QDir::homePath());
}

void Settings::setCloneDirectory(const QString &v) {
    auto path = v.trimmed();
    if (path.startsWith("~"))
        path = QDir::homePath() + path.mid(1);
    put("github/cloneDirectory", path);
}

// Orange unless the user picks otherwise; "theme" hands the choice back to Vex.
QString Settings::accentColor() const { return get("appearance/accent", "#ff8a3d"); }

void Settings::setAccentColor(const QString &v) {
    static const QRegularExpression hex("^#[0-9a-fA-F]{6}$");
    const auto value = v.trimmed();
    if (value == "theme" || hex.match(value).hasMatch())
        put("appearance/accent", value.toLower());
}

static const QList<QPair<QString, QString>> &knownEditors() {
    static const QList<QPair<QString, QString>> editors{
        {"code", "Visual Studio Code"}, {"code-oss", "Code - OSS"}, {"codium", "VSCodium"},
        {"zed", "Zed"},                 {"subl", "Sublime Text"},  {"kate", "Kate"},
        {"gnome-text-editor", "Éditeur de texte GNOME"}};
    return editors;
}

QVariantList Settings::installedEditors() const {
    QVariantList list;
    for (const auto &e : knownEditors())
        if (!QStandardPaths::findExecutable(e.first).isEmpty())
            list.append(QVariantMap{{"command", e.first}, {"name", e.second}});
    return list;
}

QString Settings::editorCommand() const {
    const auto stored = m_settings.value("editor/command").toString().trimmed();
    if (!stored.isEmpty())
        return stored;
    // Default to the first editor that's installed, VS Code first.
    for (const auto &e : knownEditors())
        if (!QStandardPaths::findExecutable(e.first).isEmpty())
            return e.first;
    return "code";
}

void Settings::setEditorCommand(const QString &v) { put("editor/command", v.trimmed()); }
QString Settings::htmlOpenMode() const { return get("editor/htmlMode", "preview"); }
bool Settings::openCodeInEditor() const { return get("editor/code", "true") == "true"; }
void Settings::setHtmlOpenMode(const QString &v) {
    if (v == "preview" || v == "editor" || v == "browser")
        put("editor/htmlMode", v);
}
void Settings::setOpenCodeInEditor(bool v) { put("editor/code", v ? "true" : "false"); }
