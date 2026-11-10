#pragma once

#include <QJsonObject>
#include <QString>
#include <QStringList>
#include <QVector>

// A list of file moves and folder creations that the user reviews before any
// of it touches the disk. Plans never delete anything and never reach outside
// the folder they were made for.
struct PlanAction {
    QString op;   // "mkdir" or "move" (a rename is a move within one folder)
    QString from; // absolute; empty for mkdir
    QString to;   // absolute
};

struct Plan {
    QString root;
    QString explanation;
    QVector<PlanAction> actions;
    QStringList skipped; // why some proposed actions were dropped
};

namespace Plans {

// The JSON shape models are asked to answer with.
QJsonObject schema();

// Reads a model's JSON answer, resolves its relative paths against root, and
// keeps only actions that are safe to run in order. Returns false only when
// the answer can't be read at all.
bool parse(const QString &json, const QString &root, Plan *plan, QString *error);

// Sorts the loose files in a folder into category folders, without a model.
Plan autoSort(const QString &directory);

// Runs the actions in order. On a failure, everything already done is undone
// and the error is returned. `applied` receives what actually ran, including
// parent folders created along the way, for undo.
bool apply(const QVector<PlanAction> &actions, QVector<PlanAction> *applied, QString *error);
// The actions that put things back, in the order they must run.
QVector<PlanAction> inverse(const QVector<PlanAction> &applied);

// Relative path for display.
QString relative(const QString &root, const QString &path);

}
