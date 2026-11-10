#pragma once

#include <QObject>
#include <QSettings>

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

    void setLocalUrl(const QString &v);
    void setLocalModel(const QString &v);
    void setEmbedModel(const QString &v);
    void setClaudeModel(const QString &v);
    void setAnthropicKey(const QString &v);
    void setSummaryEngine(const QString &v);
    void setHeavyEngine(const QString &v);
    void setCloneDirectory(const QString &v);

signals:
    void changed();

private:
    QString get(const QString &key, const QString &fallback) const;
    void put(const QString &key, const QString &value);

    QSettings m_settings;
};
