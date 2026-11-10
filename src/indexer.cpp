#include "indexer.h"

#include "ai.h"
#include "textextract.h"

#include <QCryptographicHash>
#include <QDataStream>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QSaveFile>
#include <QSet>
#include <QVariantMap>
#include <algorithm>
#include <cmath>

static const int kBatch = 16;
static const int kMaxFiles = 5000;
static const quint32 kMagic = 0x464c4149; // "FLAI"
static const quint32 kVersion = 1;

Indexer::Indexer(AiClient *ai, const QString &cacheDirectory, QObject *parent)
    : QObject(parent), m_ai(ai),
      m_cacheDirectory(cacheDirectory.isEmpty() ? QDir::homePath() + "/.cache/flair" : cacheDirectory) {}

QString Indexer::cacheFile(const QString &root) const {
    const auto hash = QCryptographicHash::hash(root.toUtf8(), QCryptographicHash::Sha1).toHex().left(16);
    return m_cacheDirectory + "/index-" + QString::fromLatin1(hash) + ".bin";
}

bool Indexer::covers(const QString &path) const {
    return !m_root.isEmpty() && !m_entries.isEmpty() && (path == m_root || path.startsWith(m_root + "/"));
}

QStringList Indexer::collect(const QString &root, int limit) {
    static const QSet<QString> skip{"node_modules", "build", "dist", "target", "__pycache__", "venv", ".venv",
                                    "vendor", "Library", "pkg"};
    QStringList files;
    QStringList queue{root};
    // Breadth first, so the shallow files that matter most fit under the limit.
    while (!queue.isEmpty() && files.size() < limit) {
        const QDir dir(queue.takeFirst());
        const auto entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::NoSymLinks, QDir::Name);
        for (const auto &info : entries) {
            if (info.fileName().startsWith('.'))
                continue;
            if (info.isDir()) {
                if (!skip.contains(info.fileName()))
                    queue.append(info.absoluteFilePath());
            } else if (info.isFile() && files.size() < limit) {
                files.append(info.absoluteFilePath());
            }
        }
    }
    return files;
}

QString Indexer::document(const QString &root, const QString &path) {
    // The path carries a lot of meaning on its own ("factures/2026/mars.pdf"),
    // so it leads; the opening text follows when there is any.
    const auto rel = QDir(root).relativeFilePath(path);
    const auto text = TextExtract::readText(path, 1500).simplified();
    return text.isEmpty() ? rel : rel + "\n" + text;
}

float Indexer::cosine(const QVector<float> &a, const QVector<float> &b) {
    if (a.size() != b.size() || a.isEmpty())
        return 0;
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.size(); ++i) {
        dot += double(a[i]) * b[i];
        na += double(a[i]) * a[i];
        nb += double(b[i]) * b[i];
    }
    return na > 0 && nb > 0 ? float(dot / (std::sqrt(na) * std::sqrt(nb))) : 0;
}

void Indexer::setEntries(const QString &root, const QVector<Entry> &entries) {
    m_root = root;
    m_entries = entries;
    emit changed();
}

bool Indexer::save() const {
    QDir().mkpath(m_cacheDirectory);
    QSaveFile file(cacheFile(m_root));
    if (!file.open(QIODevice::WriteOnly))
        return false;
    QDataStream out(&file);
    out << kMagic << kVersion << m_root << quint32(m_entries.size());
    for (const auto &e : m_entries)
        out << e.path << e.modified << e.vector;
    return file.commit();
}

bool Indexer::load(const QString &root) {
    QFile file(cacheFile(root));
    if (!file.open(QIODevice::ReadOnly))
        return false;
    QDataStream in(&file);
    quint32 magic, version, count;
    QString storedRoot;
    in >> magic >> version >> storedRoot >> count;
    if (magic != kMagic || version != kVersion || storedRoot != root || in.status() != QDataStream::Ok)
        return false;
    QVector<Entry> entries;
    entries.reserve(count);
    for (quint32 i = 0; i < count && in.status() == QDataStream::Ok; ++i) {
        Entry e;
        in >> e.path >> e.modified >> e.vector;
        entries.append(e);
    }
    if (in.status() != QDataStream::Ok)
        return false;
    setEntries(root, entries);
    return true;
}

void Indexer::open(const QString &root) {
    if (m_running || root == m_root)
        return;
    // Look for an index of this folder or of any folder above it.
    for (QString dir = root; !dir.isEmpty(); dir = QFileInfo(dir).absolutePath()) {
        if (load(dir))
            return;
        if (dir == "/" || dir == QDir::homePath())
            break;
    }
}

void Indexer::build(const QString &root) {
    if (m_running)
        return;
    load(root);
    m_previous.clear();
    if (m_root == root)
        for (const auto &e : m_entries)
            m_previous.insert(e.path, e);

    m_root = root;
    m_entries.clear();
    const auto files = collect(root, kMaxFiles);
    m_pending.clear();
    for (const auto &path : files) {
        const auto modified = QFileInfo(path).lastModified().toMSecsSinceEpoch();
        const auto previous = m_previous.constFind(path);
        if (previous != m_previous.cend() && previous->modified == modified && !previous->vector.isEmpty())
            m_entries.append(*previous);
        else
            m_pending.append(path);
    }
    m_total = int(files.size());
    m_done = int(m_entries.size());
    m_running = true;
    ++m_generation;
    emit changed();
    emit progress();
    embedNext();
}

void Indexer::cancel() {
    if (!m_running)
        return;
    ++m_generation;
    m_running = false;
    save(); // Keep what was embedded so far; the next build resumes from it.
    emit changed();
}

void Indexer::embedNext() {
    if (m_pending.isEmpty()) {
        m_running = false;
        save();
        emit changed();
        emit finished();
        return;
    }
    const auto batch = m_pending.mid(0, kBatch);
    QStringList texts;
    for (const auto &path : batch)
        texts.append(document(m_root, path));
    const int generation = m_generation;
    m_ai->embed(
        texts,
        [=](const QVector<QVector<float>> &vectors) {
            if (generation != m_generation)
                return;
            for (int i = 0; i < batch.size(); ++i)
                m_entries.append({batch[i], QFileInfo(batch[i]).lastModified().toMSecsSinceEpoch(), vectors[i]});
            m_pending = m_pending.mid(batch.size());
            m_done += int(batch.size());
            emit progress();
            // Save as we go, so a crash or quit loses at most one batch.
            if (m_done % (kBatch * 8) == 0)
                save();
            embedNext();
        },
        [=](const QString &message) {
            if (generation != m_generation)
                return;
            m_running = false;
            save();
            emit changed();
            emit failed(message);
        });
}

void Indexer::search(const QString &query, int count, std::function<void(const QVariantList &)> done,
                     std::function<void(const QString &)> fail) {
    if (m_entries.isEmpty()) {
        fail(tr("Aucun index pour ce dossier. Appuie sur I pour l'indexer d'abord."));
        return;
    }
    const auto entries = m_entries;
    const auto root = m_root;
    m_ai->embed(
        {query},
        [=](const QVector<QVector<float>> &vectors) {
            QVector<QPair<float, QString>> scored;
            scored.reserve(entries.size());
            for (const auto &e : entries)
                if (QFileInfo::exists(e.path))
                    scored.append({cosine(vectors.first(), e.vector), e.path});
            std::sort(scored.begin(), scored.end(), [](const auto &a, const auto &b) { return a.first > b.first; });
            QVariantList hits;
            for (int i = 0; i < scored.size() && i < count; ++i)
                hits.append(QVariantMap{{"path", scored[i].second},
                                        {"name", QFileInfo(scored[i].second).fileName()},
                                        {"relative", QDir(root).relativeFilePath(scored[i].second)},
                                        {"score", scored[i].first}});
            done(hits);
        },
        fail);
}
