import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Carries out a right-click action, opening the dialog it needs when it needs
// one. Main.qml and the keyboard shortcuts both come through run().
Item {
    id: actions
    signal done()

    function run(key, path) {
        const info = backend.properties(path)
        switch (key) {
        case "open":
            if (info.isDir) return backend.navigate(path)
            if (files.rowOf(path) >= 0) return backend.activate(files.rowOf(path))
            return backend.openExternally(path)
        case "summarize": return backend.summarize(path)
        case "editor": return backend.openInEditor(path)
        case "system": return backend.openExternally(path)
        case "terminal": return backend.openTerminal(path)
        case "copyPath": return backend.copyPath(path)
        case "rename": return prompt.ask("rename", path)
        case "newFolder": return prompt.ask("newFolder", path)
        case "trash": return backend.trash(path)
        case "properties": return propertiesDialog.show(path)
        case "gitInit": return backend.gitInit(path)
        case "publish": return publishDialog.show(path)
        case "commit": return commitDialog.show(path)
        case "web": return Qt.openUrlExternally(backend.gitState(path).webUrl)
        case "repoFiles": return repoFilesDialog.show(path)
        }
    }

    Connections {
        target: backend
        function onPropertiesRequested(path) { propertiesDialog.show(path) }
    }

    component Label2: Text { color: theme.textDim; font.pixelSize: 12 }
    component Value: Text { color: theme.text; font.pixelSize: 13; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }

    // ------------------------------------------------------------ rename / new folder
    FlairDialog {
        id: prompt
        property string mode
        property string path
        icon: mode === "rename" ? "pencil" : "folder"
        title: mode === "rename" ? "Renommer" : "Nouveau dossier"
        subtitle: mode === "rename" ? "Ctrl+Z annule le renommage." : "Dans " + backend.currentPath
        acceptText: mode === "rename" ? "Renommer" : "Créer"
        acceptEnabled: nameField.text.trim() !== ""
        function ask(kind, target) {
            mode = kind
            path = target
            nameField.text = kind === "rename" ? target.substring(target.lastIndexOf("/") + 1) : "Nouveau dossier"
            open()
            nameField.forceActiveFocus()
            // Select the name without its extension, like every file manager.
            const dot = nameField.text.lastIndexOf(".")
            nameField.select(0, kind === "rename" && dot > 0 ? dot : nameField.text.length)
        }
        onAccepted: {
            const ok = mode === "rename" ? backend.renamePath(path, nameField.text) : backend.createFolder(nameField.text)
            if (ok) close()
        }
        TextField {
            id: nameField
            Layout.fillWidth: true
            onAccepted: prompt.accepted()
        }
    }

    // ------------------------------------------------------------ properties
    FlairDialog {
        id: propertiesDialog
        property var info: ({})
        property string folderSize: ""
        icon: info.isDir ? "folder" : "file"
        title: info.name || ""
        subtitle: info.isDir ? "Dossier" : (info.kind || "")
        acceptText: "Fermer"
        onAccepted: close()
        function show(path) {
            info = backend.properties(path)
            folderSize = info.isDir ? "Calcul…" : ""
            if (info.isDir) backend.computeFolderSize(path)
            open()
        }
        Connections {
            target: backend
            function onFolderSizeReady(path, bytes, count) {
                if (path !== propertiesDialog.info.path) return
                propertiesDialog.folderSize = Qt.locale("fr_FR").formattedDataSize(bytes, 1, Locale.DataSizeTraditionalFormat)
                        + " · " + count + " fichier" + (count > 1 ? "s" : "")
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 16
            rowSpacing: 8
            Label2 { text: "Emplacement" }      Value { text: propertiesDialog.info.folder || "" }
            Label2 { text: "Taille" }           Value { text: propertiesDialog.info.isDir ? propertiesDialog.folderSize : (propertiesDialog.info.size || "") }
            Label2 { text: "Contenu"; visible: !!propertiesDialog.info.isDir }
            Value { visible: !!propertiesDialog.info.isDir; text: (propertiesDialog.info.items || 0) + " éléments au premier niveau" }
            Label2 { text: "Modifié" }          Value { text: propertiesDialog.info.modified || "" }
            Label2 { text: "Créé"; visible: !!propertiesDialog.info.created }
            Value { visible: !!propertiesDialog.info.created; text: propertiesDialog.info.created || "" }
            Label2 { text: "Propriétaire" }     Value { text: propertiesDialog.info.owner || "" }
            Label2 { text: "Permissions" }      Value { text: (propertiesDialog.info.permissions || "") + (propertiesDialog.info.writable ? "" : "  · lecture seule"); font.family: "monospace" }
            Label2 { text: "Lien vers"; visible: !!propertiesDialog.info.isLink }
            Value { visible: !!propertiesDialog.info.isLink; text: propertiesDialog.info.target || "" }
        }
        Button {
            text: "Copier le chemin"
            flat: true
            onClicked: backend.copyPath(propertiesDialog.info.path)
        }
    }

    // ------------------------------------------------------------ publish on GitHub
    FlairDialog {
        id: publishDialog
        property string path
        property bool isPrivate: true
        icon: "github"
        title: "Publier sur GitHub"
        subtitle: "Crée le dépôt sur ton compte" + (github.login ? " (" + github.login + ")" : "") + " et y envoie ce dossier. Git est initialisé et un premier commit créé si besoin."
        acceptText: "Publier"
        acceptEnabled: repoName.text.trim() !== "" && !/[\s\/]/.test(repoName.text.trim())
        function show(target) {
            path = target
            repoName.text = target.substring(target.lastIndexOf("/") + 1).replace(/\s+/g, "-")
            repoDescription.text = ""
            isPrivate = true
            working = false
            open()
        }
        onAccepted: { working = true; backend.publishRepo(path, repoName.text, repoDescription.text, isPrivate) }
        Connections {
            target: backend
            enabled: publishDialog.working
            function onGitJobFinished(ok) { publishDialog.working = false; if (ok) publishDialog.close() }
        }
        Text { text: "Nom du dépôt"; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
        TextField { id: repoName; Layout.fillWidth: true }
        Text { text: "Description (facultative)"; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
        TextField { id: repoDescription; Layout.fillWidth: true; placeholderText: "Une phrase sur le projet" }
        Text { text: "Visibilité"; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
        RowLayout {
            spacing: 8
            Repeater {
                model: [{ v: true, label: "Privé", icon: "lock", text: "Toi seul" }, { v: false, label: "Public", icon: "globe", text: "Tout le monde" }]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool chosen: publishDialog.isPrivate === modelData.v
                    Layout.fillWidth: true
                    height: 52
                    radius: 9
                    color: chosen ? theme.alpha(theme.highlight, 0.12) : theme.background
                    border.color: chosen ? theme.highlight : theme.line
                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 16; color: parent.parent.chosen ? theme.highlight : theme.textDim }
                        Column {
                            Text { text: modelData.label; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Text { text: modelData.text; color: theme.textDim; font.pixelSize: 11 }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: publishDialog.isPrivate = modelData.v }
                }
            }
        }
    }

    // ------------------------------------------------------------ commit
    FlairDialog {
        id: commitDialog
        property var state: ({})
        property bool push: true
        property bool suggesting: false
        icon: "check"
        title: state.hasRemote ? "Commit et push" : "Commit"
        subtitle: (state.changes || 0) + " fichier(s) modifié(s) sur la branche " + (state.branch || "")
        acceptText: state.hasRemote && push ? "Commit et push" : "Commit"
        acceptEnabled: message.text.trim() !== ""
        function show(path) {
            state = backend.gitState(path)
            push = state.hasRemote
            message.text = ""
            working = false
            open()
            message.forceActiveFocus()
        }
        onAccepted: { working = true; backend.commit(state.top, message.text, push && state.hasRemote) }
        Connections {
            target: backend
            function onGitJobFinished(ok) { if (commitDialog.working) { commitDialog.working = false; if (ok) commitDialog.close() } }
            function onCommitMessageReady(text) { commitDialog.suggesting = false; if (text) message.text = text }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(120, statusText.implicitHeight + 16)
            radius: 8
            color: theme.background
            border.color: theme.line
            ScrollView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                Text { id: statusText; text: commitDialog.state.status || ""; color: theme.textDim; font.family: "monospace"; font.pixelSize: 11 }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "Message"; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
            Button {
                text: commitDialog.suggesting ? "Rédaction…" : "Suggérer avec l'IA"
                flat: true
                enabled: !commitDialog.suggesting
                onClicked: { commitDialog.suggesting = true; backend.suggestCommitMessage(commitDialog.state.top) }
            }
        }
        TextArea {
            id: message
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            wrapMode: TextEdit.Wrap
            placeholderText: "Ce que change ce commit, à l'impératif"
        }
        CheckBox {
            visible: !!commitDialog.state.hasRemote
            text: "Envoyer sur GitHub (push)"
            checked: commitDialog.push
            onToggled: commitDialog.push = checked
        }
    }

    // ------------------------------------------------------------ repository files
    FlairDialog {
        id: repoFilesDialog
        property string path
        property var templates: []
        property var chosen: []
        property bool drafting: false
        property bool hasGitignore: false
        property bool hasReadme: false
        property bool hasLicense: false
        icon: "document"
        title: "Fichiers du dépôt"
        subtitle: "Les fichiers de base d'un projet sur GitHub. Rien d'existant n'est remplacé."
        acceptText: "Créer"
        acceptEnabled: (!hasGitignore && chosen.length > 0) || (!hasReadme && readme.text.trim() !== "") || (!hasLicense && license.checked)
        width: Math.min(Overlay.overlay ? Overlay.overlay.width - 60 : 640, 640)
        function show(target) {
            path = target
            templates = backend.gitignoreTemplates()
            chosen = backend.detectGitignore(target)
            const p = backend.properties(target + "/.gitignore"), r = backend.properties(target + "/README.md"), l = backend.properties(target + "/LICENSE")
            hasGitignore = !!p.name; hasReadme = !!r.name; hasLicense = !!l.name
            readme.text = ""
            license.checked = !hasLicense
            open()
        }
        function toggle(key) {
            const next = chosen.slice()
            const i = next.indexOf(key)
            if (i >= 0) next.splice(i, 1); else next.push(key)
            chosen = next
        }
        onAccepted: {
            let ok = true
            if (!hasGitignore && chosen.length) ok = backend.writeGitignore(path, chosen) && ok
            if (!hasReadme && readme.text.trim() !== "") ok = backend.writeNewFile(path + "/README.md", readme.text) && ok
            if (!hasLicense && license.checked) ok = backend.writeLicense(path) && ok
            if (ok) close()
        }
        Connections {
            target: backend
            function onReadmeDraftReady(directory, text) {
                if (directory !== repoFilesDialog.path) return
                repoFilesDialog.drafting = false
                if (text) readme.text = text
            }
        }

        Text { text: ".gitignore" + (repoFilesDialog.hasGitignore ? " · existe déjà" : ""); color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
        Text {
            Layout.fillWidth: true
            visible: !repoFilesDialog.hasGitignore
            text: "Ce que Git doit ignorer. Les modèles cochés correspondent à ce que contient le dossier."
            color: theme.textDim; font.pixelSize: 12; wrapMode: Text.Wrap
        }
        Flow {
            visible: !repoFilesDialog.hasGitignore
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: repoFilesDialog.templates
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: repoFilesDialog.chosen.indexOf(modelData.key) >= 0
                    width: chipText.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: on ? theme.alpha(theme.highlight, 0.14) : theme.background
                    border.color: on ? theme.highlight : theme.line
                    Text { id: chipText; anchors.centerIn: parent; text: modelData.label; color: theme.text; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: repoFilesDialog.toggle(modelData.key) }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Text { Layout.fillWidth: true; text: "README.md" + (repoFilesDialog.hasReadme ? " · existe déjà" : ""); color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
            Button {
                visible: !repoFilesDialog.hasReadme
                text: repoFilesDialog.drafting ? "Rédaction…" : "Rédiger avec l'IA"
                flat: true
                enabled: !repoFilesDialog.drafting
                onClicked: { repoFilesDialog.drafting = true; backend.draftReadme(repoFilesDialog.path) }
            }
        }
        ScrollView {
            visible: !repoFilesDialog.hasReadme
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            TextArea {
                id: readme
                wrapMode: TextEdit.Wrap
                font.family: "monospace"
                font.pixelSize: 12
                placeholderText: "La présentation du projet, en Markdown. Laisse l'IA en rédiger une à partir du dossier, puis relis-la."
            }
        }

        CheckBox {
            id: license
            visible: !repoFilesDialog.hasLicense
            text: "LICENSE (MIT, à ton nom)"
        }
        Text {
            visible: repoFilesDialog.hasLicense
            text: "LICENSE · existe déjà"
            color: theme.textDim; font.pixelSize: 12
        }
    }
}
