#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QTemporaryDir>
#include <QTimeZone>
#include <QtTest>

#include "ai.h"
#include "backend.h"
#include "github.h"
#include "gitinfo.h"
#include "indexer.h"
#include "plan.h"
#include "settings.h"
#include "textextract.h"
#include "theme.h"

static void touch(const QString &path, const QByteArray &content = "x") {
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write(content);
}

class FlairTests : public QObject {
    Q_OBJECT

private slots:
    // ------------------------------------------------------------ theme
    void themeFallsBack() {
        QTemporaryDir dir;
        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#FFD60A"));
        QCOMPARE(theme.accentForeground(), QString("black"));
    }

    void themeReadsAccent() {
        QTemporaryDir dir;
        touch(dir.path() + "/theme/colors.toml", "accent = \"#112233\"\n");
        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#112233"));
        QCOMPARE(theme.accentForeground(), QString("white"));
    }

    void highlightAvoidsGreyAccent() {
        QTemporaryDir dir;
        touch(dir.path() + "/theme/colors.toml",
              "accent = \"#6b7280\"\nbackground = \"#0b0d10\"\nforeground = \"#f3f4f6\"\nblue = \"#5c82da\"\n");
        Theme grey(dir.path());
        QCOMPARE(grey.highlight().name(), QString("#5c82da"));
        QCOMPARE(grey.background().name(), QString("#0b0d10"));

        QTemporaryDir vivid;
        touch(vivid.path() + "/theme/colors.toml", "accent = \"#e0a030\"\nblue = \"#5c82da\"\n");
        QCOMPARE(Theme(vivid.path()).highlight().name(), QString("#e0a030"));
    }

    // ------------------------------------------------------------ settings
    void settingsDefaultsAndRouting() {
        QTemporaryDir dir;
        Settings settings(dir.path() + "/flair.conf");
        QCOMPARE(settings.claudeModel(), QString("claude-opus-5-5"));
        QCOMPARE(settings.summaryEngine(), QString("local"));
        QCOMPARE(settings.heavyEngine(), QString("claude"));
        settings.setHeavyEngine("nonsense");
        QCOMPARE(settings.heavyEngine(), QString("claude"));
        settings.setAnthropicKey("sk-test");
        QCOMPARE(QFile::permissions(dir.path() + "/flair.conf") & (QFileDevice::ReadGroup | QFileDevice::ReadOther),
                 QFileDevice::Permissions());
    }

    // ------------------------------------------------------------ AI wire formats
    void sseSplitsAcrossChunks() {
        AiClient::SseParser parser;
        QVERIFY(parser.feed("event: x\ndata: {\"a\"").isEmpty());
        const auto payloads = parser.feed(":1}\r\n\ndata: [DONE]\n");
        QCOMPARE(payloads.size(), 2);
        QCOMPARE(payloads[0], QByteArray("{\"a\":1}"));
        QCOMPARE(payloads[1], QByteArray("[DONE]"));
    }

    void claudeEvents() {
        QString error;
        const auto delta = QJsonDocument::fromJson(
            R"({"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Salut"}})").object();
        QCOMPARE(AiClient::claudeEventText(delta, &error), QString("Salut"));
        const auto thinking = QJsonDocument::fromJson(
            R"({"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"hmm"}})").object();
        QCOMPARE(AiClient::claudeEventText(thinking, &error), QString());
        QVERIFY(error.isEmpty());
        const auto refusal = QJsonDocument::fromJson(R"({"type":"message_delta","delta":{"stop_reason":"refusal"}})").object();
        AiClient::claudeEventText(refusal, &error);
        QVERIFY(!error.isEmpty());
    }

    void openAiEvents() {
        QString error;
        const auto delta = QJsonDocument::fromJson(R"({"choices":[{"delta":{"content":"ok"}}]})").object();
        QCOMPARE(AiClient::openAiEventText(delta, &error), QString("ok"));
        const auto failure = QJsonDocument::fromJson(R"({"error":{"message":"boom"}})").object();
        AiClient::openAiEventText(failure, &error);
        QVERIFY(error.contains("boom"));
    }

    void stripsThinkingAndFindsJson() {
        QCOMPARE(AiClient::stripThinking("<think>plan</think>\nRéponse"), QString("Réponse"));
        QCOMPARE(AiClient::stripThinking("<think>encore en cours"), QString());
        QCOMPARE(AiClient::extractJson("Voici :\n```json\n{\"a\": {\"b\": 1}}\n```"), QString("{\"a\": {\"b\": 1}}"));
        QCOMPARE(AiClient::extractJson("pas de json"), QString());
    }

    // ------------------------------------------------------------ plans
    void planKeepsSafeActionsOnly() {
        QTemporaryDir dir;
        const auto root = dir.path();
        touch(root + "/a.txt");
        touch(root + "/b.txt");
        touch(root + "/taken.txt");
        const auto json = R"({"explanation":"test","actions":[
            {"op":"mkdir","from":"","to":"Docs"},
            {"op":"move","from":"a.txt","to":"Docs/a.txt"},
            {"op":"move","from":"a.txt","to":"again.txt"},
            {"op":"move","from":"b.txt","to":"taken.txt"},
            {"op":"move","from":"b.txt","to":"../escape.txt"},
            {"op":"move","from":"/etc/passwd","to":"p.txt"},
            {"op":"delete","from":"b.txt","to":""}
        ]})";
        Plan plan;
        QString error;
        QVERIFY(Plans::parse(json, root, &plan, &error));
        QCOMPARE(plan.actions.size(), 2);
        QCOMPARE(plan.actions[0].op, QString("mkdir"));
        QCOMPARE(plan.actions[1].to, root + "/Docs/a.txt");
        QCOMPARE(plan.skipped.size(), 5); // moved-away source, overwrite, two escapes, unknown op
    }

    void planRejectsSymlinkEscape() {
        QTemporaryDir dir, outside;
        touch(dir.path() + "/a.txt");
        QVERIFY(QFile::link(outside.path(), dir.path() + "/out"));
        Plan plan;
        QVERIFY(Plans::parse(R"({"explanation":"","actions":[{"op":"move","from":"a.txt","to":"out/a.txt"}]})",
                             dir.path(), &plan, nullptr));
        QVERIFY(plan.actions.isEmpty());
        QCOMPARE(plan.skipped.size(), 1);
    }

    void unreadableAnswerFails() {
        Plan plan;
        QString error;
        QVERIFY(!Plans::parse("nope", "/tmp", &plan, &error));
        QVERIFY(!error.isEmpty());
    }

    void autoSortGroupsByType() {
        QTemporaryDir dir;
        const auto root = dir.path();
        touch(root + "/photo.jpg");
        touch(root + "/notes.md");
        touch(root + "/film.mkv.part");
        touch(root + "/mystery.xyz");
        touch(root + "/Images/photo.jpg"); // forces a numbered name
        QDir(root).mkdir("Projet");
        const auto plan = Plans::autoSort(root);
        QStringList moves;
        for (const auto &a : plan.actions)
            if (a.op == "move")
                moves << Plans::relative(root, a.to);
        moves.sort();
        QCOMPARE(moves, (QStringList{"Images/photo (2).jpg", "Textes/notes.md"}));
    }

    void applyAndUndo() {
        QTemporaryDir dir;
        const auto root = dir.path();
        touch(root + "/a.txt", "hello");
        const QVector<PlanAction> actions{{"move", root + "/a.txt", root + "/x/y/a.txt"}};
        QVector<PlanAction> applied;
        QString error;
        QVERIFY(Plans::apply(actions, &applied, &error));
        QVERIFY(QFile::exists(root + "/x/y/a.txt"));
        QCOMPARE(applied.size(), 3); // two folders created, one move

        for (const auto &a : Plans::inverse(applied)) {
            if (a.op == "move")
                QVERIFY(QDir().rename(a.from, a.to));
            else
                QVERIFY(QDir().rmdir(a.to));
        }
        QVERIFY(QFile::exists(root + "/a.txt"));
        QVERIFY(!QFileInfo::exists(root + "/x"));
    }

    void failedApplyRollsBack() {
        QTemporaryDir dir;
        const auto root = dir.path();
        touch(root + "/a.txt");
        touch(root + "/b.txt");
        touch(root + "/dest/b.txt");
        const QVector<PlanAction> actions{{"move", root + "/a.txt", root + "/new/a.txt"},
                                          {"move", root + "/b.txt", root + "/dest/b.txt"}};
        QString error;
        QVERIFY(!Plans::apply(actions, nullptr, &error));
        QVERIFY(QFile::exists(root + "/a.txt"));
        QVERIFY(!QFileInfo::exists(root + "/new"));
        QVERIFY(!error.isEmpty());
    }

    // ------------------------------------------------------------ git
    void parsesPorcelain() {
        QString branch;
        QHash<QString, QString> statuses;
        static const char raw[] = "## main...origin/main [ahead 1]\0 M src/a.cpp\0?? notes/\0R  new.txt\0old.txt\0";
        const QByteArray out(raw, sizeof(raw) - 1);
        GitInfo::parsePorcelain(out, &branch, &statuses);
        QCOMPARE(branch, QString("main"));
        QCOMPARE(statuses.value("src/a.cpp"), QString("M"));
        QCOMPARE(statuses.value("notes"), QString("?"));
        QCOMPARE(statuses.value("new.txt"), QString("R"));
        QVERIFY(!statuses.contains("old.txt"));
    }

    void remoteWebUrls() {
        QCOMPARE(GitInfo::webUrlFromRemote("git@github.com:owner/repo.git"), QString("https://github.com/owner/repo"));
        QCOMPARE(GitInfo::webUrlFromRemote("https://github.com/owner/repo"), QString("https://github.com/owner/repo"));
        QCOMPARE(GitInfo::webUrlFromRemote("https://token@github.com/o/r.git"), QString("https://github.com/o/r"));
        QCOMPARE(GitInfo::webUrlFromRemote("/srv/git/repo.git"), QString());
    }

    // ------------------------------------------------------------ GitHub
    void parsesRepoList() {
        const auto repos = GitHubRepos::parse(R"([
            {"name":"old","nameWithOwner":"me/old","updatedAt":"2025-01-01T00:00:00Z","primaryLanguage":null},
            {"name":"new","nameWithOwner":"me/new","description":"d","isPrivate":true,"stargazerCount":3,
             "updatedAt":"2026-11-01T00:00:00Z","primaryLanguage":{"name":"C++"}}
        ])");
        QCOMPARE(repos.size(), 2);
        QCOMPARE(repos[0].fullName, QString("me/new")); // most recently updated first
        QCOMPARE(repos[0].language, QString("C++"));
        QVERIFY(repos[0].isPrivate);
        QCOMPARE(repos[1].language, QString());
    }

    void matchesRemotesToClones() {
        QCOMPARE(GitHubRepos::repoFromRemote("git@github.com:Me/Repo.git"), QString("me/repo"));
        QCOMPARE(GitHubRepos::repoFromRemote("https://github.com/me/repo"), QString("me/repo"));
        QCOMPARE(GitHubRepos::repoFromRemote("https://gitlab.com/me/repo"), QString());

        QTemporaryDir dir;
        touch(dir.path() + "/top/.git/config", "[remote \"origin\"]\n\turl = https://github.com/me/top.git\n");
        touch(dir.path() + "/group/nested/.git/config", "[remote \"origin\"]\n\turl = git@github.com:me/nested.git\n");
        touch(dir.path() + "/group/a/b/.git/config", "[remote \"origin\"]\n\turl = git@github.com:me/deep.git\n");
        const auto clones = GitHubRepos::findClones({dir.path()});
        QCOMPARE(clones.value("me/top"), dir.path() + "/top");
        QCOMPARE(clones.value("me/nested"), dir.path() + "/group/nested");
        QVERIFY(!clones.contains("me/deep")); // deeper than two levels
    }

    void relativeTimes() {
        const auto now = QDateTime(QDate(2026, 11, 10), QTime(12, 0), QTimeZone::UTC);
        QCOMPARE(GitHubRepos::relativeTime(now.addSecs(-120), now), QString("à l'instant"));
        QCOMPARE(GitHubRepos::relativeTime(now.addDays(-4), now), QString("il y a 4 j"));
        QCOMPARE(GitHubRepos::relativeTime(now.addDays(-800), now), QString("il y a 2 ans"));
    }

    // ------------------------------------------------------------ index
    void cosineSimilarity() {
        QCOMPARE(Indexer::cosine({1, 0}, {1, 0}), 1.0f);
        QCOMPARE(Indexer::cosine({1, 0}, {0, 1}), 0.0f);
        QCOMPARE(Indexer::cosine({1, 0}, {1, 0, 0}), 0.0f);
    }

    void collectSkipsNoise() {
        QTemporaryDir dir;
        const auto root = dir.path();
        touch(root + "/a.md");
        touch(root + "/.git/config");
        touch(root + "/node_modules/x.js");
        touch(root + "/src/main.cpp");
        auto files = Indexer::collect(root, 100);
        for (auto &f : files)
            f = QDir(root).relativeFilePath(f);
        files.sort();
        QCOMPARE(files, (QStringList{"a.md", "src/main.cpp"}));
    }

    void indexRoundTrips() {
        QTemporaryDir cache;
        Settings settings(cache.path() + "/flair.conf");
        AiClient ai(&settings);
        Indexer index(&ai, cache.path());
        index.setEntries("/some/root", {{"/some/root/a", 42, {0.5f, 0.25f}}});
        QVERIFY(index.save());
        Indexer other(&ai, cache.path());
        QVERIFY(other.load("/some/root"));
        QCOMPARE(other.size(), 1);
        QVERIFY(other.covers("/some/root/deeper/file"));
        QVERIFY(!other.covers("/some/rootless"));
        QVERIFY(!other.load("/other/root"));
    }

    // ------------------------------------------------------------ text
    void readsTextNotBinary() {
        QTemporaryDir dir;
        touch(dir.path() + "/a.unknown", "plain words");
        touch(dir.path() + "/b.unknown", QByteArray("bin\0ary", 7));
        touch(dir.path() + "/c.png", "fake");
        QCOMPARE(TextExtract::readText(dir.path() + "/a.unknown", 100), QString("plain words"));
        QVERIFY(TextExtract::readText(dir.path() + "/b.unknown", 100).isEmpty());
        QVERIFY(TextExtract::readText(dir.path() + "/c.png", 100).isEmpty());
    }

    void outlineListsTree() {
        QTemporaryDir dir;
        touch(dir.path() + "/top.txt");
        touch(dir.path() + "/sub/inner.txt");
        const auto text = Backend::outline(dir.path(), 2, 100);
        QVERIFY(text.contains("sub/  [dossier"));
        QVERIFY(text.contains("sub/inner.txt"));
        QVERIFY(text.contains("top.txt"));
    }
};

QTEST_MAIN(FlairTests)
#include "flair_tests.moc"
