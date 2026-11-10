#include "textextract.h"

#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QLocale>
#include <QProcess>
#include <QSet>
#include <QStandardPaths>

namespace TextExtract {

static const QHash<QString, QString> &extensions() {
    static const QHash<QString, QString> map = [] {
        QHash<QString, QString> m;
        auto add = [&m](const QString &category, const QStringList &list) {
            for (const auto &e : list)
                m.insert(e, category);
        };
        add("image", {"png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "heic", "avif", "tif", "tiff", "ico", "raw",
                      "cr2", "nef", "psd", "xcf", "kra"});
        add("video", {"mp4", "mkv", "webm", "mov", "avi", "m4v", "flv", "wmv", "mpg", "mpeg"});
        add("audio", {"mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"});
        add("document", {"pdf", "doc", "docx", "odt", "rtf", "epub", "djvu"});
        add("tableur", {"xls", "xlsx", "ods", "csv", "tsv"});
        add("presentation", {"ppt", "pptx", "odp", "key"});
        add("archive", {"zip", "tar", "gz", "tgz", "xz", "bz2", "zst", "7z", "rar", "iso"});
        add("installeur", {"appimage", "deb", "rpm", "exe", "msi", "dmg", "apk", "flatpakref", "jar"});
        add("code", {"c", "cc", "cpp", "h", "hpp", "rs", "go", "py", "js", "mjs", "ts", "tsx", "jsx", "java", "kt",
                     "rb", "php", "cs", "swift", "lua", "sh", "bash", "zsh", "fish", "qml", "pro", "cmake", "dart",
                     "zig", "nim", "hs", "ml", "ex", "exs", "sql", "html", "css", "scss", "vue", "svelte", "json",
                     "yaml", "yml", "toml", "ini", "conf", "xml", "gradle", "nix", "el", "vim", "pkgbuild"});
        add("texte", {"txt", "md", "markdown", "rst", "org", "log", "tex", "nfo", "srt", "vtt"});
        return m;
    }();
    return map;
}

QString category(const QFileInfo &info) {
    if (info.isDir())
        return "dossier";
    const auto name = info.fileName().toLower();
    if (name == "pkgbuild" || name == "makefile" || name == "dockerfile")
        return "code";
    return extensions().value(info.suffix().toLower(), "autre");
}

QString sortFolder(const QString &category) {
    static const QHash<QString, QString> folders{
        {"image", "Images"},           {"video", "Vidéos"},     {"audio", "Musique"},
        {"document", "Documents"},     {"tableur", "Documents"}, {"presentation", "Documents"},
        {"archive", "Archives"},       {"installeur", "Installeurs"}, {"code", "Code"},
        {"texte", "Textes"}};
    return folders.value(category);
}

bool isTextual(const QString &path) {
    const QFileInfo info(path);
    const auto c = category(info);
    if (c == "code" || c == "texte")
        return true;
    if (c != "autre")
        return false;
    // Unknown extension: call it text if the start has no NUL bytes.
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return false;
    const auto head = file.read(4096);
    return !head.isEmpty() && !head.contains('\0');
}

QString readText(const QString &path, int maxChars) {
    const QFileInfo info(path);
    if (!info.isFile() || !info.isReadable())
        return {};
    if (info.suffix().compare("pdf", Qt::CaseInsensitive) == 0) {
        if (QStandardPaths::findExecutable("pdftotext").isEmpty())
            return {};
        QProcess process;
        process.start("pdftotext", {"-l", "8", "-enc", "UTF-8", path, "-"});
        if (!process.waitForFinished(15000)) {
            process.kill();
            return {};
        }
        return QString::fromUtf8(process.readAllStandardOutput()).left(maxChars);
    }
    if (!isTextual(path))
        return {};
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    // UTF-8 can take up to 4 bytes per character.
    return QString::fromUtf8(file.read(qint64(maxChars) * 4)).left(maxChars);
}

QString humanSize(qint64 bytes) {
    return QLocale(QLocale::French).formattedDataSize(bytes, 1, QLocale::DataSizeTraditionalFormat);
}

}
