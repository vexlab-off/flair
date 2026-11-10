import QtQuick
import QtQuick.Layouts
import "brands.js" as Brands

Rectangle {
    id: row
    required property int index
    required property string name
    required property string path
    required property bool isDir
    required property string size
    required property string modified
    required property string kind
    required property string git
    property bool current: false
    property bool focused: false

    signal clicked()
    signal doubleClicked()
    signal contextRequested(real x, real y)

    readonly property var iconFor: ({ dossier: "folder", autre: "file" })
    readonly property color gitColor: git === "M" || git === "R" ? theme.warning
                                    : git === "A" ? theme.success
                                    : git === "D" ? theme.danger
                                    : git === "•" ? theme.highlight : theme.textFaint

    height: 34
    radius: 7
    color: current ? theme.alpha(theme.highlight, focused ? 0.16 : 0.08)
                   : (mouse.containsMouse ? theme.alpha(theme.text, 0.035) : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 12

        Icon {
            name: row.iconFor[row.kind] || row.kind
            brand: row.isDir ? null : Brands.forFile(row.name)
            color: theme.kindColor(row.kind)
            size: brand ? 16 : 17
            Layout.preferredWidth: 17
        }
        Text {
            Layout.fillWidth: true
            text: row.name
            color: row.current ? theme.text : (row.isDir ? theme.text : Qt.tint(theme.text, theme.alpha(theme.background, 0.15)))
            font.pixelSize: 13
            font.weight: row.isDir ? Font.DemiBold : Font.Normal
            elide: Text.ElideMiddle
        }
        Rectangle {
            visible: row.git !== ""
            Layout.preferredWidth: 18
            Layout.preferredHeight: 16
            radius: 4
            color: theme.alpha(row.gitColor, 0.14)
            Text {
                anchors.centerIn: parent
                text: row.git
                color: row.gitColor
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }
        Text {
            Layout.preferredWidth: 76
            horizontalAlignment: Text.AlignRight
            text: row.size
            color: theme.textDim
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }
        Text {
            Layout.preferredWidth: 128
            horizontalAlignment: Text.AlignRight
            text: row.modified
            color: theme.textFaint
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            row.clicked()
            if (mouse.button === Qt.RightButton) row.contextRequested(mouse.x, mouse.y)
        }
        onDoubleClicked: row.doubleClicked()
    }
}
