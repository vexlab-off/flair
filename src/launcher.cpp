#include "launcher.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>

namespace LauncherIcons {

static const QColor kInk("#1b120b");
static const QColor kCream("#fff3e8");
static const QColor kDarkTile("#16110d");
static const QColor kLightTile("#fbf6ef");

static QColor mix(const QColor &a, const QColor &b, double t) {
    return QColor::fromRgbF(float(a.redF() + (b.redF() - a.redF()) * t), float(a.greenF() + (b.greenF() - a.greenF()) * t),
                            float(a.blueF() + (b.blueF() - a.blueF()) * t));
}

Colors flairColors(const QColor &accent, const QString &style) {
    if (style == "sombre")
        return {kDarkTile, accent.darker(190), accent, kCream};
    if (style == "clair")
        return {kLightTile, mix(accent, Qt::white, 0.55), accent, accent.darker(150)};
    return {accent, accent.darker(150), kInk, kCream};
}

Colors codeColors(const QColor &accent, const QString &style) {
    if (style == "sombre")
        return {kDarkTile, {}, accent, kCream};
    if (style == "clair")
        return {kLightTile, {}, kInk, accent};
    return {accent, {}, kInk, kCream};
}

QString flairSvg(const QColor &accent, const QString &style) {
    const auto c = flairColors(accent, style);
    return QString(R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <rect width="256" height="256" rx="60" fill="%1"/>
  <path d="M44 98a14 14 0 0 1 14-14h40l18 20h82a14 14 0 0 1 14 14v86a14 14 0 0 1-14 14H58a14 14 0 0 1-14-14z" fill="%2"/>
  <path d="M148 34C152 70 166 84 202 88C166 92 152 106 148 142C144 106 130 92 94 88C130 84 144 70 148 34zM82 46C83.6 58 88.5 62.9 100.5 64.5C88.5 66.1 83.6 71 82 83C80.4 71 75.5 66.1 63.5 64.5C75.5 62.9 80.4 58 82 46z" fill="%4"/>
  <path d="M40 132h176c4 0 7 3.4 6.4 7.4l-10.6 63.6a16 16 0 0 1-15.8 13.4H66a16 16 0 0 1-15.8-13.4L33.6 139.4c-.6-4 2.4-7.4 6.4-7.4z" fill="%3"/>
</svg>
)")
        .arg(c.tile.name(), c.back.name(), c.front.name(), c.spark.name());
}

QString flaircodeSvg(const QColor &accent, const QString &style) {
    const auto c = codeColors(accent, style);
    return QString(R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <rect width="256" height="256" rx="60" fill="%1"/>
  <path d="M92 72L44 128l48 56M164 72l48 56-48 56" fill="none" stroke="%2" stroke-width="26" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M128 76C131.6 108 143 119.4 175 123C143 126.6 131.6 138 128 170C124.4 138 113 126.6 81 123C113 119.4 124.4 108 128 76z" fill="%3"/>
</svg>
)")
        .arg(c.tile.name(), c.front.name(), c.spark.name());
}

static bool write(const QString &path, const QByteArray &bytes) {
    QDir().mkpath(QFileInfo(path).absolutePath());
    QSaveFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(bytes) >= 0 && file.commit();
}

void apply(const QColor &accent, const QString &style, bool follow, const QString &home,
           const QString &systemApplications) {
    const auto iconDir = home + "/.local/share/flair/icons";
    const auto userApplications = home + "/.local/share/applications";
    for (const auto &app : {QString("flair"), QString("flaircode")}) {
        const auto systemEntry = systemApplications + "/" + app + ".desktop";
        const auto userEntry = userApplications + "/" + app + ".desktop";
        // Only override entries flair itself wrote, never one the user made.
        QFile existing(userEntry);
        const bool ours = !existing.exists() ||
                          (existing.open(QIODevice::ReadOnly) && existing.readAll().contains("X-Flair-Generated=true"));
        existing.close();
        if (!ours)
            continue;
        if (!follow || !QFileInfo::exists(systemEntry)) {
            if (QFileInfo::exists(userEntry))
                QFile::remove(userEntry);
            continue;
        }
        // A new file name per colour and style: launchers cache icons by path.
        const auto svgPath = QString("%1/%2-%3-%4.svg").arg(iconDir, app, style, accent.name().mid(1));
        const auto svg = app == "flair" ? flairSvg(accent, style) : flaircodeSvg(accent, style);
        if (!write(svgPath, svg.toUtf8()))
            continue;
        for (const auto &old : QDir(iconDir).entryInfoList({app + "-*.svg"}, QDir::Files))
            if (old.absoluteFilePath() != svgPath)
                QFile::remove(old.absoluteFilePath());
        QFile source(systemEntry);
        if (!source.open(QIODevice::ReadOnly))
            continue;
        auto entry = QString::fromUtf8(source.readAll());
        static const QRegularExpression iconLine("^Icon=.*$", QRegularExpression::MultilineOption);
        entry.replace(iconLine, "Icon=" + svgPath);
        if (!entry.endsWith('\n'))
            entry += '\n';
        entry += "X-Flair-Generated=true\n";
        write(userEntry, entry.toUtf8());
    }
}

}
