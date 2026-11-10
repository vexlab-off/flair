import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The right-click menu: what can be done with this file or folder, with the
// Git and GitHub setup of a folder in its own group.
Popup {
    id: menu
    property string path
    property bool isDir: false
    // True for a click on the empty part of the list: actions on the current folder.
    property bool onEmpty: false
    property var git: ({})
    property var items: []
    signal action(string key, string path)

    padding: 6
    width: 286
    background: Rectangle {
        color: theme.surface
        radius: 11
        border.color: theme.line
        layer.enabled: true
    }

    function openFor(targetPath, targetIsDir, isBackground, x, y) {
        path = targetPath
        isDir = targetIsDir
        onEmpty = isBackground
        git = isDir ? backend.gitState(path) : ({})
        items = build()
        // Keep the menu on screen.
        const parentItem = menu.parent
        menu.x = Math.min(x, parentItem.width - width - 8)
        menu.y = Math.min(y, Math.max(8, parentItem.height - estimatedHeight() - 8))
        open()
    }

    function estimatedHeight() {
        let h = 12
        for (const item of items) h += item.separator ? 9 : (item.header ? 26 : 32)
        return h
    }

    function build() {
        const list = []
        const isHtml = /\.x?html?$/i.test(path)
        if (!onEmpty) {
            list.push({ key: "open", icon: isDir ? "folder" : (isHtml ? "globe" : "external"), label: isDir ? "Ouvrir" : (isHtml ? "Afficher l'aperçu" : "Ouvrir"), hint: "Entrée" })
            if (!isDir) list.push({ key: "summarize", icon: "sparkle", label: "Résumer avec l'IA", hint: "Espace" })
        } else {
            list.push({ key: "newFolder", icon: "folder", label: "Nouveau dossier…", hint: "Ctrl+Maj+N" })
        }
        list.push({ key: "editor", icon: "code", label: "Ouvrir dans l'éditeur", hint: "E" })
        if (!isDir && !onEmpty) list.push({ key: "system", icon: "external", label: "Ouvrir avec l'application par défaut" })
        if (isDir) list.push({ key: "terminal", icon: "terminal", label: "Ouvrir un terminal ici" })
        list.push({ separator: true })
        list.push({ key: "copyPath", icon: "copy", label: "Copier le chemin" })
        if (!onEmpty) {
            list.push({ key: "rename", icon: "pencil", label: "Renommer…", hint: "F2" })
            list.push({ key: "trash", icon: "trash", label: "Mettre à la corbeille", hint: "Suppr", danger: true })
        }
        if (isDir) {
            list.push({ separator: true })
            list.push({ header: true, label: "Git et GitHub" })
            if (!git.isRepo) {
                list.push({ key: "gitInit", icon: "branch", label: "Initialiser un dépôt Git" })
                list.push({ key: "publish", icon: "github", label: "Publier sur GitHub…" })
            } else {
                if (git.changes > 0)
                    list.push({ key: "commit", icon: "check", label: (git.hasRemote ? "Commit et push…" : "Commit…") + "  (" + git.changes + ")" })
                if (git.hasRemote) {
                    if (git.webUrl) list.push({ key: "web", icon: "github", label: "Ouvrir sur GitHub" })
                } else {
                    list.push({ key: "publish", icon: "github", label: "Publier sur GitHub…" })
                }
            }
            list.push({ key: "repoFiles", icon: "document", label: "Fichiers du dépôt (.gitignore, README…)" })
        }
        list.push({ separator: true })
        list.push({ key: "properties", icon: "info", label: "Propriétés", hint: "Alt+Entrée" })
        return list
    }

    contentItem: Column {
        spacing: 0
        Repeater {
            model: menu.items
            delegate: Loader {
                required property var modelData
                width: 274
                sourceComponent: modelData.separator ? separator : (modelData.header ? header : entry)

                Component {
                    id: separator
                    Item { height: 9; Rectangle { anchors.centerIn: parent; width: parent.width - 12; height: 1; color: theme.line } }
                }
                Component {
                    id: header
                    Text {
                        height: 26
                        leftPadding: 10
                        verticalAlignment: Text.AlignBottom
                        bottomPadding: 4
                        text: modelData.label
                        color: theme.textFaint
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }
                Component {
                    id: entry
                    Rectangle {
                        height: 32
                        radius: 7
                        color: hover.containsMouse ? (modelData.danger ? theme.alpha(theme.danger, 0.12) : theme.alpha(theme.highlight, 0.12)) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Icon {
                                name: modelData.icon
                                size: 15
                                color: modelData.danger ? theme.danger : (hover.containsMouse ? theme.highlight : theme.textDim)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: modelData.danger && hover.containsMouse ? theme.danger : theme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: !!modelData.hint
                                text: modelData.hint || ""
                                color: theme.textFaint
                                font.pixelSize: 11
                            }
                        }
                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                const key = modelData.key, target = menu.path
                                menu.close()
                                menu.action(key, target)
                            }
                        }
                    }
                }
            }
        }
    }
}
