import QtQuick
import QtQuick.Layouts

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

    signal clicked()
    signal doubleClicked()

    height: 30
    radius: 6
    color: current ? Qt.rgba(1, 1, 1, 0.08) : (mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

    Rectangle {
        visible: row.current
        width: 3
        height: parent.height - 10
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        color: theme.accent
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10

        KindBadge { kind: row.kind }

        Text {
            Layout.fillWidth: true
            text: row.name
            color: row.isDir ? "#f2f2f5" : "#d0d0d6"
            font.pixelSize: 13
            font.bold: row.isDir
            elide: Text.ElideMiddle
        }
        Text {
            visible: row.git !== ""
            text: row.git
            color: row.git === "?" ? "#7a7a85" : theme.accent
            font.pixelSize: 12
            font.family: "monospace"
            font.bold: true
        }
        Text {
            Layout.preferredWidth: 70
            horizontalAlignment: Text.AlignRight
            text: row.size
            color: "#7a7a85"
            font.pixelSize: 12
        }
        Text {
            Layout.preferredWidth: 130
            horizontalAlignment: Text.AlignRight
            text: row.modified
            color: "#5e5e68"
            font.pixelSize: 12
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
