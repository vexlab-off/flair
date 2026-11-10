import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1280
    height: 800
    minimumWidth: 820
    minimumHeight: 520
    visible: true
    title: "flair — " + backend.currentPath
    color: "#0e0e10"

    Material.theme: Material.Dark
    Material.accent: theme.accent

    // "", "search", "command", "chat", "path", "clone"
    property string inputMode: ""
    property string selectedPath: ""
    readonly property bool browsing: inputMode === "" && !settingsDialog.visible && !help.visible

    function openInput(mode) {
        inputMode = mode
        input.text = mode === "path" ? backend.currentPath + "/" : ""
        input.forceActiveFocus()
        if (mode === "chat") backend.panel = "chat"
        if (mode === "command") backend.panel = "plan"
    }
    function closeInput() {
        inputMode = ""
        list.forceActiveFocus()
    }
    function submit() {
        const text = input.text
        switch (inputMode) {
        case "search": backend.search(text); closeInput(); if (backend.searchResults.length) side.results.forceActiveFocus(); return
        case "command": backend.command(text); closeInput(); return
        case "chat": backend.ask(text); input.text = ""; return  // stays open for the next question
        case "path": if (backend.navigate(text)) closeInput(); return
        case "clone": backend.clone(text); closeInput(); return
        }
    }
    function handleEscape() {
        if (help.visible) { help.visible = false; return }
        if (inputMode !== "") { closeInput(); return }
        if (backend.busy) { backend.cancel(); return }
        if (backend.panel === "plan" && backend.planItems.length) { backend.discardPlan(); return }
        backend.clearError()
        list.forceActiveFocus()
    }

    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; enabled: inputMode === ""; onActivated: help.visible = !help.visible }
    Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: Qt.quit() }
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; enabled: !settingsDialog.visible; onActivated: win.handleEscape() }
    Shortcut { sequence: "Space"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.summarize(win.selectedPath || backend.currentPath) }
    Shortcut { sequence: "/"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: win.openInput("search") }
    Shortcut { sequence: ":"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: win.openInput("command") }
    Shortcut { sequence: "Ctrl+K"; context: Qt.ApplicationShortcut; onActivated: win.openInput("command") }
    Shortcut { sequence: "C"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: win.openInput("chat") }
    Shortcut { sequence: "S"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.autoSort() }
    Shortcut { sequence: "Shift+S"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.smartSort() }
    Shortcut { sequence: "I"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.buildIndex() }
    Shortcut { sequence: "D"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.explainChanges() }
    Shortcut { sequence: "G"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.openOnWeb() }
    Shortcut { sequence: "Ctrl+G"; context: Qt.ApplicationShortcut; onActivated: win.openInput("clone") }
    Shortcut { sequence: "Ctrl+L"; context: Qt.ApplicationShortcut; onActivated: win.openInput("path") }
    Shortcut { sequence: "~"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.navigate("~") }
    Shortcut { sequence: "."; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: files.showHidden = !files.showHidden }
    Shortcut { sequence: "1"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.panel = "preview" }
    Shortcut { sequence: "2"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.panel = "search" }
    Shortcut { sequence: "3"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.panel = "chat" }
    Shortcut { sequence: "4"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.panel = "plan" }
    Shortcut { sequences: ["Ctrl+Return", "Ctrl+Enter"]; context: Qt.ApplicationShortcut; enabled: !settingsDialog.visible; onActivated: backend.applyPlan() }
    Shortcut { sequence: "Ctrl+Z"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.undo() }
    Shortcut { sequence: "Ctrl+Shift+Z"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.redo() }
    Shortcut { sequence: "Ctrl+,"; context: Qt.ApplicationShortcut; onActivated: settingsDialog.open() }

    Connections {
        target: backend
        function onSelectPath(path) {
            const row = files.rowOf(path)
            if (row >= 0) { list.currentIndex = row; list.positionViewAtIndex(row, ListView.Contain) }
            list.forceActiveFocus()
        }
    }
    Connections {
        target: files
        function onDirectoryChanged() { win.selectedPath = ""; list.currentIndex = 0 }
        // The folder changed on disk: keep the cursor on the same entry.
        function onCountChanged() {
            const row = files.rowOf(win.selectedPath)
            list.currentIndex = row >= 0 ? row : Math.min(Math.max(0, list.currentIndex), files.count - 1)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ------------------------------------------------------------ header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: backend.currentPath
                color: "#f2f2f5"
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideLeft
                MouseArea { anchors.fill: parent; onClicked: win.openInput("path") }
            }
            Chip {
                visible: git.isRepo
                text: "⎇ " + git.branch + (git.changedCount ? "  ·  " + git.changedCount + " modif." : "")
                accent: true
            }
            Chip {
                text: (backend.localOnline ? "● " : "○ ") + "local"
                dim: !backend.localOnline
            }
            Chip {
                text: (backend.claudeReady ? "● " : "○ ") + "Claude"
                dim: !backend.claudeReady
            }
            Chip {
                visible: indexer.size > 0 || indexer.running
                text: indexer.running ? "index " + indexer.done + "/" + indexer.total : "indexé"
            }
        }

        // ------------------------------------------------------------ body
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            ListView {
                id: list
                SplitView.fillWidth: true
                SplitView.minimumWidth: 360
                clip: true
                focus: true
                model: files
                highlightMoveDuration: 0
                keyNavigationEnabled: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}

                onCurrentIndexChanged: if (currentIndex >= 0) win.selectedPath = files.pathAt(currentIndex)

                delegate: FileRow {
                    width: ListView.view.width - 8
                    current: ListView.isCurrentItem
                    onClicked: { list.currentIndex = index; list.forceActiveFocus() }
                    onDoubleClicked: backend.activate(index)
                }

                Keys.onPressed: (event) => {
                    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) return
                    switch (event.key) {
                    case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Right: case Qt.Key_L:
                        backend.activate(currentIndex); event.accepted = true; break
                    case Qt.Key_Backspace: case Qt.Key_Left: case Qt.Key_H:
                        backend.goUp(); event.accepted = true; break
                    case Qt.Key_J: incrementCurrentIndex(); event.accepted = true; break
                    case Qt.Key_K: decrementCurrentIndex(); event.accepted = true; break
                    case Qt.Key_Home: currentIndex = 0; event.accepted = true; break
                    case Qt.Key_End: currentIndex = count - 1; event.accepted = true; break
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "Dossier vide"
                    color: "#5e5e68"
                }
            }

            SidePanel {
                id: side
                SplitView.preferredWidth: win.width * 0.42
                SplitView.minimumWidth: 320
                onRevealRequested: (path) => backend.reveal(path)
            }
        }

        // ------------------------------------------------------------ input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            visible: win.inputMode !== ""
            radius: 8
            color: "#18181c"
            border.color: theme.accent
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10
                Text {
                    text: ({ search: "Rechercher", command: "Commande", chat: "Question", path: "Aller à", clone: "Cloner" })[win.inputMode] || ""
                    color: theme.accent
                    font.bold: true
                    font.pixelSize: 13
                }
                TextField {
                    id: input
                    Layout.fillWidth: true
                    background: null
                    font.pixelSize: 14
                    placeholderText: ({
                        search: "ce que tu cherches, en mots à toi : « facture électricité 2025 »",
                        command: "« range les captures d'écran par mois », « renomme les photos par date »…",
                        chat: "pose une question sur ce dossier",
                        path: "chemin",
                        clone: "propriétaire/dépôt ou URL github.com"
                    })[win.inputMode] || ""
                    onAccepted: win.submit()
                }
            }
        }

        // ------------------------------------------------------------ status
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.fillWidth: true
                text: backend.error || backend.status || (files.count + " éléments" + (files.showHidden ? " (cachés visibles)" : ""))
                color: backend.error ? "#ff6b6b" : "#7a7a85"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            Text {
                text: (backend.canUndo ? "Ctrl+Z annuler  ·  " : "") + "? aide"
                color: "#5e5e68"
                font.pixelSize: 12
            }
        }
    }

    component Chip: Rectangle {
        property alias text: chipLabel.text
        property bool accent: false
        property bool dim: false
        height: 24
        width: chipLabel.implicitWidth + 18
        radius: 12
        color: accent ? Qt.rgba(1, 1, 1, 0.06) : "#18181c"
        border.color: accent ? theme.accent : "transparent"
        Text {
            id: chipLabel
            anchors.centerIn: parent
            color: parent.dim ? "#5e5e68" : (parent.accent ? theme.accent : "#c0c0c8")
            font.pixelSize: 11
        }
    }

    HelpOverlay {
        id: help
        anchors.fill: parent
        visible: false
    }

    SettingsDialog {
        id: settingsDialog
        onClosed: list.forceActiveFocus()
    }
}
