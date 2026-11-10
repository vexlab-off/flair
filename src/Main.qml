import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1360
    height: 840
    minimumWidth: 760
    minimumHeight: 560
    visible: true
    title: backend.view === "github" ? "flair — GitHub" : "flair — " + backend.currentPath
    color: theme.background

    Material.theme: Material.Dark
    Material.accent: theme.highlight
    Material.background: theme.surface
    Material.foreground: theme.text

    // "", "search", "command", "chat", "path", "clone", "filter"
    property string inputMode: ""
    property string selectedPath: ""
    readonly property bool inGitHub: backend.view === "github"
    readonly property bool browsing: inputMode === "" && !settingsDialog.visible && !help.visible
    // Half-screen tiles and small laptops: the sidebar folds to icons.
    readonly property bool compact: width < 1240
    readonly property string homePath: backend.places.length ? backend.places[0].path : ""

    function focusList() { (inGitHub ? repoList : list).forceActiveFocus() }
    function openInput(mode) {
        inputMode = mode
        input.text = mode === "path" ? backend.currentPath + "/" : (mode === "filter" ? github.filter : "")
        input.forceActiveFocus()
        if (mode === "chat") backend.panel = "chat"
        if (mode === "command") backend.panel = "plan"
    }
    function closeInput() {
        inputMode = ""
        focusList()
    }
    function submit() {
        const text = input.text
        switch (inputMode) {
        case "search": backend.search(text); closeInput(); if (backend.searchResults.length) side.results.forceActiveFocus(); return
        case "command": backend.command(text); closeInput(); return
        case "chat": backend.ask(text); input.text = ""; return  // stays open for the next question
        case "path": if (backend.navigate(text)) closeInput(); return
        case "clone": backend.clone(text); closeInput(); return
        case "filter": closeInput(); return
        }
    }
    function handleEscape() {
        if (help.visible) { help.visible = false; return }
        if (inputMode !== "") {
            if (inputMode === "filter") github.filter = ""
            closeInput(); return
        }
        if (backend.busy) { backend.cancel(); return }
        if (backend.panel === "plan" && backend.planItems.length) { backend.discardPlan(); return }
        if (inGitHub && github.filter !== "") { github.filter = ""; return }
        backend.clearError()
        focusList()
    }
    function summarizeCurrent() {
        if (inGitHub) backend.summarizeRepo(repoList.currentIndex)
        else backend.summarize(win.selectedPath || backend.currentPath)
    }
    function crumbLabel(path) {
        if (path === homePath) return "Accueil"
        if (path === "/") return "/"
        return path.substring(path.lastIndexOf("/") + 1)
    }

    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; enabled: inputMode === ""; onActivated: help.visible = !help.visible }
    Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: Qt.quit() }
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; enabled: !settingsDialog.visible; onActivated: win.handleEscape() }
    Shortcut { sequence: "Space"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: win.summarizeCurrent() }
    Shortcut { sequence: "/"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: win.openInput(win.inGitHub ? "filter" : "search") }
    Shortcut { sequence: ":"; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: win.openInput("command") }
    Shortcut { sequence: "Ctrl+K"; context: Qt.ApplicationShortcut; enabled: !win.inGitHub; onActivated: win.openInput("command") }
    Shortcut { sequence: "C"; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: win.openInput("chat") }
    Shortcut { sequence: "S"; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: backend.autoSort() }
    Shortcut { sequence: "Shift+S"; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: backend.smartSort() }
    Shortcut { sequence: "I"; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: backend.buildIndex() }
    Shortcut { sequence: "D"; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: backend.explainChanges() }
    Shortcut {
        sequence: "E"; context: Qt.ApplicationShortcut; enabled: browsing
        onActivated: {
            if (win.inGitHub) {
                const repo = github.at(repoList.currentIndex)
                if (repo.localPath) backend.openInEditor(repo.localPath)
            } else {
                backend.openInEditor(win.selectedPath || backend.currentPath)
            }
        }
    }
    Shortcut { sequence: "R"; context: Qt.ApplicationShortcut; enabled: browsing && win.inGitHub; onActivated: github.refresh() }
    Shortcut {
        sequence: "G"; context: Qt.ApplicationShortcut; enabled: browsing
        onActivated: win.inGitHub ? backend.openRepoOnWeb(repoList.currentIndex) : backend.openOnWeb()
    }
    Shortcut { sequence: "Ctrl+G"; context: Qt.ApplicationShortcut; onActivated: win.inGitHub ? backend.showFiles() : backend.showGitHub() }
    Shortcut { sequence: "Ctrl+Shift+G"; context: Qt.ApplicationShortcut; onActivated: win.openInput("clone") }
    Shortcut { sequence: "Ctrl+L"; context: Qt.ApplicationShortcut; onActivated: win.openInput("path") }
    Shortcut { sequence: "~"; context: Qt.ApplicationShortcut; enabled: browsing; onActivated: backend.navigate("~") }
    Shortcut { sequence: "."; context: Qt.ApplicationShortcut; enabled: browsing && !win.inGitHub; onActivated: files.showHidden = !files.showHidden }
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
        function onViewChanged() { Qt.callLater(win.focusList) }
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

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            compact: win.compact
            Layout.preferredWidth: compact ? 60 : 232
            Layout.fillHeight: true
            onSettingsRequested: settingsDialog.open()
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 14
            spacing: 12

            // -------------------------------------------------------- top bar
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 4

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    visible: !win.inGitHub
                    color: upHover.containsMouse ? theme.raised : "transparent"
                    Icon { anchors.centerIn: parent; name: "arrowUp"; size: 16; color: theme.textDim }
                    MouseArea { id: upHover; anchors.fill: parent; hoverEnabled: true; onClicked: backend.goUp() }
                }

                // Breadcrumb
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    contentWidth: crumbs.implicitWidth
                    clip: true
                    interactive: contentWidth > width
                    onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
                    Row {
                        id: crumbs
                        height: parent.height
                        spacing: 2
                        visible: !win.inGitHub
                        Repeater {
                            model: backend.breadcrumb.filter(p => !(win.homePath.startsWith(p + "/") || (p === "/" && win.homePath !== "" && backend.currentPath.startsWith(win.homePath))))
                            delegate: Row {
                                required property string modelData
                                required property int index
                                height: parent.height
                                spacing: 2
                                Icon {
                                    visible: index > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "chevron"; size: 14; color: theme.textFaint
                                }
                                Rectangle {
                                    readonly property bool last: modelData === backend.currentPath
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 28
                                    width: crumbContent.implicitWidth + 16
                                    radius: 7
                                    color: crumbHover.containsMouse ? theme.raised : "transparent"
                                    Row {
                                        id: crumbContent
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Icon {
                                            visible: modelData === win.homePath
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "home"; size: 14
                                            color: parent.parent.last ? theme.text : theme.textDim
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: win.crumbLabel(modelData)
                                            color: parent.parent.last ? theme.text : theme.textDim
                                            font.pixelSize: parent.parent.last ? 15 : 13
                                            font.weight: parent.parent.last ? Font.Bold : Font.Normal
                                        }
                                    }
                                    MouseArea { id: crumbHover; anchors.fill: parent; hoverEnabled: true; onClicked: backend.navigate(modelData) }
                                }
                            }
                        }
                    }
                    Row {
                        visible: win.inGitHub
                        height: parent.height
                        spacing: 10
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "github"; size: 18; color: theme.text }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "GitHub"
                            color: theme.text
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: github.login ? "@" + github.login : ""
                            color: theme.textDim
                            font.pixelSize: 13
                        }
                    }
                }

                // Search affordance: the same thing / does.
                Rectangle {
                    Layout.preferredWidth: win.compact ? 200 : 260
                    Layout.preferredHeight: 32
                    radius: 8
                    color: theme.surface
                    border.color: searchHover.containsMouse ? theme.alpha(theme.highlight, 0.5) : theme.line
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 8
                        Icon { name: "search"; size: 14; color: theme.textFaint }
                        Text {
                            Layout.fillWidth: true
                            text: win.inGitHub ? (github.filter || "Filtrer les dépôts") : "Rechercher dans ce dossier"
                            color: win.inGitHub && github.filter ? theme.text : theme.textFaint
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Keycap { text: "/" }
                    }
                    MouseArea { id: searchHover; anchors.fill: parent; hoverEnabled: true; onClicked: win.openInput(win.inGitHub ? "filter" : "search") }
                }
            }

            // -------------------------------------------------------- body
            SplitView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Horizontal
                handle: Item {
                    implicitWidth: 12
                    Rectangle {
                        anchors.centerIn: parent
                        width: 3; height: 32; radius: 1.5
                        color: SplitHandle.hovered || SplitHandle.pressed ? theme.highlight : theme.line
                    }
                }

                // Files or repositories
                Rectangle {
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 320
                    color: theme.surface
                    radius: 12
                    border.color: theme.line

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 0

                        // Column headers
                        RowLayout {
                            visible: !win.inGitHub
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.leftMargin: 41
                            Layout.rightMargin: 14
                            spacing: 12
                            Text { Layout.fillWidth: true; text: "Nom"; color: theme.textFaint; font.pixelSize: 11; font.weight: Font.Medium }
                            Text { Layout.preferredWidth: 76; horizontalAlignment: Text.AlignRight; text: "Taille"; color: theme.textFaint; font.pixelSize: 11; font.weight: Font.Medium }
                            Text { Layout.preferredWidth: 128; horizontalAlignment: Text.AlignRight; text: "Modifié"; color: theme.textFaint; font.pixelSize: 11; font.weight: Font.Medium }
                        }
                        Rectangle { visible: !win.inGitHub; Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6; height: 1; color: theme.line }

                        ListView {
                            id: list
                            visible: !win.inGitHub
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 4
                            clip: true
                            focus: true
                            model: files
                            spacing: 1
                            highlightMoveDuration: 0
                            keyNavigationEnabled: true
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {}

                            onCurrentIndexChanged: if (currentIndex >= 0) win.selectedPath = files.pathAt(currentIndex)

                            delegate: FileRow {
                                width: ListView.view.width - 10
                                x: 2
                                current: ListView.isCurrentItem
                                focused: list.activeFocus
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

                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: list.count === 0
                                spacing: 8
                                Icon { Layout.alignment: Qt.AlignHCenter; name: "folder"; size: 34; stroke: 1.2; color: theme.textFaint }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Dossier vide"; color: theme.textDim; font.pixelSize: 13 }
                            }
                        }

                        // ---------------------------------------------- GitHub
                        RowLayout {
                            visible: win.inGitHub
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            spacing: 10
                            Text {
                                Layout.fillWidth: true
                                text: github.state === "ready"
                                      ? (github.filter ? github.count + " sur " + github.total + " dépôts" : github.total + " dépôts")
                                        + " · clonés dans " + settings.cloneDirectory.replace(win.homePath, "~")
                                      : ""
                                color: theme.textFaint
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 7
                                color: refreshHover.containsMouse ? theme.raised : "transparent"
                                Icon { anchors.centerIn: parent; name: "refresh"; size: 15; color: theme.textDim }
                                MouseArea { id: refreshHover; anchors.fill: parent; hoverEnabled: true; onClicked: github.refresh() }
                            }
                        }
                        Rectangle { visible: win.inGitHub; Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6; height: 1; color: theme.line }

                        ListView {
                            id: repoList
                            visible: win.inGitHub
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 4
                            clip: true
                            model: github
                            spacing: 1
                            highlightMoveDuration: 0
                            keyNavigationEnabled: true
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {}

                            delegate: RepoRow {
                                width: ListView.view.width - 10
                                x: 2
                                current: ListView.isCurrentItem
                                focused: repoList.activeFocus
                                onClicked: { repoList.currentIndex = index; repoList.forceActiveFocus() }
                                onDoubleClicked: backend.activateRepo(index)
                            }

                            Keys.onPressed: (event) => {
                                if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) return
                                switch (event.key) {
                                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Right: case Qt.Key_L:
                                    backend.activateRepo(currentIndex); event.accepted = true; break
                                case Qt.Key_Backspace: case Qt.Key_Left: case Qt.Key_H:
                                    backend.showFiles(); event.accepted = true; break
                                case Qt.Key_J: incrementCurrentIndex(); event.accepted = true; break
                                case Qt.Key_K: decrementCurrentIndex(); event.accepted = true; break
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 60, 380)
                                visible: github.state !== "ready" || repoList.count === 0
                                spacing: 10
                                BusyIndicator { Layout.alignment: Qt.AlignHCenter; visible: github.state === "loading"; running: visible }
                                Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: github.state !== "loading"
                                    name: github.state === "error" ? "alert" : "github"
                                    size: 34
                                    color: github.state === "error" ? theme.warning : theme.textFaint
                                }
                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                    text: github.state === "loading" ? "Lecture de tes dépôts…"
                                        : github.state === "error" ? github.error
                                        : github.filter ? "Aucun dépôt ne correspond à « " + github.filter + " »."
                                        : "Aucun dépôt sur ce compte."
                                    color: theme.textDim
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }
                }

                SidePanel {
                    id: side
                    SplitView.preferredWidth: Math.round(win.width * 0.34)
                    SplitView.minimumWidth: 290
                    onRevealRequested: (path) => backend.reveal(path)
                }
            }

            // -------------------------------------------------------- input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                visible: win.inputMode !== ""
                radius: 10
                color: theme.surface
                border.color: theme.highlight
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10
                    Icon {
                        name: ({ search: "search", command: "sparkle", chat: "chat", path: "folder", clone: "clone", filter: "search" })[win.inputMode] || "search"
                        size: 16
                        color: theme.highlight
                    }
                    Text {
                        text: ({ search: "Rechercher", command: "Commande", chat: "Question", path: "Aller à", clone: "Cloner", filter: "Filtrer" })[win.inputMode] || ""
                        color: theme.highlight
                        font.weight: Font.DemiBold
                        font.pixelSize: 13
                    }
                    TextField {
                        id: input
                        Layout.fillWidth: true
                        background: null
                        font.pixelSize: 14
                        color: theme.text
                        selectionColor: theme.alpha(theme.highlight, 0.35)
                        placeholderTextColor: theme.textFaint
                        placeholderText: ({
                            search: "ce que tu cherches, avec tes mots : « facture électricité 2025 »",
                            command: "« range les captures d'écran par mois », « renomme les photos par date »…",
                            chat: "pose une question sur ce dossier",
                            path: "chemin",
                            clone: "propriétaire/dépôt ou URL github.com",
                            filter: "nom, description ou langage"
                        })[win.inputMode] || ""
                        onAccepted: win.submit()
                        onTextChanged: if (win.inputMode === "filter") github.filter = text
                    }
                    Keycap { text: "Entrée" }
                    Keycap { text: "Échap" }
                }
            }

            // -------------------------------------------------------- status
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                spacing: 8
                Icon {
                    visible: backend.error !== ""
                    name: "alert"; size: 14; color: theme.danger
                }
                Text {
                    Layout.fillWidth: true
                    text: backend.error || backend.status
                          || (win.inGitHub ? "Entrée ouvre le clone ou clone le dépôt · Espace résume le README · G ouvre sur GitHub"
                                           : files.count + " éléments" + (files.showHidden ? " · fichiers cachés visibles" : ""))
                    color: backend.error ? theme.danger : theme.textDim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Repeater {
                    model: win.inGitHub ? [["Entrée", "ouvrir"], ["Espace", "résumer"], ["?", "aide"]]
                                        : [["Espace", "résumer"], [":", "commande"], ["C", "chat"], ["?", "aide"]]
                    delegate: Row {
                        required property var modelData
                        spacing: 5
                        Keycap { text: modelData[0] }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: theme.textFaint; font.pixelSize: 11 }
                    }
                }
                Row {
                    visible: backend.canUndo
                    spacing: 5
                    Keycap { text: "Ctrl+Z" }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "annuler"; color: theme.textFaint; font.pixelSize: 11 }
                }
            }
        }
    }

    HelpOverlay {
        id: help
        anchors.fill: parent
        visible: false
    }

    SettingsDialog {
        id: settingsDialog
        onClosed: win.focusList()
    }
}
