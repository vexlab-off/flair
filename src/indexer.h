#pragma once

#include <QHash>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVector>
#include <functional>

class AiClient;

// A semantic index of one folder tree: each file's path and opening text,
// embedded by the local model and cached in ~/.cache/flair so only new or
// changed files are embedded again.
class Indexer : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString root READ root NOTIFY changed)
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(int done READ done NOTIFY progress)
    Q_PROPERTY(int total READ total NOTIFY progress)
    Q_PROPERTY(int size READ size NOTIFY changed)

public:
    struct Entry {
        QString path;
        qint64 modified = 0;
        QVector<float> vector;
    };

    Indexer(AiClient *ai, const QString &cacheDirectory = {}, QObject *parent = nullptr);

    QString root() const { return m_root; }
    bool running() const { return m_running; }
    int done() const { return m_done; }
    int total() const { return m_total; }
    int size() const { return int(m_entries.size()); }
    bool covers(const QString &path) const;

    // Loads the cached index for root, if one exists.
    void open(const QString &root);
    void build(const QString &root);
    void cancel();
    // Up to `count` hits as {path, score}, best first.
    void search(const QString &query, int count, std::function<void(const QVariantList &)> done,
                std::function<void(const QString &)> fail);

    // The files worth indexing under root (skips hidden, VCS, and build trees).
    static QStringList collect(const QString &root, int limit);
    static float cosine(const QVector<float> &a, const QVector<float> &b);
    static QString document(const QString &root, const QString &path);
    QString cacheFile(const QString &root) const;
    bool save() const;
    bool load(const QString &root);
    void setEntries(const QString &root, const QVector<Entry> &entries);

signals:
    void changed();
    void progress();
    void failed(const QString &message);
    void finished();

private:
    void embedNext();

    AiClient *m_ai;
    QString m_cacheDirectory;
    QString m_root;
    QVector<Entry> m_entries;
    bool m_running = false;
    int m_done = 0;
    int m_total = 0;
    int m_generation = 0;
    QStringList m_pending;
    QHash<QString, Entry> m_previous;
};
