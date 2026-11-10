#pragma once

#include <QString>

class QFileInfo;

// What a file is and what text can be read out of it, for the model to look at.
namespace TextExtract {

// One of: dossier, image, video, audio, document, tableur, presentation,
// archive, code, installeur, texte, autre.
QString category(const QFileInfo &info);
// French folder name auto-sort files a category into, or empty to leave it alone.
QString sortFolder(const QString &category);
bool isTextual(const QString &path);
// Up to maxChars of readable text: plain text and code as is, PDFs through
// pdftotext. Empty when there's nothing a model could read.
QString readText(const QString &path, int maxChars);
QString humanSize(qint64 bytes);

}
