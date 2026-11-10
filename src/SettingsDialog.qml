import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Where the models live and which one does what.
Dialog {
    id: dialog
    title: "Réglages"
    modal: true
    anchors.centerIn: parent
    width: Math.min(parent.width - 80, 620)
    standardButtons: Dialog.Save | Dialog.Cancel
    background: Rectangle { color: theme.surface; radius: 14; border.color: theme.line }

    onOpened: {
        localUrl.text = settings.localUrl
        localModel.editText = settings.localModel
        embedModel.editText = settings.embedModel
        claudeModel.text = settings.claudeModel
        apiKey.text = settings.anthropicKey
        summaryEngine.currentIndex = settings.summaryEngine === "claude" ? 1 : 0
        heavyEngine.currentIndex = settings.heavyEngine === "local" ? 0 : 1
        cloneDirectory.text = settings.cloneDirectory
        backend.probeEngines()
    }

    onAccepted: {
        settings.localUrl = localUrl.text
        settings.localModel = localModel.editText
        settings.embedModel = embedModel.editText
        settings.claudeModel = claudeModel.text
        settings.anthropicKey = apiKey.text
        settings.summaryEngine = summaryEngine.currentIndex === 1 ? "claude" : "local"
        settings.heavyEngine = heavyEngine.currentIndex === 0 ? "local" : "claude"
        settings.cloneDirectory = cloneDirectory.text
    }

    readonly property var engines: ["Local", "Claude"]

    GridLayout {
        anchors.fill: parent
        columns: 2
        columnSpacing: 16
        rowSpacing: 6

        Label { text: "Modèle local"; font.bold: true; color: theme.highlight; Layout.columnSpan: 2 }

        Label { text: "Serveur" }
        TextField {
            id: localUrl
            Layout.fillWidth: true
            placeholderText: "http://localhost:1234 (LM Studio) ou http://localhost:11434 (Ollama)"
        }
        Label { text: "État" }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: backend.localOnline ? "En ligne · " + backend.localModels.length + " modèles" : "Hors ligne : lance le serveur de LM Studio ou Ollama"
            color: backend.localOnline ? theme.success : theme.warning
        }
        Label { text: "Modèle de chat" }
        ComboBox {
            id: localModel
            Layout.fillWidth: true
            editable: true
            model: backend.localModels
        }
        Label { text: "Embeddings" }
        ComboBox {
            id: embedModel
            Layout.fillWidth: true
            editable: true
            model: backend.localModels
        }
        Label {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Modèle de chat vide = le premier modèle chargé sur le serveur. Les embeddings (recherche par le sens) demandent un modèle dédié, par ex. nomic-embed-text."
            color: theme.textDim
            font.pixelSize: 11
        }

        Label { text: "Claude"; font.bold: true; color: theme.highlight; Layout.columnSpan: 2; Layout.topMargin: 10 }

        Label { text: "Modèle" }
        TextField { id: claudeModel; Layout.fillWidth: true }
        Label { text: "Clé API" }
        TextField {
            id: apiKey
            Layout.fillWidth: true
            echoMode: TextInput.Password
            enabled: !settings.keyFromEnvironment
            placeholderText: settings.keyFromEnvironment ? "Fournie par ANTHROPIC_API_KEY" : "sk-ant-…"
        }

        Label { text: "Répartition"; font.bold: true; color: theme.highlight; Layout.columnSpan: 2; Layout.topMargin: 10 }

        Label { text: "Résumés" }
        ComboBox { id: summaryEngine; Layout.fillWidth: true; model: dialog.engines }
        Label { text: "Chat, plans, Git" }
        ComboBox { id: heavyEngine; Layout.fillWidth: true; model: dialog.engines }

        Label { text: "GitHub"; font.bold: true; color: theme.highlight; Layout.columnSpan: 2; Layout.topMargin: 10 }

        Label { text: "Cloner dans" }
        TextField { id: cloneDirectory; Layout.fillWidth: true; placeholderText: "~/Work" }
    }
}
