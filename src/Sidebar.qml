import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Where you can go: the usual places, GitHub as one more folder, and the
// state of the AI engines at the foot.
Rectangle {
    id: bar
    color: theme.sidebar
    property bool compact: false
    signal settingsRequested()

    component NavItem: Rectangle {
        id: item
        property string icon
        property string label
        property string badge: ""
        property bool active: false
        property color iconColor: active ? theme.highlight : theme.textDim
        signal activated()
        Layout.fillWidth: true
        height: 32
        radius: 7
        color: active ? theme.alpha(theme.highlight, 0.14) : (hover.containsMouse ? theme.alpha(theme.text, 0.04) : "transparent")
        ToolTipArea { text: item.label; enabled: bar.compact }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: bar.compact ? (item.width - 16) / 2 : 10
            anchors.rightMargin: 10
            spacing: 10
            Icon { name: item.icon; size: 16; color: item.iconColor }
            Text {
                visible: !bar.compact
                Layout.fillWidth: true
                text: item.label
                color: item.active ? theme.text : theme.textDim
                font.pixelSize: 13
                font.weight: item.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            Text {
                visible: item.badge !== "" && !bar.compact
                text: item.badge
                color: theme.textFaint
                font.pixelSize: 11
                font.features: { "tnum": 1 }
            }
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: item.activated()
        }
    }

    // Names an icon-only item on hover when the sidebar is folded.
    component ToolTipArea: Item {
        property string text
        anchors.fill: parent
        ToolTip.visible: enabled && parent.children.length && hoverProbe.containsMouse
        ToolTip.text: text
        ToolTip.delay: 300
        MouseArea { id: hoverProbe; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    }

    component GroupLabel: Text {
        visible: !bar.compact
        Layout.topMargin: 18
        Layout.bottomMargin: 4
        Layout.leftMargin: 10
        color: theme.textFaint
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: bar.compact ? 8 : 12
        anchors.topMargin: 16
        spacing: 2

        RowLayout {
            Layout.leftMargin: bar.compact ? 8 : 6
            Layout.bottomMargin: bar.compact ? 14 : 6
            spacing: 10
            Logo { size: 28 }
            Text {
                visible: !bar.compact
                text: "flair"
                color: theme.text
                font.pixelSize: 19
                font.weight: Font.Bold
                font.letterSpacing: -0.4
            }
        }

        GroupLabel { text: "Emplacements" }
        Repeater {
            model: backend.places
            delegate: NavItem {
                required property var modelData
                icon: modelData.icon
                label: modelData.label
                active: backend.view === "files" && backend.currentPath === modelData.path
                onActivated: backend.navigate(modelData.path)
            }
        }

        GroupLabel { text: "GitHub" }
        NavItem {
            icon: "github"
            label: github.login !== "" ? github.login : "Mes dépôts"
            badge: github.total > 0 ? github.total : ""
            active: backend.view === "github"
            iconColor: active ? theme.text : theme.textDim
            onActivated: backend.showGitHub()
        }
        NavItem {
            visible: git.isRepo
            icon: "branch"
            label: git.branch + (git.changedCount ? "  ·  " + git.changedCount + " modif." : "")
            onActivated: backend.explainChanges()
        }

        Item { Layout.fillHeight: true }

        // Engines
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: bar.compact ? 18 : 10
            spacing: 7
            Repeater {
                model: [
                    { label: "Modèle local", on: backend.localOnline },
                    { label: "Claude", on: backend.claudeReady },
                    { label: indexer.running ? "Indexation " + indexer.done + "/" + indexer.total
                                             : (indexer.size > 0 ? "Index · " + indexer.size + " fichiers" : "Pas d'index"),
                      on: indexer.size > 0 }
                ]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 8
                    Rectangle {
                        width: 7; height: 7; radius: 3.5
                        color: modelData.on ? theme.success : "transparent"
                        border.color: modelData.on ? theme.success : theme.textFaint
                        border.width: 1
                    }
                    Text {
                        visible: !bar.compact
                        text: modelData.label
                        color: modelData.on ? theme.textDim : theme.textFaint
                        font.pixelSize: 12
                    }
                }
            }
        }
        NavItem {
            Layout.topMargin: 10
            icon: "sliders"
            label: "Réglages"
            onActivated: bar.settingsRequested()
        }
    }

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: theme.line
    }
}
