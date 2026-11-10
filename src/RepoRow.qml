import QtQuick
import QtQuick.Layouts
import "brands.js" as Brands

// One repository in the GitHub folder: what it is, and whether it's here.
Rectangle {
    id: row
    required property int index
    required property string name
    required property string fullName
    required property string description
    required property string language
    required property bool isPrivate
    required property bool isFork
    required property int stars
    required property string updated
    required property string localPath
    property bool current: false
    property bool focused: false

    signal clicked()
    signal doubleClicked()

    readonly property bool cloned: localPath !== ""

    height: 56
    radius: 8
    color: current ? theme.alpha(theme.highlight, focused ? 0.16 : 0.08)
                   : (mouse.containsMouse ? theme.alpha(theme.text, 0.035) : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 12

        Icon {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 10
            name: row.cloned ? "folder" : "clone"
            color: row.cloned ? theme.highlight : theme.textFaint
            size: 18
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                spacing: 8
                Text {
                    text: row.name
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.maximumWidth: row.width * 0.45
                }
                Icon { visible: row.isPrivate; name: "lock"; size: 12; color: theme.textFaint }
                Icon { visible: row.isFork; name: "fork"; size: 12; color: theme.textFaint }
                Item { Layout.fillWidth: true }
            }
            Text {
                Layout.fillWidth: true
                text: row.description || (row.cloned ? row.localPath.replace(backend.places.length ? backend.places[0].path : "", "~") : "Pas de description")
                color: row.description ? theme.textDim : theme.textFaint
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        RowLayout {
            spacing: 6
            visible: row.language !== ""
            Icon {
                visible: brand !== null
                size: 13
                brand: Brands.forLanguage(row.language)
            }
            Rectangle { visible: !Brands.forLanguage(row.language); width: 8; height: 8; radius: 4; color: theme.languageColor(row.language) }
            Text { text: row.language; color: theme.textDim; font.pixelSize: 12 }
        }
        RowLayout {
            spacing: 4
            visible: row.stars > 0
            Icon { name: "star"; size: 12; color: theme.textFaint }
            Text { text: row.stars; color: theme.textDim; font.pixelSize: 12; font.features: { "tnum": 1 } }
        }
        Text {
            Layout.preferredWidth: 86
            horizontalAlignment: Text.AlignRight
            text: row.updated
            color: theme.textFaint
            font.pixelSize: 12
        }
        Rectangle {
            Layout.preferredWidth: stateLabel.implicitWidth + 16
            Layout.preferredHeight: 22
            radius: 11
            color: row.cloned ? theme.alpha(theme.highlight, 0.14) : "transparent"
            border.color: row.cloned ? "transparent" : theme.line
            Text {
                id: stateLabel
                anchors.centerIn: parent
                text: row.cloned ? "Cloné" : "Cloner"
                color: row.cloned ? theme.highlight : theme.textDim
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.clicked()
        onDoubleClicked: row.doubleClicked()
    }
}
