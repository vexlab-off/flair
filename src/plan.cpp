#include "plan.h"

#include "textextract.h"

#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSet>

namespace Plans {

QJsonObject schema() {
    const QJsonObject action{
        {"type", "object"},
        {"properties",
         QJsonObject{{"op", QJsonObject{{"type", "string"}, {"enum", QJsonArray{"mkdir", "move"}}}},
                     {"from", QJsonObject{{"type", "string"}}},
                     {"to", QJsonObject{{"type", "string"}}}}},
        {"required", QJsonArray{"op", "from", "to"}},
        {"additionalProperties", false}};
    return QJsonObject{{"type", "object"},
                       {"properties", QJsonObject{{"explanation", QJsonObject{{"type", "string"}}},
                                                  {"actions", QJsonObject{{"type", "array"}, {"items", action}}}}},
                       {"required", QJsonArray{"explanation", "actions"}},
                       {"additionalProperties", false}};
}

QString relative(const QString &root, const QString &path) {
    return QDir(root).relativeFilePath(path);
}

// The real location of the nearest existing ancestor, so a symlink can't carry
// a destination outside the root.
static QString canonicalAncestor(QString path) {
    while (!QFileInfo::exists(path) && path != "/")
        path = QFileInfo(path).absolutePath();
    const auto canonical = QFileInfo(path).canonicalFilePath();
    return canonical.isEmpty() ? path : canonical;
}

static bool inside(const QString &root, const QString &path) {
    const auto canonicalRoot = QFileInfo(root).canonicalFilePath();
    const auto ancestor = canonicalAncestor(path);
    return ancestor == canonicalRoot || ancestor.startsWith(canonicalRoot + "/");
}

// Resolves a path the model wrote relative to root; empty when it's absolute
// or climbs out.
static QString resolve(const QString &root, QString rel) {
    rel = rel.trimmed();
    while (rel.startsWith("./"))
        rel.remove(0, 2);
    if (rel.isEmpty() || rel.startsWith('/') || rel.startsWith('~'))
        return {};
    const auto path = QDir::cleanPath(root + "/" + rel);
    if (!path.startsWith(root + "/"))
        return {};
    return path;
}

bool parse(const QString &json, const QString &rootIn, Plan *plan, QString *error) {
    QJsonParseError parseError;
    const auto doc = QJsonDocument::fromJson(json.toUtf8(), &parseError);
    if (!doc.isObject()) {
        if (error)
            *error = QObject::tr("La réponse du modèle n'est pas du JSON lisible (%1).").arg(parseError.errorString());
        return false;
    }
    const auto root = QDir::cleanPath(rootIn);
    const auto object = doc.object();
    plan->root = root;
    plan->explanation = object.value("explanation").toString();
    plan->actions.clear();
    plan->skipped.clear();

    // Simulate the plan so each action is checked against the state the
    // earlier ones leave behind.
    QSet<QString> gone, made;
    auto exists = [&](const QString &p) { return made.contains(p) || (!gone.contains(p) && QFileInfo::exists(p)); };

    for (const auto &value : object.value("actions").toArray()) {
        const auto a = value.toObject();
        const auto op = a.value("op").toString();
        const auto fromRel = a.value("from").toString();
        const auto toRel = a.value("to").toString();
        const auto to = resolve(root, toRel);
        if (to.isEmpty() || !inside(root, to)) {
            plan->skipped << QObject::tr("« %1 » sort du dossier : ignoré").arg(toRel);
            continue;
        }
        if (op == "mkdir") {
            if (exists(to))
                continue;
            made.insert(to);
            gone.remove(to);
            plan->actions.append({"mkdir", {}, to});
        } else if (op == "move") {
            const auto from = resolve(root, fromRel);
            if (from.isEmpty() || !inside(root, from)) {
                plan->skipped << QObject::tr("« %1 » sort du dossier : ignoré").arg(fromRel);
            } else if (!exists(from)) {
                plan->skipped << QObject::tr("« %1 » n'existe pas : ignoré").arg(fromRel);
            } else if (from == to) {
                continue;
            } else if (exists(to)) {
                plan->skipped << QObject::tr("« %1 » existe déjà, rien n'est écrasé : ignoré").arg(toRel);
            } else if (to.startsWith(from + "/")) {
                plan->skipped << QObject::tr("« %1 » ne peut pas aller dans lui-même : ignoré").arg(fromRel);
            } else {
                gone.insert(from);
                made.remove(from);
                made.insert(to);
                plan->actions.append({"move", from, to});
            }
        } else {
            plan->skipped << QObject::tr("Action inconnue « %1 » : ignorée").arg(op);
        }
    }
    return true;
}

Plan autoSort(const QString &directoryIn) {
    const auto directory = QDir::cleanPath(directoryIn);
    Plan plan;
    plan.root = directory;
    QHash<QString, int> counts;
    QSet<QString> taken;
    const auto entries = QDir(directory).entryInfoList(QDir::Files | QDir::NoDotAndDotDot, QDir::Name | QDir::IgnoreCase);
    for (const auto &info : entries) {
        const auto suffix = info.suffix().toLower();
        // Downloads still in progress must stay where the browser expects them.
        if (suffix == "part" || suffix == "crdownload" || suffix == "download")
            continue;
        const auto folder = TextExtract::sortFolder(TextExtract::category(info));
        if (folder.isEmpty())
            continue;
        const auto folderPath = directory + "/" + folder;
        if (QFileInfo(folderPath).exists() && !QFileInfo(folderPath).isDir())
            continue;
        // Never overwrite: number the name if the destination is taken.
        QString target = folderPath + "/" + info.fileName();
        for (int n = 2; QFileInfo::exists(target) || taken.contains(target); ++n) {
            const auto base = info.completeBaseName();
            target = folderPath + "/" + base + QString(" (%1)").arg(n) + (suffix.isEmpty() ? "" : "." + info.suffix());
        }
        if (!QFileInfo::exists(folderPath) && !taken.contains(folderPath)) {
            plan.actions.append({"mkdir", {}, folderPath});
            taken.insert(folderPath);
        }
        taken.insert(target);
        plan.actions.append({"move", info.absoluteFilePath(), target});
        counts[folder]++;
    }
    QStringList parts;
    for (auto it = counts.cbegin(); it != counts.cend(); ++it)
        parts << QObject::tr("%1 → %2").arg(it.value()).arg(it.key());
    parts.sort();
    plan.explanation = parts.isEmpty()
                           ? QObject::tr("Rien à ranger ici : aucun fichier libre d'un type connu.")
                           : QObject::tr("Rangement par type : %1. Les dossiers et les fichiers inconnus ne bougent pas.")
                                 .arg(parts.join(", "));
    return plan;
}

bool apply(const QVector<PlanAction> &actions, QVector<PlanAction> *applied, QString *error) {
    QVector<PlanAction> done;
    auto rollback = [&] {
        for (const auto &undo : inverse(done)) {
            if (undo.op == "move")
                QDir().rename(undo.from, undo.to);
            else if (undo.op == "rmdir")
                QDir().rmdir(undo.to);
        }
    };
    auto makeDir = [&](const QString &path) -> bool {
        // Create each missing level separately so undo can remove exactly those.
        QStringList missing;
        for (QString p = path; !QFileInfo::exists(p) && p != "/"; p = QFileInfo(p).absolutePath())
            missing.prepend(p);
        for (const auto &p : missing) {
            if (!QDir().mkdir(p))
                return false;
            done.append({"mkdir", {}, p});
        }
        return true;
    };

    for (const auto &action : actions) {
        bool ok = true;
        QString why;
        if (action.op == "mkdir") {
            ok = makeDir(action.to);
            why = QObject::tr("impossible de créer « %1 »").arg(action.to);
        } else if (action.op == "move") {
            if (!QFileInfo::exists(action.from)) {
                ok = false;
                why = QObject::tr("« %1 » a disparu").arg(action.from);
            } else if (QFileInfo::exists(action.to)) {
                ok = false;
                why = QObject::tr("« %1 » existe déjà").arg(action.to);
            } else if (!makeDir(QFileInfo(action.to).absolutePath())) {
                ok = false;
                why = QObject::tr("impossible de créer le dossier de « %1 »").arg(action.to);
            } else if (!QDir().rename(action.from, action.to)) {
                ok = false;
                why = QObject::tr("impossible de déplacer « %1 » vers « %2 »").arg(action.from, action.to);
            } else {
                done.append(action);
            }
        }
        if (!ok) {
            rollback();
            if (error)
                *error = QObject::tr("Plan annulé, rien n'a changé : %1.").arg(why);
            return false;
        }
    }
    if (applied)
        *applied = done;
    return true;
}

QVector<PlanAction> inverse(const QVector<PlanAction> &applied) {
    QVector<PlanAction> out;
    for (auto it = applied.crbegin(); it != applied.crend(); ++it) {
        if (it->op == "move")
            out.append({"move", it->to, it->from});
        else if (it->op == "mkdir")
            out.append({"rmdir", {}, it->to});
    }
    return out;
}

}
