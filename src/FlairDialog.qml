import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// The frame every small dialog shares: icon and title, a body, and actions.
Popup {
    id: dialog
    property string icon: "sparkle"
    property string title
    property string subtitle
    property string acceptText: "Valider"
    property bool acceptEnabled: true
    property bool working: false
    default property alias body: content.data
    signal accepted()

    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    // Sized from the window's overlay, not the parent, which may be a zero-size holder.
    width: Math.min(Overlay.overlay ? Overlay.overlay.width - 60 : 520, 520)
    padding: 0
    closePolicy: working ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
    Overlay.modal: Rectangle { color: theme.alpha(theme.background, 0.7) }
    background: Rectangle { color: theme.surface; radius: 14; border.color: theme.line }

    contentItem: ColumnLayout {
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            Layout.bottomMargin: 14
            spacing: 12
            Rectangle {
                width: 32; height: 32; radius: 9
                color: theme.alpha(theme.highlight, 0.14)
                Icon { anchors.centerIn: parent; name: dialog.icon; size: 17; color: theme.highlight }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: dialog.title; color: theme.text; font.pixelSize: 16; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideMiddle }
                Text {
                    visible: text !== ""
                    Layout.fillWidth: true
                    text: dialog.subtitle
                    color: theme.textDim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }
        }
        ColumnLayout {
            id: content
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 12
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 18
            spacing: 8
            BusyIndicator { visible: dialog.working; running: visible; Layout.preferredWidth: 26; Layout.preferredHeight: 26 }
            Item { Layout.fillWidth: true }
            Button { text: "Annuler"; flat: true; enabled: !dialog.working; onClicked: dialog.close() }
            Button {
                text: dialog.acceptText
                highlighted: true
                Material.accent: theme.highlight
                enabled: dialog.acceptEnabled && !dialog.working
                onClicked: dialog.accepted()
            }
        }
    }
}
