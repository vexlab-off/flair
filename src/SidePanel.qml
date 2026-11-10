import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// The right-hand side: where every AI result shows up.
Rectangle {
    id: panel
    color: theme.surface
    radius: 12
    border.color: theme.line
    border.width: 1

    property alias results: resultsList
    readonly property bool narrow: width < 440
    signal revealRequested(string path)

    readonly property var tabs: [
        { key: "preview", label: "Aperçu", icon: "eye" },
        { key: "search", label: "Recherche", icon: "search" },
        { key: "chat", label: "Chat", icon: "chat" },
        { key: "plan", label: "Plan", icon: "plan" }
    ]

    component EmptyState: ColumnLayout {
        property string icon
        property string title
        property string body
        property var keys: []
        spacing: 10
        Icon { Layout.alignment: Qt.AlignHCenter; name: parent.icon; size: 30; color: theme.textFaint; stroke: 1.3 }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: parent.title
            color: theme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: parent.body
            color: theme.textDim
            font.pixelSize: 12
            lineHeight: 1.25
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            spacing: 6
            Repeater {
                model: parent.parent.keys
                delegate: Keycap { required property string modelData; text: modelData }
            }
        }
    }

    component PanelTitle: Text {
        Layout.fillWidth: true
        color: theme.text
        font.pixelSize: 17
        font.weight: Font.Bold
        font.letterSpacing: -0.2
        elide: Text.ElideMiddle
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Segmented tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: tabRow.implicitWidth + 6
                radius: 9
                color: theme.background
                border.color: theme.line
                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: panel.tabs
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool active: backend.panel === modelData.key
                            height: 26
                            width: tabContent.implicitWidth + 18
                            radius: 7
                            color: active ? theme.raised : (tabHover.containsMouse ? theme.alpha(theme.text, 0.04) : "transparent")
                            Row {
                                id: tabContent
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: modelData.icon; size: 14
                                    color: parent.parent.active ? theme.highlight : theme.textFaint
                                }
                                Text {
                                    visible: !panel.narrow || parent.parent.active
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: parent.parent.active ? theme.text : theme.textDim
                                    font.pixelSize: 12
                                    font.weight: parent.parent.active ? Font.DemiBold : Font.Normal
                                }
                            }
                            MouseArea {
                                id: tabHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: backend.panel = modelData.key
                            }
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
            BusyIndicator {
                visible: backend.busy
                running: backend.busy
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: ["preview", "search", "chat", "plan"].indexOf(backend.panel)

            // ---------------------------------------------------------- preview
            Item {
                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: !backend.previewTitle
                    icon: "sparkle"
                    title: "Résumé par l'IA"
                    body: "Sélectionne un fichier, un dossier ou un dépôt et appuie sur Espace. D explique les changements Git en cours."
                    keys: ["Espace", "D"]
                }
                ColumnLayout {
                    anchors.fill: parent
                    visible: backend.previewTitle !== ""
                    spacing: 6
                    PanelTitle { text: backend.previewTitle }
                    RowLayout {
                        spacing: 8
                        Text {
                            text: backend.previewMeta
                            color: theme.textDim
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.maximumWidth: panel.width - 140
                        }
                        Rectangle {
                            visible: backend.previewEngine !== ""
                            implicitWidth: engineRow.implicitWidth + 14
                            implicitHeight: 20
                            radius: 10
                            color: theme.alpha(theme.highlight, 0.12)
                            Row {
                                id: engineRow
                                anchors.centerIn: parent
                                spacing: 4
                                Icon { anchors.verticalCenter: parent.verticalCenter; name: "sparkle"; size: 11; color: theme.highlight }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: backend.previewEngine
                                    color: theme.highlight
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.topMargin: 8; height: 1; color: theme.line }
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        TextArea {
                            readOnly: true
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.MarkdownText
                            text: backend.previewText
                            color: theme.text
                            selectionColor: theme.alpha(theme.highlight, 0.35)
                            selectedTextColor: theme.text
                            font.pixelSize: 13
                            background: null
                            selectByMouse: true
                            leftPadding: 0
                            rightPadding: 4
                        }
                    }
                }
            }

            // ---------------------------------------------------------- search
            ColumnLayout {
                spacing: 8
                PanelTitle { text: backend.searchQuery ? "« " + backend.searchQuery + " »" : "Recherche" }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: indexer.running
                          ? "Indexation… " + indexer.done + " / " + indexer.total
                          : (indexer.size > 0 ? "Par le sens · index de " + indexer.size + " fichiers"
                                              : "Par nom · I indexe ce dossier pour chercher par le sens")
                    color: theme.textDim
                    font.pixelSize: 12
                }
                ProgressBar {
                    Layout.fillWidth: true
                    visible: indexer.running
                    from: 0
                    to: Math.max(1, indexer.total)
                    value: indexer.done
                }
                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 4
                    clip: true
                    model: backend.searchResults
                    spacing: 2
                    keyNavigationEnabled: true
                    highlightMoveDuration: 0
                    Keys.onReturnPressed: if (currentIndex >= 0) panel.revealRequested(model[currentIndex].path)
                    Keys.onEnterPressed: if (currentIndex >= 0) panel.revealRequested(model[currentIndex].path)
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem && ListView.view.activeFocus
                        width: ListView.view.width
                        height: 48
                        radius: 8
                        color: current ? theme.alpha(theme.highlight, 0.14) : (hit.containsMouse ? theme.alpha(theme.text, 0.035) : "transparent")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Icon { name: "file"; size: 16; color: theme.textDim }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideMiddle
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.relative
                                    color: theme.textFaint
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                }
                            }
                            // Match strength as a short bar rather than a raw percentage.
                            Rectangle {
                                visible: modelData.score >= 0
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 4
                                radius: 2
                                color: theme.line
                                Rectangle {
                                    width: parent.width * Math.max(0.05, Math.min(1, (modelData.score - 0.3) / 0.5))
                                    height: parent.height
                                    radius: 2
                                    color: theme.highlight
                                }
                            }
                        }
                        MouseArea {
                            id: hit
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: resultsList.currentIndex = index
                            onDoubleClicked: panel.revealRequested(modelData.path)
                        }
                    }
                    EmptyState {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: resultsList.count === 0 && !backend.busy
                        icon: "search"
                        title: backend.searchQuery ? "Aucun résultat" : "Cherche comme tu parles"
                        body: backend.searchQuery ? "Essaie d'autres mots, ou indexe ce dossier pour chercher par le sens."
                                                  : "« la facture d'électricité de mars », « le script qui redimensionne les images »…"
                        keys: ["/", "I"]
                    }
                }
            }

            // ---------------------------------------------------------- chat
            ColumnLayout {
                spacing: 8
                PanelTitle { text: "Chat"; visible: chatList.count > 0 }
                Text {
                    visible: chatList.count > 0
                    Layout.fillWidth: true
                    text: backend.chatFolder || backend.currentPath
                    color: theme.textFaint
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                }
                ListView {
                    id: chatList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 12
                    model: backend.chatLog
                    onCountChanged: positionViewAtEnd()
                    Connections {
                        target: backend
                        function onChatChanged() { chatList.positionViewAtEnd() }
                    }
                    delegate: Item {
                        required property var modelData
                        readonly property bool mine: modelData.role === "user"
                        width: ListView.view.width
                        height: bubble.height
                        Rectangle {
                            id: bubble
                            anchors.right: parent.mine ? parent.right : undefined
                            width: parent.mine ? Math.min(parent.width * 0.85, body.implicitWidth + 24) : parent.width
                            height: body.implicitHeight + (parent.mine ? 16 : 4)
                            radius: 10
                            color: parent.mine ? theme.alpha(theme.highlight, 0.14) : "transparent"
                            TextEdit {
                                id: body
                                anchors.fill: parent
                                anchors.margins: parent.parent.mine ? 8 : 2
                                anchors.leftMargin: parent.parent.mine ? 12 : 0
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                textFormat: parent.parent.mine ? TextEdit.PlainText : TextEdit.MarkdownText
                                text: modelData.text || "…"
                                color: theme.text
                                selectionColor: theme.alpha(theme.highlight, 0.35)
                                font.pixelSize: 13
                            }
                        }
                    }
                    EmptyState {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: chatList.count === 0
                        icon: "chat"
                        title: "Discute avec ce dossier"
                        body: "Pose une question sur ce qu'il contient. Avec un index, les fichiers pertinents sont lus pour répondre."
                        keys: ["C"]
                    }
                }
            }

            // ---------------------------------------------------------- plan
            Item {
                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: !backend.planRequest
                    icon: "plan"
                    title: "Ranger, déplacer, renommer"
                    body: "Décris ce que tu veux en français, ou laisse flair ranger par type. Rien ne bouge avant ta validation, et Ctrl+Z annule."
                    keys: [":", "S", "Maj+S"]
                }
                ColumnLayout {
                    anchors.fill: parent
                    visible: backend.planRequest !== ""
                    spacing: 8
                    PanelTitle { text: backend.planRequest; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                    Text {
                        Layout.fillWidth: true
                        text: backend.planExplanation
                        color: theme.textDim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        lineHeight: 1.2
                    }
                    Repeater {
                        model: backend.planSkipped
                        delegate: RowLayout {
                            required property string modelData
                            Layout.fillWidth: true
                            spacing: 8
                            Icon { name: "alert"; size: 14; color: theme.warning }
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: theme.warning
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: theme.line; visible: planList.count > 0 }
                    ListView {
                        id: planList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: backend.planItems
                        spacing: 1
                        delegate: RowLayout {
                            required property var modelData
                            width: ListView.view.width
                            height: 26
                            spacing: 10
                            Icon {
                                name: modelData.op === "mkdir" ? "folder" : "chevron"
                                size: 14
                                color: modelData.op === "mkdir" ? theme.highlight : theme.textFaint
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.op === "mkdir"
                                      ? "<b>" + modelData.to + "/</b>"
                                      : modelData.from + "&nbsp;&nbsp;→&nbsp;&nbsp;<b>" + modelData.to + "</b>"
                                textFormat: Text.StyledText
                                color: theme.text
                                font.pixelSize: 12
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                    RowLayout {
                        visible: planList.count > 0
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: "Appliquer " + planList.count + " actions"
                            highlighted: true
                            Material.accent: theme.highlight
                            onClicked: backend.applyPlan()
                        }
                        Button {
                            text: "Abandonner"
                            flat: true
                            onClicked: backend.discardPlan()
                        }
                        Item { Layout.fillWidth: true }
                        Keycap { text: "Ctrl+Entrée" }
                    }
                }
            }
        }
    }
}
