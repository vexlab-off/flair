#pragma once

#include <QByteArray>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QPointer>
#include <QVector>
#include <functional>

class QNetworkAccessManager;
class QNetworkReply;
class Settings;

// Talks to two kinds of model over HTTP: a local OpenAI-compatible server
// (LM Studio or Ollama) and the Claude Messages API. Both stream, and every
// failure comes back as a sentence the window can show as is.
class AiClient : public QObject {
    Q_OBJECT

public:
    enum class Engine { Local, Claude };

    struct Request {
        Engine engine = Engine::Local;
        QString system;
        QJsonArray messages; // [{role, content}] with plain-text content
        int maxTokens = 4096;
        QJsonObject schema; // When set, the reply must be JSON matching it.
        QString effort = "medium";
    };

    using Progress = std::function<void(const QString &visibleSoFar)>;
    using Done = std::function<void(const QString &text)>;
    using Fail = std::function<void(const QString &message)>;
    using Vectors = std::function<void(const QVector<QVector<float>> &)>;

    explicit AiClient(Settings *settings, QObject *parent = nullptr);

    void chat(const Request &request, Progress progress, Done done, Fail fail);
    void embed(const QStringList &texts, Vectors done, Fail fail);
    void cancelAll();
    // Asks the local server which models it has; ok is false when it's unreachable.
    void probeLocal(std::function<void(bool ok, const QStringList &models)> done);

    static Engine engineFromName(const QString &name) { return name == "claude" ? Engine::Claude : Engine::Local; }
    // Reasoning models put their scratchpad in <think> tags; nobody needs to read it.
    static QString stripThinking(const QString &text);
    // Pulls the first JSON object out of a reply that may wrap it in prose or fences.
    static QString extractJson(const QString &text);

    // Splits a Server-Sent Events byte stream into the payloads of its data: lines.
    struct SseParser {
        QByteArray buffer;
        QList<QByteArray> feed(const QByteArray &bytes);
    };

    // Text a single streamed event adds, for each wire format. Errors and
    // refusals are reported through *error.
    static QString claudeEventText(const QJsonObject &event, QString *error);
    static QString openAiEventText(const QJsonObject &event, QString *error);

private:
    void startLocalChat(const Request &request, const QString &model, Progress progress, Done done, Fail fail);
    void startClaudeChat(const Request &request, Progress progress, Done done, Fail fail);
    void stream(QNetworkReply *reply, bool claude, Progress progress, Done done, Fail fail);
    void withLocalModel(std::function<void(const QString &)> then, Fail fail);
    QString networkError(QNetworkReply *reply, const QByteArray &body, bool claude) const;
    QNetworkReply *track(QNetworkReply *reply);

    Settings *m_settings;
    QNetworkAccessManager *m_network;
    QString m_resolvedLocalModel;
    QList<QPointer<QNetworkReply>> m_replies;
};
