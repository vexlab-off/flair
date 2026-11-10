#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QHash>
#include <QObject>
#include <QTimer>
#include <QVariantMap>

// Follows the whole Vex palette live, not just the accent, and derives the
// few surface tones the window needs from it.
class Theme : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accent READ accent NOTIFY changed)
    Q_PROPERTY(QString accentForeground READ accentForeground NOTIFY changed)
    // The colour that marks selection and focus: the accent, unless the accent
    // is close to grey, in which case the palette's most vivid colour.
    Q_PROPERTY(QColor highlight READ highlight NOTIFY changed)
    Q_PROPERTY(QColor highlightText READ highlightText NOTIFY changed)
    Q_PROPERTY(QColor background READ background NOTIFY changed)
    Q_PROPERTY(QColor sidebar READ sidebar NOTIFY changed)
    Q_PROPERTY(QColor surface READ surface NOTIFY changed)
    Q_PROPERTY(QColor raised READ raised NOTIFY changed)
    Q_PROPERTY(QColor line READ line NOTIFY changed)
    Q_PROPERTY(QColor text READ text NOTIFY changed)
    Q_PROPERTY(QColor textDim READ textDim NOTIFY changed)
    Q_PROPERTY(QColor textFaint READ textFaint NOTIFY changed)
    Q_PROPERTY(QColor danger READ danger NOTIFY changed)
    Q_PROPERTY(QColor success READ success NOTIFY changed)
    Q_PROPERTY(QColor warning READ warning NOTIFY changed)

public:
    explicit Theme(const QString &currentDirectory = {}, QObject *parent = nullptr);

    QString accent() const { return m_accent; }
    QString accentForeground() const;
    QColor highlight() const;
    QColor highlightText() const;
    QColor background() const { return color("background", "#0e0e10"); }
    QColor sidebar() const { return mix(background(), QColor(Qt::black), 0.25); }
    QColor surface() const { return mix(background(), text(), 0.035); }
    QColor raised() const { return mix(background(), text(), 0.07); }
    QColor line() const { return mix(background(), text(), 0.10); }
    QColor text() const { return color("foreground", "#ececf0"); }
    QColor textDim() const { return mix(text(), background(), 0.38); }
    QColor textFaint() const { return mix(text(), background(), 0.58); }
    QColor danger() const { return color("bright_red", color("red", "#ff6b6b")); }
    QColor success() const { return color("bright_green", color("green", "#7fcf8a")); }
    QColor warning() const { return color("bright_yellow", color("yellow", "#e0b050")); }

    // Colour for a file category (dossier, image, code…), drawn from the palette.
    Q_INVOKABLE QColor kindColor(const QString &kind) const;
    // A programming language's dot colour for repository rows.
    Q_INVOKABLE QColor languageColor(const QString &language) const;
    Q_INVOKABLE QColor alpha(const QColor &color, double opacity) const;

    static QString readAccent(const QString &path);
    static QHash<QString, QColor> readColors(const QString &path);
    static QColor mix(const QColor &a, const QColor &b, double amount);
    static QColor mostVivid(const QHash<QString, QColor> &colors, const QColor &fallback);

signals:
    void changed();

private:
    QColor color(const QString &key, const QColor &fallback) const { return m_colors.value(key, fallback); }
    void reload();

    QString m_directory;
    QString m_accent = "#FFD60A";
    QHash<QString, QColor> m_colors;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};
