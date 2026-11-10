#include "ai.h"

#include "settings.h"

#include <QJsonDocument>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QSharedPointer>
#include <QUrl>

static const char *kAnthropicVersion = "2026-10-21";

// Models that take server-side refusal fallbacks; anything else would reject
// the parameter.
static bool supportsFallbacks(const QString &model) {
    static const QStringList models{"claude-fable-5-2", "claude-fable-5-1", "claude-opus-5-5", "claude-opus-5",
                                    "claude-sonnet-5-5"};
    return models.contains(model);
}

AiClient::AiClient(Settings *settings, QObject *parent)
    : QObject(parent), m_settings(settings), m_network(new QNetworkAccessManager(this)) {
    // A different server or model invalidates the model we discovered.
    connect(m_settings, &Settings::changed, this, [this] { m_resolvedLocalModel.clear(); });
}

QNetworkReply *AiClient::track(QNetworkReply *reply) {
    m_replies.removeAll(nullptr);
    m_replies.append(reply);
    return reply;
}

void AiClient::cancelAll() {
    const auto replies = m_replies;
    m_replies.clear();
    for (const auto &reply : replies) {
        if (reply) {
            reply->setProperty("flairCancelled", true);
            reply->abort();
        }
    }
}

QString AiClient::stripThinking(const QString &text) {
    static const QRegularExpression closed(R"(<think>.*?</think>)", QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression open(R"(<think>.*$)", QRegularExpression::DotMatchesEverythingOption);
    QString out = text;
    out.remove(closed);
    out.remove(open);
    return out.trimmed();
}

QString AiClient::extractJson(const QString &text) {
    const QString clean = stripThinking(text);
    const int start = clean.indexOf('{');
    const int end = clean.lastIndexOf('}');
    if (start < 0 || end <= start)
        return {};
    return clean.mid(start, end - start + 1);
}

QList<QByteArray> AiClient::SseParser::feed(const QByteArray &bytes) {
    buffer += bytes;
    QList<QByteArray> payloads;
    int newline;
    while ((newline = buffer.indexOf('\n')) >= 0) {
        QByteArray line = buffer.left(newline);
        buffer.remove(0, newline + 1);
        if (line.endsWith('\r'))
            line.chop(1);
        if (line.startsWith("data:")) {
            QByteArray payload = line.mid(5).trimmed();
            if (!payload.isEmpty())
                payloads.append(payload);
        }
    }
    return payloads;
}

QString AiClient::claudeEventText(const QJsonObject &event, QString *error) {
    const auto type = event.value("type").toString();
    if (type == "content_block_delta") {
        const auto delta = event.value("delta").toObject();
        if (delta.value("type").toString() == "text_delta")
            return delta.value("text").toString();
    } else if (type == "message_delta") {
        const auto reason = event.value("delta").toObject().value("stop_reason").toString();
        if (reason == "refusal" && error)
            *error = QObject::tr("Claude a refusé de répondre à cette demande.");
    } else if (type == "error" && error) {
        const auto e = event.value("error").toObject();
        *error = QObject::tr("Erreur Claude (%1) : %2").arg(e.value("type").toString(), e.value("message").toString());
    }
    return {};
}

QString AiClient::openAiEventText(const QJsonObject &event, QString *error) {
    if (event.contains("error") && error) {
        const auto e = event.value("error");
        *error = QObject::tr("Erreur du modèle local : %1")
                     .arg(e.isObject() ? e.toObject().value("message").toString() : e.toString());
        return {};
    }
    const auto choices = event.value("choices").toArray();
    if (choices.isEmpty())
        return {};
    return choices.first().toObject().value("delta").toObject().value("content").toString();
}

QString AiClient::networkError(QNetworkReply *reply, const QByteArray &body, bool claude) const {
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (status == 0) {
        if (claude)
            return tr("Impossible de joindre l'API Claude : %1").arg(reply->errorString());
        return tr("Le serveur IA local ne répond pas sur %1. Lance le serveur de LM Studio "
                  "(onglet Developer → Start Server) ou Ollama, ou change l'adresse dans les réglages (Ctrl+,).")
            .arg(m_settings->localUrl());
    }
    QString detail;
    const auto json = QJsonDocument::fromJson(body).object();
    const auto e = json.value("error");
    if (e.isObject())
        detail = e.toObject().value("message").toString();
    else if (e.isString())
        detail = e.toString();
    if (detail.isEmpty())
        detail = QString::fromUtf8(body.left(300)).trimmed();
    if (claude && status == 401)
        return tr("Clé API Anthropic refusée (401). Vérifie-la dans les réglages (Ctrl+,).");
    return tr("%1 a répondu %2 : %3").arg(claude ? "Claude" : tr("Le serveur local")).arg(status).arg(detail);
}

void AiClient::stream(QNetworkReply *reply, bool claude, Progress progress, Done done, Fail fail) {
    track(reply);
    auto parser = QSharedPointer<SseParser>::create();
    auto full = QSharedPointer<QString>::create();
    auto failure = QSharedPointer<QString>::create();
    auto body = QSharedPointer<QByteArray>::create();

    connect(reply, &QNetworkReply::readyRead, this, [=] {
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray bytes = reply->readAll();
        if (status >= 400) {
            *body += bytes;
            return;
        }
        bool grew = false;
        for (const auto &payload : parser->feed(bytes)) {
            if (payload == "[DONE]")
                continue;
            const auto event = QJsonDocument::fromJson(payload).object();
            QString error;
            const auto text = claude ? claudeEventText(event, &error) : openAiEventText(event, &error);
            if (!error.isEmpty())
                *failure = error;
            if (!text.isEmpty()) {
                *full += text;
                grew = true;
            }
        }
        if (grew && progress)
            progress(stripThinking(*full));
    });

    connect(reply, &QNetworkReply::finished, this, [=] {
        reply->deleteLater();
        m_replies.removeAll(reply);
        if (reply->property("flairCancelled").toBool())
            return;
        *body += reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            fail(networkError(reply, *body, claude));
            return;
        }
        if (!failure->isEmpty()) {
            fail(*failure);
            return;
        }
        done(stripThinking(*full));
    });
}

void AiClient::withLocalModel(std::function<void(const QString &)> then, Fail fail) {
    if (!m_settings->localModel().isEmpty()) {
        then(m_settings->localModel());
        return;
    }
    if (!m_resolvedLocalModel.isEmpty()) {
        then(m_resolvedLocalModel);
        return;
    }
    // No model configured: use the first chat model the server has, so a fresh
    // LM Studio or Ollama setup works without visiting the settings.
    QNetworkRequest request(QUrl(m_settings->localUrl() + "/v1/models"));
    request.setTransferTimeout(10000);
    auto *reply = track(m_network->get(request));
    connect(reply, &QNetworkReply::finished, this, [=] {
        reply->deleteLater();
        m_replies.removeAll(reply);
        if (reply->property("flairCancelled").toBool())
            return;
        const auto body = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            fail(networkError(reply, body, false));
            return;
        }
        for (const auto &value : QJsonDocument::fromJson(body).object().value("data").toArray()) {
            const auto id = value.toObject().value("id").toString();
            if (!id.contains("embed", Qt::CaseInsensitive)) {
                m_resolvedLocalModel = id;
                then(id);
                return;
            }
        }
        fail(tr("Le serveur local à %1 n'a aucun modèle de chat chargé. Charge-en un dans LM Studio ou Ollama.")
                 .arg(m_settings->localUrl()));
    });
}

void AiClient::probeLocal(std::function<void(bool, const QStringList &)> done) {
    QNetworkRequest request(QUrl(m_settings->localUrl() + "/v1/models"));
    request.setTransferTimeout(4000);
    auto *reply = m_network->get(request);
    connect(reply, &QNetworkReply::finished, this, [=] {
        reply->deleteLater();
        QStringList models;
        for (const auto &value : QJsonDocument::fromJson(reply->readAll()).object().value("data").toArray())
            models << value.toObject().value("id").toString();
        done(reply->error() == QNetworkReply::NoError, models);
    });
}

void AiClient::chat(const Request &request, Progress progress, Done done, Fail fail) {
    if (request.engine == Engine::Claude) {
        startClaudeChat(request, progress, done, fail);
        return;
    }
    withLocalModel([=](const QString &model) { startLocalChat(request, model, progress, done, fail); }, fail);
}

void AiClient::startLocalChat(const Request &request, const QString &model, Progress progress, Done done, Fail fail) {
    QJsonArray messages;
    if (!request.system.isEmpty())
        messages.append(QJsonObject{{"role", "system"}, {"content", request.system}});
    for (const auto &m : request.messages)
        messages.append(m);

    QJsonObject body{{"model", model}, {"messages", messages}, {"stream", true}, {"max_tokens", request.maxTokens}};
    if (!request.schema.isEmpty())
        body["response_format"] = QJsonObject{
            {"type", "json_schema"},
            {"json_schema", QJsonObject{{"name", "answer"}, {"strict", true}, {"schema", request.schema}}}};

    QNetworkRequest http(QUrl(m_settings->localUrl() + "/v1/chat/completions"));
    http.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    // Loading a large model can take a while before the first token arrives.
    http.setTransferTimeout(300000);
    stream(m_network->post(http, QJsonDocument(body).toJson(QJsonDocument::Compact)), false, progress, done, fail);
}

void AiClient::startClaudeChat(const Request &request, Progress progress, Done done, Fail fail) {
    const auto key = m_settings->anthropicKey();
    if (key.isEmpty()) {
        fail(tr("Aucune clé API Anthropic. Exporte ANTHROPIC_API_KEY ou ajoute la clé dans les réglages (Ctrl+,), "
                "ou bascule cette tâche sur le modèle local."));
        return;
    }
    const auto model = m_settings->claudeModel();
    QJsonObject outputConfig{{"effort", request.effort}};
    if (!request.schema.isEmpty())
        outputConfig["format"] = QJsonObject{{"type", "json_schema"}, {"schema", request.schema}};

    QJsonObject body{{"model", model},
                     {"max_tokens", request.maxTokens},
                     {"stream", true},
                     {"messages", request.messages},
                     {"output_config", outputConfig}};
    if (!request.system.isEmpty())
        body["system"] = request.system;

    QNetworkRequest http(QUrl("https://api.anthropic.com/v1/messages"));
    http.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    http.setRawHeader("x-api-key", key.toUtf8());
    http.setRawHeader("anthropic-version", kAnthropicVersion);
    // If a safety classifier declines, the API retries on a fallback model in
    // the same call instead of just stopping.
    if (supportsFallbacks(model)) {
        body["fallbacks"] = "default";
        http.setRawHeader("anthropic-beta", "server-side-fallback-2026-07-01");
    }
    http.setTransferTimeout(300000);
    stream(m_network->post(http, QJsonDocument(body).toJson(QJsonDocument::Compact)), true, progress, done, fail);
}

void AiClient::embed(const QStringList &texts, Vectors done, Fail fail) {
    const auto model = m_settings->embedModel();
    QJsonObject body{{"model", model}, {"input", QJsonArray::fromStringList(texts)}};
    QNetworkRequest http(QUrl(m_settings->localUrl() + "/v1/embeddings"));
    http.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    http.setTransferTimeout(300000);
    auto *reply = track(m_network->post(http, QJsonDocument(body).toJson(QJsonDocument::Compact)));
    connect(reply, &QNetworkReply::finished, this, [=] {
        reply->deleteLater();
        m_replies.removeAll(reply);
        if (reply->property("flairCancelled").toBool())
            return;
        const auto bytes = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (status == 400 || status == 404)
                fail(tr("Le modèle d'embeddings « %1 » n'est pas disponible sur %2. Télécharge un modèle comme "
                        "nomic-embed-text dans LM Studio (ou `ollama pull nomic-embed-text`), puis indique son nom "
                        "dans les réglages (Ctrl+,).")
                         .arg(model, m_settings->localUrl()));
            else
                fail(networkError(reply, bytes, false));
            return;
        }
        const auto data = QJsonDocument::fromJson(bytes).object().value("data").toArray();
        QVector<QVector<float>> vectors(texts.size());
        for (const auto &item : data) {
            const auto object = item.toObject();
            const int index = object.value("index").toInt(-1);
            if (index < 0 || index >= vectors.size())
                continue;
            const auto values = object.value("embedding").toArray();
            QVector<float> vector;
            vector.reserve(values.size());
            for (const auto &v : values)
                vector.append(float(v.toDouble()));
            vectors[index] = vector;
        }
        for (const auto &v : vectors) {
            if (v.isEmpty()) {
                fail(tr("Le serveur d'embeddings a renvoyé une réponse incomplète."));
                return;
            }
        }
        done(vectors);
    });
}
