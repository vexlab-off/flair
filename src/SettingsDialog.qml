import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Every setting with a sentence on what it changes, grouped by what the user
// is trying to do. Nothing is saved until Enregistrer.
Popup {
    id: dialog
    modal: true
    focus: true
    anchors.centerIn: parent
    width: Math.min(parent.width - 60, 720)
    height: Math.min(parent.height - 60, 820)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle { color: theme.alpha(theme.background, 0.7) }
    background: Rectangle { color: theme.surface; radius: 16; border.color: theme.line }

    // Staged values, written back only on save.
    property string accent
    property string logoStyle: "plein"
    property string mode: "auto"
    property string folderColor: "accent"
    property string editor
    property var editors: []
    property string htmlMode: 'preview'

    readonly property var swatches: [
        { name: "Orange", value: "#ff8a3d" }, { name: "Ambre", value: "#f5b942" },
        { name: "Rouge", value: "#f05252" }, { name: "Rose", value: "#ec5fa6" },
        { name: "Violet", value: "#9b7bff" }, { name: "Bleu", value: "#5c9df5" },
        { name: "Vert", value: "#3ecf8e" }
    ]

    onOpened: {
        logoStyle = settings.logoStyle
        mode = settings.appearanceMode
        folderColor = settings.folderColor
        launcherToggle.checked = settings.launcherFollowsAccent
        accent = settings.accentColor
        editors = settings.installedEditors()
        editor = settings.editorCommand
        editorField.text = editor
        htmlMode = settings.htmlOpenMode
        openCode.checked = settings.openCodeInEditor
        localUrl.text = settings.localUrl
        localModel.editText = settings.localModel
        embedModel.editText = settings.embedModel
        claudeModel.text = settings.claudeModel
        apiKey.text = settings.anthropicKey
        summaryEngine.currentIndex = settings.summaryEngine === "claude" ? 1 : 0
        heavyEngine.currentIndex = settings.heavyEngine === "local" ? 0 : 1
        cloneDirectory.text = settings.cloneDirectory.replace(backend.places.length ? backend.places[0].path : "", "~")
        backend.probeEngines()
        scroller.contentItem.contentY = 0
    }

    function save() {
        settings.logoStyle = logoStyle
        settings.appearanceMode = mode
        settings.folderColor = folderColor
        settings.launcherFollowsAccent = launcherToggle.checked
        settings.accentColor = accent
        settings.editorCommand = editorField.text
        settings.htmlOpenMode = htmlMode
        settings.openCodeInEditor = openCode.checked
        settings.localUrl = localUrl.text
        settings.localModel = localModel.editText
        settings.embedModel = embedModel.editText
        settings.claudeModel = claudeModel.text
        settings.anthropicKey = apiKey.text
        settings.summaryEngine = summaryEngine.currentIndex === 1 ? "claude" : "local"
        settings.heavyEngine = heavyEngine.currentIndex === 0 ? "local" : "claude"
        settings.cloneDirectory = cloneDirectory.text
        close()
    }

    // ------------------------------------------------------------ pieces

    component Section: ColumnLayout {
        id: section
        property string icon
        property string title
        property string intro
        default property alias content: body.data
        Layout.fillWidth: true
        spacing: 14
        RowLayout {
            spacing: 10
            Rectangle {
                width: 30; height: 30; radius: 8
                color: theme.alpha(theme.highlight, 0.14)
                Icon { anchors.centerIn: parent; name: section.icon; size: 16; color: theme.highlight }
            }
            Text { text: section.title; color: theme.text; font.pixelSize: 15; font.weight: Font.Bold }
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: section.intro
            textFormat: Text.StyledText
            color: theme.textDim
            font.pixelSize: 12
            wrapMode: Text.Wrap
            lineHeight: 1.25
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 16
        }
    }

    // A setting: what it is, what it changes, then the control.
    component Field: ColumnLayout {
        id: field
        property string label
        property string help
        default property alias control: holder.data
        Layout.fillWidth: true
        spacing: 4
        Text { text: field.label; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: field.help
            color: theme.textDim
            font.pixelSize: 12
            wrapMode: Text.Wrap
            lineHeight: 1.2
            textFormat: Text.StyledText
        }
        Item {
            id: holder
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: childrenRect.height
        }
    }

    component Toggle: RowLayout {
        id: toggle
        property alias checked: sw.checked
        property string label
        property string help
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: toggle.label; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
            Text {
                Layout.fillWidth: true
                text: toggle.help
                color: theme.textDim
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
        Switch { id: sw; Material.accent: theme.highlight }
    }

    component Divider: Rectangle { Layout.fillWidth: true; height: 1; color: theme.line }

    component Note: Rectangle {
        id: note
        property alias text: noteText.text
        property color tone: theme.textDim
        property string icon: "alert"
        Layout.fillWidth: true
        implicitHeight: noteText.implicitHeight + 20
        radius: 8
        color: theme.alpha(tone, 0.08)
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            Icon { Layout.alignment: Qt.AlignTop; name: note.icon; size: 15; color: note.tone }
            Text {
                id: noteText
                Layout.fillWidth: true
                color: theme.text
                font.pixelSize: 12
                wrapMode: Text.Wrap
                lineHeight: 1.2
                textFormat: Text.StyledText
            }
        }
    }

    // ------------------------------------------------------------ layout

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 24
            Layout.bottomMargin: 16
            spacing: 14
            Logo { size: 34 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Réglages"; color: theme.text; font.pixelSize: 20; font.weight: Font.Bold; font.letterSpacing: -0.3 }
                Text {
                    Layout.fillWidth: true
                    text: "Chaque réglage dit ce qu'il change. Rien n'est enregistré avant « Enregistrer »."
                    color: theme.textDim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }
            Rectangle {
                width: 30; height: 30; radius: 8
                color: closeHover.containsMouse ? theme.raised : "transparent"
                Icon { anchors.centerIn: parent; name: "close"; size: 16; color: theme.textDim }
                MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; onClicked: dialog.close() }
            }
        }
        Divider {}

        ScrollView {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: scroller.availableWidth - 48
                x: 24
                spacing: 28

                Item { height: 4 }

                // ---------------------------------------------- appearance
                Section {
                    icon: "eye"
                    title: "Apparence"
                    intro: "La couleur qui marque la sélection, le logo et les éléments actifs."

                    Field {
                        label: "Couleur d'accent"
                        help: "« Thème Vex » reprend la couleur de ton thème et change avec lui. Les autres restent fixes, quel que soit le thème."
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: dialog.swatches
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool chosen: dialog.accent.toLowerCase() === modelData.value
                                    width: swatchRow.implicitWidth + 20
                                    height: 32
                                    radius: 16
                                    color: chosen ? theme.alpha(modelData.value, 0.16) : theme.background
                                    border.color: chosen ? modelData.value : theme.line
                                    border.width: chosen ? 1.5 : 1
                                    Row {
                                        id: swatchRow
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: modelData.value }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: theme.text; font.pixelSize: 12 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.accent = modelData.value }
                                }
                            }
                            Rectangle {
                                readonly property bool chosen: dialog.accent === "theme"
                                width: themeRow.implicitWidth + 20
                                height: 32
                                radius: 16
                                color: chosen ? theme.alpha(theme.text, 0.08) : theme.background
                                border.color: chosen ? theme.text : theme.line
                                Row {
                                    id: themeRow
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "sparkle"; size: 14; color: theme.textDim }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Thème Vex"; color: theme.text; font.pixelSize: 12 }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.accent = "theme" }
                            }
                        }
                    }

                    Field {
                        label: "Mode"
                        help: "Clair ou sombre, pour flair et Flair Code. « Automatique » suit le thème de Vex."
                        Row {
                            spacing: 8
                            Repeater {
                                model: [["auto", "Automatique", "sparkle"], ["light", "Clair", "sun"], ["dark", "Sombre", "moon"]]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool chosen: dialog.mode === modelData[0]
                                    width: modeRow.implicitWidth + 24; height: 34; radius: 17
                                    color: chosen ? theme.alpha(theme.highlight, 0.16) : theme.background
                                    border.color: chosen ? theme.highlight : theme.line
                                    Row { id: modeRow; anchors.centerIn: parent; spacing: 8
                                        Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData[2]; size: 15; color: parent.parent.chosen ? theme.highlight : theme.textDim }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: theme.text; font.pixelSize: 12 } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.mode = modelData[0] }
                                }
                            }
                        }
                    }

                    Field {
                        label: "Couleur des dossiers"
                        help: "La couleur des icônes de dossier, dans flair et dans Flair Code. En mode clair, elle est assombrie pour rester lisible."
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: [["accent", "Comme l'accent", ""], ["neutral", "Gris", ""], ["#f5b942", "Ambre", "#f5b942"], ["#5c9df5", "Bleu", "#5c9df5"],
                                        ["#3ecf8e", "Vert", "#3ecf8e"], ["#9b7bff", "Violet", "#9b7bff"], ["#ec5fa6", "Rose", "#ec5fa6"]]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool chosen: dialog.folderColor === modelData[0]
                                    width: folderRow.implicitWidth + 22; height: 32; radius: 16
                                    color: chosen ? theme.alpha(theme.highlight, 0.14) : theme.background
                                    border.color: chosen ? theme.highlight : theme.line
                                    Row { id: folderRow; anchors.centerIn: parent; spacing: 8
                                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "folder"; size: 15
                                               color: modelData[0] === "accent" ? theme.highlight : modelData[0] === "neutral" ? theme.textDim : modelData[2] }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: theme.text; font.pixelSize: 12 } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.folderColor = modelData[0] }
                                }
                            }
                        }
                    }

                    Field {
                        label: "Style du logo"
                        help: "Comment le logo porte la couleur d'accent, dans flair, dans Flair Code et dans le lanceur."
                        Row {
                            spacing: 10
                            Repeater {
                                model: [["plein", "Plein", "La tuile en couleur"], ["sombre", "Sombre", "Tuile noire, dessin en couleur"], ["clair", "Clair", "Tuile claire, dessin en couleur"]]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool chosen: dialog.logoStyle === modelData[0]
                                    width: 150
                                    height: 120
                                    radius: 12
                                    color: chosen ? theme.alpha(theme.highlight, 0.1) : theme.background
                                    border.color: chosen ? theme.highlight : theme.line
                                    border.width: chosen ? 2 : 1
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 8
                                            Logo { size: 44; variant: modelData[0] }
                                            FlairCodeMark { size: 44; variant: modelData[0] }
                                        }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[2]; color: theme.textDim; font.pixelSize: 10 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.logoStyle = modelData[0] }
                                }
                            }
                        }
                    }
                    Toggle {
                        id: launcherToggle
                        label: "Le logo du lanceur suit la couleur"
                        help: "Les icônes de flair et de Flair Code dans Super+Espace prennent la couleur et le style choisis ici."
                    }
                }

                Divider {}

                // ---------------------------------------------- system
                Section {
                    icon: "folder"
                    title: "Système"
                    intro: "Faire de flair l'explorateur de fichiers de ton ordinateur : les dossiers s'ouvrent dans flair, et « Afficher dans le dossier » depuis le navigateur, VS Code ou un téléchargement aussi."

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Explorateur de fichiers par défaut"; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Text {
                                Layout.fillWidth: true
                                text: backend.isDefaultFileManager
                                      ? "Activé. Désactiver rétablit l'explorateur d'avant (Nautilus)."
                                      : "Désactivé : Nautilus ouvre les dossiers. Activer est réversible à tout moment ici."
                                color: theme.textDim
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                        Switch {
                            Material.accent: theme.highlight
                            checked: backend.isDefaultFileManager
                            onToggled: backend.setDefaultFileManager(checked)
                        }
                    }
                }

                Divider {}

                // ---------------------------------------------- opening files
                Section {
                    icon: "code"
                    title: "Ouvrir les fichiers"
                    intro: "Ce qui se passe quand tu appuies sur Entrée ou double-cliques un fichier. Les autres fichiers (images, PDF, vidéos…) s'ouvrent avec l'application par défaut du système. E ouvre n'importe quel fichier ou dossier dans l'éditeur."

                    Field {
                        label: "Éditeur de code"
                        help: dialog.editors.length
                              ? "Le programme qui ouvre le code (et le HTML avec E). Choisis un éditeur détecté, ou tape la commande d'un autre."
                              : "Le programme qui ouvre le code (et le HTML avec E). Aucun éditeur connu n'est installé : tape sa commande (« code » pour VS Code)."
                        ColumnLayout {
                            width: parent.width
                            spacing: 8
                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: dialog.editors.length > 0
                                Repeater {
                                    model: dialog.editors
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool chosen: editorField.text === modelData.command
                                        width: edLabel.implicitWidth + 24
                                        height: 30
                                        radius: 8
                                        color: chosen ? theme.alpha(theme.highlight, 0.14) : theme.background
                                        border.color: chosen ? theme.highlight : theme.line
                                        Text { id: edLabel; anchors.centerIn: parent; text: modelData.name; color: theme.text; font.pixelSize: 12 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editorField.text = modelData.command }
                                    }
                                }
                            }
                            TextField {
                                id: editorField
                                Layout.fillWidth: true
                                placeholderText: "code"
                            }
                            Note {
                                visible: editorField.text === "code" && !dialog.editors.some(e => e.command === "code")
                                tone: theme.warning
                                text: "Visual Studio Code n'est pas installé. Dans un terminal : <b>sudo pacman -S code</b>. En attendant, flair te le signalera au lieu d'ouvrir le fichier."
                            }
                        }
                    }
                    Field {
                        label: "Fichiers HTML"
                        help: "Ce que font un double-clic ou Entrée sur une page .html. Un simple clic affiche toujours l'aperçu, et E ouvre toujours l'éditeur."
                        Column {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: [
                                    { key: "preview", icon: "globe", title: "Aperçu dans flair", text: "La page s'affiche rendue dans le panneau de droite et se recharge à chaque enregistrement." },
                                    { key: "editor", icon: "code", title: "Ouvrir dans l'éditeur", text: "Pour modifier le code de la page." },
                                    { key: "browser", icon: "external", title: "Ouvrir dans le navigateur", text: "Ton navigateur par défaut, en plein écran." }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool chosen: dialog.htmlMode === modelData.key
                                    width: parent.width
                                    height: htmlText.implicitHeight + 36
                                    radius: 9
                                    color: chosen ? theme.alpha(theme.highlight, 0.12) : theme.background
                                    border.color: chosen ? theme.highlight : theme.line
                                    Icon { x: 14; y: 13; name: modelData.icon; size: 16; color: parent.chosen ? theme.highlight : theme.textDim }
                                    Column {
                                        x: 42; y: 10
                                        width: parent.width - 56
                                        spacing: 2
                                        Text { text: modelData.title; color: theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { id: htmlText; width: parent.width; text: modelData.text; color: theme.textDim; font.pixelSize: 12; wrapMode: Text.Wrap }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.htmlMode = modelData.key }
                                }
                            }
                        }
                    }
                    Toggle {
                        id: openCode
                        label: "Ouvrir aussi le code dans l'éditeur"
                        help: "Les fichiers de code (.js, .py, .cpp, .qml, .json, Markdown…) s'ouvrent dans l'éditeur au lieu de l'application par défaut."
                    }
                }

                Divider {}

                // ---------------------------------------------- local AI
                Section {
                    icon: "layers"
                    title: "IA locale"
                    intro: "Un modèle qui tourne sur ta machine : rien ne sort de ton ordinateur, c'est gratuit, mais plus lent et moins fin que Claude. flair parle à LM Studio ou à Ollama."

                    Note {
                        tone: backend.localOnline ? theme.success : theme.warning
                        icon: backend.localOnline ? "check" : "alert"
                        text: backend.localOnline
                              ? "Serveur en ligne, " + backend.localModels.length + " modèle(s) disponible(s)."
                              : "Serveur injoignable. Dans LM Studio : onglet <b>Developer</b> → <b>Start Server</b>. Avec Ollama : lance <b>ollama serve</b>."
                    }
                    Field {
                        label: "Adresse du serveur"
                        help: "LM Studio écoute sur <b>http://localhost:1234</b>, Ollama sur <b>http://localhost:11434</b>."
                        RowLayout {
                            width: parent.width
                            spacing: 8
                            TextField { id: localUrl; Layout.fillWidth: true; placeholderText: "http://localhost:1234" }
                            Button {
                                text: "Tester"
                                flat: true
                                onClicked: { settings.localUrl = localUrl.text; backend.probeEngines() }
                            }
                        }
                    }
                    Field {
                        label: "Modèle de discussion"
                        help: "Celui qui résume et répond. Laisse vide pour utiliser le premier modèle chargé dans le serveur."
                        ComboBox { id: localModel; width: parent.width; editable: true; model: backend.localModels }
                    }
                    Field {
                        label: "Modèle d'embeddings"
                        help: "Un petit modèle spécialisé qui transforme chaque fichier en « empreinte de sens » : c'est lui qui permet de chercher « facture d'électricité » et de trouver le bon PDF. Télécharge par exemple <b>nomic-embed-text</b>."
                        ComboBox { id: embedModel; width: parent.width; editable: true; model: backend.localModels }
                    }
                }

                Divider {}

                // ---------------------------------------------- Claude
                Section {
                    icon: "sparkle"
                    title: "Claude"
                    intro: "Le modèle d'Anthropic, bien meilleur pour comprendre un dossier, proposer un rangement ou expliquer du code. Il est payant à l'usage, et le contenu des fichiers concernés est envoyé à Anthropic."

                    Field {
                        label: "Clé API"
                        help: settings.keyFromEnvironment
                              ? "Fournie par la variable ANTHROPIC_API_KEY, qui a priorité sur ce champ."
                              : "À créer sur <b>console.anthropic.com</b> → API Keys. Elle est stockée dans ~/.config/flair/flair.conf, lisible par toi seul."
                        TextField {
                            id: apiKey
                            width: parent.width
                            echoMode: TextInput.Password
                            enabled: !settings.keyFromEnvironment
                            placeholderText: settings.keyFromEnvironment ? "Fournie par ANTHROPIC_API_KEY" : "sk-ant-…"
                        }
                    }
                    Field {
                        label: "Modèle"
                        help: "<b>claude-opus-5-5</b> est le plus capable. <b>claude-sonnet-5-5</b> coûte deux fois moins cher, <b>claude-haiku-5-5</b> beaucoup moins, pour des réponses plus simples."
                        TextField { id: claudeModel; width: parent.width }
                    }
                }

                Divider {}

                // ---------------------------------------------- routing
                Section {
                    icon: "sliders"
                    title: "Qui fait quoi"
                    intro: "Choisis quel moteur s'occupe de chaque tâche. La recherche par le sens utilise toujours le modèle d'embeddings local."

                    Field {
                        label: "Résumés (Espace)"
                        help: "Fréquents et courts : le modèle local suffit souvent et reste privé."
                        ComboBox { id: summaryEngine; width: parent.width; model: ["Local — privé et gratuit", "Claude — plus précis, payant"] }
                    }
                    Field {
                        label: "Chat, plans de rangement et Git"
                        help: "Demandent de vraies capacités de raisonnement : Claude est recommandé. Les plans restent toujours à valider avant que quoi que ce soit bouge."
                        ComboBox { id: heavyEngine; width: parent.width; model: ["Local — privé et gratuit", "Claude — plus précis, payant"] }
                    }
                }

                Divider {}

                // ---------------------------------------------- GitHub
                Section {
                    icon: "github"
                    title: "GitHub"
                    intro: github.login !== ""
                           ? "Connecté en tant que <b>" + github.login + "</b> via l'outil gh."
                           : "Le dossier GitHub passe par l'outil gh. S'il n'est pas connecté, lance « gh auth login » une fois dans un terminal."

                    Field {
                        label: "Cloner les dépôts dans"
                        help: "Quand tu ouvres un dépôt pas encore présent sur la machine, flair le clone dans ce dossier puis l'ouvre. Les clones déjà présents ailleurs (~/Work, ~/Projects…) sont reconnus automatiquement."
                        TextField { id: cloneDirectory; width: parent.width; placeholderText: "~/Work" }
                    }
                }

                Item { height: 8 }
            }
        }

        Divider {}

        // Footer
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.leftMargin: 24
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: "Ctrl+, rouvre ces réglages."
                color: theme.textFaint
                font.pixelSize: 12
            }
            Button { text: "Annuler"; flat: true; onClicked: dialog.close() }
            PrimaryButton {
                text: "Enregistrer"
                onClicked: dialog.save()
            }
        }
    }
}
