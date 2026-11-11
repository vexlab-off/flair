#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantMap>

// The pictures (or the videos and songs) of one folder, in order, with the
// one being shown: what Flair Image and Flair Vidéo step through.
class MediaFolder : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString path READ path NOTIFY changed)
    Q_PROPERTY(QString name READ name NOTIFY changed)
    Q_PROPERTY(int index READ index NOTIFY changed)
    Q_PROPERTY(int count READ count NOTIFY changed)
    Q_PROPERTY(QStringList files READ files NOTIFY changed)
    Q_PROPERTY(QString kind READ kind CONSTANT)
    Q_PROPERTY(QString message READ message NOTIFY messageChanged)

public:
    // kind: "image" for pictures, "video" for videos and songs.
    explicit MediaFolder(const QString &kind, QObject *parent = nullptr);

    QString path() const { return m_index >= 0 && m_index < m_files.size() ? m_files[m_index] : QString(); }
    QString name() const;
    int index() const { return m_index; }
    int count() const { return int(m_files.size()); }
    QStringList files() const { return m_files; }
    QString kind() const { return m_kind; }
    QString message() const { return m_message; }

    // Opens a file (and its folder's siblings) or a folder (its first file).
    Q_INVOKABLE bool open(const QString &path);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void go(int index);
    // Moves the current file to the trash and shows the next one.
    Q_INVOKABLE bool trashCurrent();
    Q_INVOKABLE void copyPath();
    Q_INVOKABLE void revealInFlair();
    Q_INVOKABLE void openWithSystem();
    Q_INVOKABLE QVariantMap info() const;

    static bool matches(const QString &kind, const QString &path);
    static QStringList siblings(const QString &kind, const QString &directory);

signals:
    void changed();
    void messageChanged();

private:
    void setMessage(const QString &message);

    QString m_kind;
    QStringList m_files;
    int m_index = -1;
    QString m_message;
};
