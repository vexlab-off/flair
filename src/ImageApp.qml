import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Flair Image: the pictures of a folder, one at a time, with zoom, rotation,
// a slideshow and a strip of thumbnails. Never edits a file.
ApplicationWindow {
    id: win
    width: 1280
    height: 860
    minimumWidth: 640
    minimumHeight: 420
    visible: true
    title: (folder.name || "Flair Image") + " — Flair Image"
    color: theme.isDark ? "#0b0b0d" : theme.background

    Material.theme: theme.isDark ? Material.Dark : Material.Light
    Material.accent: theme.highlight

    property real zoom: 1          // relative to "fit"; 1 = fitted
    property bool actualSize: false
    property int viewRotation: 0
    property bool slideshow: false
    property bool infoVisible: false
    property bool chromeVisible: true
    readonly property bool fullscreen: visibility === Window.FullScreen

    function resetView() { zoom = 1; actualSize = false; viewRotation = 0; flick.contentX = 0; flick.contentY = 0 }
    function zoomBy(factor) { actualSize = false; zoom = Math.max(0.1, Math.min(20, zoom * factor)) }
    function toggleFullscreen() { visibility = fullscreen ? Window.Windowed : Window.FullScreen }

    Connections { target: folder; function onChanged() { win.resetView() } }

    Timer {
        interval: 3500
        repeat: true
        running: win.slideshow
        onTriggered: folder.next()
    }

    Shortcut { sequences: ["Right", "PgDown", "Space"]; onActivated: { if (win.slideshow) win.slideshow = false; folder.next() } }
    Shortcut { sequences: ["Left", "PgUp", "Backspace"]; onActivated: folder.previous() }
    Shortcut { sequence: "Home"; onActivated: folder.go(0) }
    Shortcut { sequence: "End"; onActivated: folder.go(folder.count - 1) }
    Shortcut { sequences: ["+", "=", "Ctrl+="]; onActivated: win.zoomBy(1.25) }
    Shortcut { sequences: ["-", "Ctrl+-"]; onActivated: win.zoomBy(0.8) }
    Shortcut { sequence: "0"; onActivated: win.resetView() }
    Shortcut { sequence: "1"; onActivated: { win.zoom = 1; win.actualSize = true } }
    Shortcut { sequence: "R"; onActivated: win.viewRotation = (win.viewRotation + 90) % 360 }
    Shortcut { sequence: "Shift+R"; onActivated: win.viewRotation = (win.viewRotation + 270) % 360 }
    Shortcut { sequences: ["F", "F11"]; onActivated: win.toggleFullscreen() }
    Shortcut { sequence: "S"; onActivated: win.slideshow = !win.slideshow }
    Shortcut { sequence: "I"; onActivated: win.infoVisible = !win.infoVisible }
    Shortcut { sequence: "H"; onActivated: win.chromeVisible = !win.chromeVisible }
    Shortcut { sequence: "Del"; onActivated: confirmTrash.open() }
    Shortcut { sequence: "Ctrl+C"; onActivated: folder.copyPath() }
    Shortcut { sequence: "E"; onActivated: folder.revealInFlair() }
    Shortcut { sequence: "?"; onActivated: help.visible = !help.visible }
    Shortcut { sequence: "Q"; onActivated: Qt.quit() }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (help.visible) help.visible = false
            else if (win.slideshow) win.slideshow = false
            else if (win.fullscreen) win.visibility = Window.Windowed
            else Qt.quit()
        }
    }

    // ------------------------------------------------------------ picture
    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: win.chromeVisible && !win.fullscreen ? top.height : 0
        anchors.bottomMargin: win.chromeVisible && !win.fullscreen ? strip.height : 0
        anchors.rightMargin: win.infoVisible ? info.width : 0
        clip: true
        contentWidth: Math.max(width, holder.width)
        contentHeight: Math.max(height, holder.height)
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { visible: win.zoom > 1 || win.actualSize }
        ScrollBar.horizontal: ScrollBar { visible: win.zoom > 1 || win.actualSize }

        readonly property bool sideways: win.viewRotation % 180 !== 0
        readonly property real naturalW: sideways ? picture.implicitHeight : picture.implicitWidth
        readonly property real naturalH: sideways ? picture.implicitWidth : picture.implicitHeight
        readonly property real fit: naturalW > 0 ? Math.min(1, Math.min((width - 40) / naturalW, (height - 40) / naturalH)) : 1
        readonly property real scale: win.actualSize ? 1 : fit * win.zoom

        Item {
            id: holder
            width: flick.naturalW * flick.scale
            height: flick.naturalH * flick.scale
            x: Math.max(0, (flick.width - width) / 2)
            y: Math.max(0, (flick.height - height) / 2)
            Image {
                id: picture
                anchors.centerIn: parent
                width: implicitWidth * flick.scale
                height: implicitHeight * flick.scale
                rotation: win.viewRotation
                source: folder.path ? "file://" + folder.path.split("/").map(encodeURIComponent).join("/") : ""
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
                autoTransform: true
                Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
        }

        // Wheel zooms around the picture; with Ctrl or not, it's what people expect from a viewer.
        WheelHandler {
            onWheel: (event) => win.zoomBy(event.angleDelta.y > 0 ? 1.12 : 1 / 1.12)
        }
        TapHandler {
            onDoubleTapped: win.toggleFullscreen()
        }
    }

    BusyIndicator { anchors.centerIn: flick; running: picture.status === Image.Loading }
    Text {
        anchors.centerIn: flick
        visible: picture.status === Image.Error || folder.count === 0
        text: folder.count === 0 ? folder.message : "Cette image ne peut pas s'afficher."
        color: theme.textDim
        font.pixelSize: 14
    }

    // Previous / next arrows on the sides
    Repeater {
        model: [-1, 1]
        delegate: Rectangle {
            required property int modelData
            visible: folder.count > 1 && arrowHover.containsMouse
            anchors.verticalCenter: flick.verticalCenter
            x: modelData < 0 ? 16 : flick.width - width - 16
            width: 44; height: 44; radius: 22
            color: theme.alpha(theme.isDark ? "#000000" : "#ffffff", 0.55)
            Icon { anchors.centerIn: parent; name: "chevron"; rotation: modelData < 0 ? 180 : 0; size: 20; color: theme.text }
            MouseArea { anchors.fill: parent; onClicked: modelData < 0 ? folder.previous() : folder.next() }
        }
    }
    MouseArea { id: arrowHover; anchors.fill: flick; hoverEnabled: true; acceptedButtons: Qt.NoButton }

    // ------------------------------------------------------------ top bar
    Rectangle {
        id: top
        visible: win.chromeVisible && !win.fullscreen
        width: parent.width
        height: 50
        color: theme.isDark ? "#121214" : theme.sidebar
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: theme.line }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 6
            AppMark { app: "flair-image"; size: 26 }
            Text { text: "Flair Image"; color: theme.text; font.pixelSize: 14; font.weight: Font.Bold; Layout.rightMargin: 10 }
            Text {
                Layout.fillWidth: true
                text: folder.name + (folder.count > 1 ? "   " + (folder.index + 1) + " / " + folder.count : "")
                color: theme.textDim
                font.pixelSize: 13
                elide: Text.ElideMiddle
            }
            Text {
                visible: picture.status === Image.Ready
                text: picture.sourceSize.width + " × " + picture.sourceSize.height + "  ·  " + Math.round(flick.scale * 100) + " %"
                color: theme.textFaint
                font.pixelSize: 12
                font.features: { "tnum": 1 }
                Layout.rightMargin: 8
            }
            ToolButton2 { icon: "minus"; tip: "Zoom arrière (-)"; onClicked: win.zoomBy(0.8) }
            ToolButton2 { icon: "plus"; tip: "Zoom avant (+)"; onClicked: win.zoomBy(1.25) }
            ToolButton2 { icon: "expand"; tip: "Ajuster (0) · taille réelle (1)"; active: win.actualSize; onClicked: win.actualSize ? win.resetView() : (win.actualSize = true) }
            ToolButton2 { icon: "refresh"; tip: "Pivoter (R, Maj+R)"; onClicked: win.viewRotation = (win.viewRotation + 90) % 360 }
            ToolButton2 { icon: "play"; tip: "Diaporama (S)"; active: win.slideshow; onClicked: win.slideshow = !win.slideshow }
            ToolButton2 { icon: "info"; tip: "Informations (I)"; active: win.infoVisible; onClicked: win.infoVisible = !win.infoVisible }
            ToolButton2 { icon: "folder"; tip: "Ouvrir le dossier dans flair (E)"; onClicked: folder.revealInFlair() }
            ToolButton2 { icon: "trash"; tip: "Mettre à la corbeille (Suppr)"; onClicked: confirmTrash.open() }
            ToolButton2 { icon: "expand"; tip: "Plein écran (F)"; onClicked: win.toggleFullscreen() }
        }
    }

    // ------------------------------------------------------------ thumbnails
    Rectangle {
        id: strip
        visible: win.chromeVisible && !win.fullscreen && folder.count > 1
        anchors.bottom: parent.bottom
        width: parent.width
        height: visible ? 86 : 0
        color: theme.isDark ? "#121214" : theme.sidebar
        Rectangle { width: parent.width; height: 1; color: theme.line }
        ListView {
            id: thumbs
            anchors.fill: parent
            anchors.margins: 10
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            model: folder.files
            currentIndex: folder.index
            highlightMoveDuration: 200
            preferredHighlightBegin: width / 2 - 40
            preferredHighlightEnd: width / 2 + 40
            highlightRangeMode: ListView.ApplyRange
            delegate: Rectangle {
                required property string modelData
                required property int index
                readonly property bool current: index === folder.index
                width: 80; height: 64; radius: 6
                color: theme.surface
                border.color: current ? theme.highlight : "transparent"
                border.width: 2
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    fillMode: Image.PreserveAspectCrop
                    source: "file://" + modelData.split("/").map(encodeURIComponent).join("/")
                    sourceSize: Qt.size(160, 128)
                    asynchronous: true
                    opacity: parent.current ? 1 : 0.7
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: folder.go(index) }
            }
        }
    }

    // ------------------------------------------------------------ info
    Rectangle {
        id: info
        visible: win.infoVisible
        anchors.right: parent.right
        anchors.top: top.visible ? top.bottom : parent.top
        anchors.bottom: strip.visible ? strip.top : parent.bottom
        width: 280
        color: theme.surface
        Rectangle { width: 1; height: parent.height; color: theme.line }
        readonly property var details: (folder.index, folder.path, folder.info())
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Text { text: "Informations"; color: theme.text; font.pixelSize: 15; font.weight: Font.Bold }
            Repeater {
                model: [["Nom", info.details.name], ["Dimensions", picture.sourceSize.width + " × " + picture.sourceSize.height + " px"],
                        ["Taille", info.details.size], ["Format", info.details.type], ["Modifiée", info.details.modified], ["Dossier", info.details.folder]]
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: modelData[0]; color: theme.textFaint; font.pixelSize: 11 }
                    Text { Layout.fillWidth: true; text: modelData[1] || ""; color: theme.text; font.pixelSize: 13; wrapMode: Text.WrapAnywhere }
                }
            }
            Item { Layout.fillHeight: true }
            Button { text: "Copier le chemin"; flat: true; onClicked: folder.copyPath() }
            Button { text: "Ouvrir avec une autre application"; flat: true; onClicked: folder.openWithSystem() }
        }
    }

    // Status message
    Rectangle {
        visible: folder.message !== "" && messageTimer.running
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: strip.height + 16
        width: messageText.implicitWidth + 28
        height: 34
        radius: 17
        color: theme.surface
        border.color: theme.line
        Text { id: messageText; anchors.centerIn: parent; text: folder.message; color: theme.text; font.pixelSize: 12 }
        Timer { id: messageTimer; interval: 3000 }
        Connections { target: folder; function onMessageChanged() { messageTimer.restart() } }
    }

    Dialog {
        id: confirmTrash
        modal: true
        anchors.centerIn: parent
        title: "Mettre « " + folder.name + " » à la corbeille ?"
        standardButtons: Dialog.Yes | Dialog.Cancel
        background: Rectangle { color: theme.surface; radius: 12; border.color: theme.line }
        Text { text: "Tu pourras la récupérer depuis la corbeille du système."; color: theme.textDim }
        onAccepted: folder.trashCurrent()
    }

    // ------------------------------------------------------------ help
    Rectangle {
        id: help
        visible: false
        anchors.fill: parent
        color: theme.alpha(theme.background, 0.9)
        MouseArea { anchors.fill: parent; onClicked: help.visible = false }
        Rectangle {
            anchors.centerIn: parent
            width: helpGrid.implicitWidth + 56
            height: helpGrid.implicitHeight + 56
            radius: 14
            color: theme.surface
            border.color: theme.line
            GridLayout {
                id: helpGrid
                anchors.centerIn: parent
                columns: 2
                columnSpacing: 20
                rowSpacing: 8
                Repeater {
                    model: [["← →  ·  Espace", "Image précédente / suivante"], ["Début  ·  Fin", "Première / dernière"], ["+  ·  -  ·  molette", "Zoom"],
                            ["0  ·  1", "Ajuster  ·  taille réelle"], ["R  ·  Maj+R", "Pivoter (affichage seulement)"], ["S", "Diaporama"],
                            ["F  ·  double-clic", "Plein écran"], ["I", "Informations"], ["H", "Masquer les barres"], ["E", "Ouvrir le dossier dans flair"],
                            ["Suppr", "Mettre à la corbeille"], ["Ctrl+C", "Copier le chemin"], ["Échap  ·  Q", "Quitter"]]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.columnSpan: 2
                        spacing: 16
                        Item { Layout.preferredWidth: 150; Layout.preferredHeight: 20; Keycap { anchors.verticalCenter: parent.verticalCenter; text: modelData[0] } }
                        Text { text: modelData[1]; color: theme.textDim; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    component ToolButton2: Rectangle {
        id: tb
        property string icon
        property string tip
        property bool active: false
        signal clicked()
        width: 32; height: 32; radius: 8
        color: active ? theme.alpha(theme.highlight, 0.16) : (tbHover.containsMouse ? theme.raised : "transparent")
        Icon { anchors.centerIn: parent; name: tb.icon; size: 16; color: tb.active ? theme.highlight : theme.textDim }
        ToolTip.visible: tbHover.containsMouse
        ToolTip.text: tb.tip
        ToolTip.delay: 400
        MouseArea { id: tbHover; anchors.fill: parent; hoverEnabled: true; onClicked: tb.clicked() }
    }
}
