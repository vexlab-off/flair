import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// The right-hand side: where every AI result shows up.
Rectangle {
    id: panel
    color: "#141417"
    radius: 10

    property alias results: resultsList
    signal revealRequested(string path)

    readonly property var tabs: [
        { key: "preview", label: "Aperçu", hint: "Espace" },
        { key: "search", label: "Recherche", hint: "/" },
        { key: "chat", label: "Chat", hint: "C" },
        { key: "plan", label: "Plan", hint: ":" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Tabs
        RowLayout {
            spacing: 6
            Repeater {
                model: panel.tabs
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: backend.panel === modelData.key
                    height: 28
                    width: label.implicitWidth + 22
                    radius: 14
                    color: active ? theme.accent : "#1d1d22"
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.active ? theme.accentForeground : "#a0a0aa"
                        font.pixelSize: 12
                        font.bold: parent.active
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: backend.panel = modelData.key
                    }
                }
            }
            Item { Layout.fillWidth: true }
            BusyIndicator {
                visible: backend.busy
                running: backend.busy
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: ["preview", "search", "chat", "plan"].indexOf(backend.panel)

            // ---------------------------------------------------------- preview
            ColumnLayout {
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: backend.previewTitle || "Aperçu"
                    color: "#f2f2f5"
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                Text {
                    Layout.fillWidth: true
                    text: backend.previewMeta + (backend.previewEngine ? "  ·  résumé " + backend.previewEngine : "")
                    color: "#7a7a85"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 8
                    clip: true
                    TextArea {
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.MarkdownText
                        text: backend.previewText || "Choisis un fichier ou un dossier et appuie sur Espace pour un résumé.\n\nD résume les changements Git du dépôt."
                        color: backend.previewText ? "#d8d8de" : "#6a6a74"
                        font.pixelSize: 13
                        background: null
                        selectByMouse: true
                    }
                }
            }

            // ---------------------------------------------------------- search
            ColumnLayout {
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: backend.searchQuery ? "« " + backend.searchQuery + " »" : "Recherche"
                    color: "#f2f2f5"
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: indexer.running
                          ? "Indexation… " + indexer.done + " / " + indexer.total
                          : (indexer.size > 0 ? "Index : " + indexer.size + " fichiers sous " + indexer.root
                                              : "Pas d'index : recherche par nom. I indexe ce dossier pour chercher par le sens.")
                    color: "#7a7a85"
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
                        width: ListView.view.width
                        height: 44
                        radius: 6
                        color: ListView.isCurrentItem && ListView.view.activeFocus ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: score.left
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            Text {
                                width: parent.width
                                text: modelData.name
                                color: "#e6e6ea"
                                font.pixelSize: 13
                                elide: Text.ElideMiddle
                            }
                            Text {
                                width: parent.width
                                text: modelData.relative
                                color: "#6a6a74"
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }
                        Text {
                            id: score
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.score >= 0
                            text: Math.round(modelData.score * 100) + "%"
                            color: theme.accent
                            font.pixelSize: 11
                            font.family: "monospace"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: resultsList.currentIndex = index
                            onDoubleClicked: panel.revealRequested(modelData.path)
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: resultsList.count === 0 && backend.searchQuery !== "" && !backend.busy
                        text: "Aucun résultat."
                        color: "#6a6a74"
                    }
                }
            }

            // ---------------------------------------------------------- chat
            ColumnLayout {
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: "Chat · " + (backend.chatFolder || backend.currentPath)
                    color: "#f2f2f5"
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                ListView {
                    id: chatList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: backend.chatLog
                    onCountChanged: positionViewAtEnd()
                    Connections {
                        target: backend
                        function onChatChanged() { chatList.positionViewAtEnd() }
                    }
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool mine: modelData.role === "user"
                        width: ListView.view.width
                        height: body.implicitHeight + 18
                        radius: 8
                        color: mine ? "#1f1f25" : "transparent"
                        border.color: mine ? "transparent" : "#24242a"
                        TextEdit {
                            id: body
                            anchors.fill: parent
                            anchors.margins: 9
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: parent.mine ? TextEdit.PlainText : TextEdit.MarkdownText
                            text: modelData.text || "…"
                            color: parent.mine ? "#f2f2f5" : "#d0d0d6"
                            font.pixelSize: 13
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: chatList.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: "Appuie sur C et pose une question sur ce dossier.\nAvec un index (I), les fichiers pertinents sont lus pour répondre."
                        color: "#6a6a74"
                    }
                }
            }

            // ---------------------------------------------------------- plan
            ColumnLayout {
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: backend.planRequest || "Plan"
                    color: "#f2f2f5"
                    font.pixelSize: 16
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: backend.planExplanation || "« : » décrit ce que tu veux faire en français (« range les PDF par année », « renomme les photos par date »…).\nS range par type sans IA, Maj+S demande un rangement à l'IA.\nRien ne bouge avant que tu valides avec Ctrl+Entrée."
                    color: backend.planExplanation ? "#d0d0d6" : "#6a6a74"
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                Repeater {
                    model: backend.planSkipped
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        text: "⚠ " + modelData
                        color: "#d9a54a"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
                ListView {
                    id: planList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: backend.planItems
                    spacing: 2
                    delegate: RowLayout {
                        required property var modelData
                        width: ListView.view.width
                        spacing: 8
                        Text {
                            Layout.preferredWidth: 18
                            text: modelData.op === "mkdir" ? "+" : "→"
                            color: theme.accent
                            font.bold: true
                            font.family: "monospace"
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.op === "mkdir"
                                  ? "<b>" + modelData.to + "/</b>"
                                  : modelData.from + "  <font color='#6a6a74'>→</font>  <b>" + modelData.to + "</b>"
                            textFormat: Text.StyledText
                            color: "#d0d0d6"
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                        }
                    }
                }
                RowLayout {
                    visible: planList.count > 0
                    Layout.fillWidth: true
                    Button {
                        text: "Appliquer  (Ctrl+Entrée)"
                        highlighted: true
                        onClicked: backend.applyPlan()
                    }
                    Button {
                        text: "Abandonner  (Échap)"
                        flat: true
                        onClicked: backend.discardPlan()
                    }
                }
            }
        }
    }
}
