import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtMultimedia

// Flair Vidéo: plays the videos and songs of a folder in order, keyboard
// first, with the controls fading away while it plays.
ApplicationWindow {
    id: win
    width: 1280
    height: 780
    minimumWidth: 560
    minimumHeight: 360
    visible: true
    title: (folder.name || "Flair Vidéo") + " — Flair Vidéo"
    color: "black"

    Material.theme: theme.isDark ? Material.Dark : Material.Light
    Material.accent: theme.highlight

    readonly property bool fullscreen: visibility === Window.FullScreen
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState
    readonly property bool isAudio: /\.(mp3|flac|ogg|opus|wav|m4a|aac|wma)$/i.test(folder.path)
    property string loop: "none" // none, one, all
    property bool playlistVisible: false
    property bool controlsVisible: true

    function toggle() { playing ? player.pause() : player.play() }
    function seek(ms) { player.position = Math.max(0, Math.min(player.duration, player.position + ms)) }
    function toggleFullscreen() { visibility = fullscreen ? Window.Windowed : Window.FullScreen }
    function showControls() { controlsVisible = true; hideTimer.restart() }
    function format(ms) {
        const s = Math.floor(ms / 1000), m = Math.floor(s / 60), h = Math.floor(m / 60)
        const pad = n => (n < 10 ? "0" : "") + n
        return h > 0 ? h + ":" + pad(m % 60) + ":" + pad(s % 60) : m + ":" + pad(s % 60)
    }
    function tag(key) { const v = player.metaData.value(key); return v === undefined || v === null ? "" : String(v) }

    Connections {
        target: folder
        function onChanged() { Qt.callLater(() => player.play()) }
    }
    Component.onCompleted: player.play()

    MediaPlayer {
        id: player
        source: folder.path ? "file://" + folder.path.split("/").map(encodeURIComponent).join("/") : ""
        audioOutput: AudioOutput { id: audio; volume: 0.8 }
        videoOutput: video
        loops: win.loop === "one" ? MediaPlayer.Infinite : 1
        onMediaStatusChanged: {
            // At the end, the next file of the folder (or the first, looping all).
            if (mediaStatus === MediaPlayer.EndOfMedia && win.loop !== "one") {
                if (folder.index < folder.count - 1) folder.next()
                else if (win.loop === "all") folder.go(0)
            }
        }
    }

    Timer { id: hideTimer; interval: 2600; onTriggered: if (win.playing && !playlistVisible) win.controlsVisible = false }

    Shortcut { sequences: ["Space", "K"]; onActivated: { win.toggle(); win.showControls() } }
    Shortcut { sequence: "Right"; onActivated: { win.seek(5000); win.showControls() } }
    Shortcut { sequence: "Left"; onActivated: { win.seek(-5000); win.showControls() } }
    Shortcut { sequence: "L"; onActivated: { win.seek(10000); win.showControls() } }
    Shortcut { sequence: "J"; onActivated: { win.seek(-10000); win.showControls() } }
    Shortcut { sequence: "Up"; onActivated: { audio.volume = Math.min(1, audio.volume + 0.05); win.showControls() } }
    Shortcut { sequence: "Down"; onActivated: { audio.volume = Math.max(0, audio.volume - 0.05); win.showControls() } }
    Shortcut { sequence: "M"; onActivated: { audio.muted = !audio.muted; win.showControls() } }
    Shortcut { sequences: ["F", "F11"]; onActivated: win.toggleFullscreen() }
    Shortcut { sequences: ["N", "PgDown"]; onActivated: folder.next() }
    Shortcut { sequences: ["P", "PgUp"]; onActivated: folder.previous() }
    Shortcut { sequence: "]"; onActivated: { player.playbackRate = Math.min(3, player.playbackRate + 0.25); win.showControls() } }
    Shortcut { sequence: "["; onActivated: { player.playbackRate = Math.max(0.25, player.playbackRate - 0.25); win.showControls() } }
    Shortcut { sequence: "Backspace"; onActivated: { player.playbackRate = 1; win.showControls() } }
    Shortcut { sequence: "B"; onActivated: { win.loop = win.loop === "none" ? "one" : win.loop === "one" ? "all" : "none"; win.showControls() } }
    Shortcut { sequence: "Tab"; onActivated: win.playlistVisible = !win.playlistVisible }
    Shortcut { sequence: "E"; onActivated: folder.revealInFlair() }
    Shortcut { sequence: "?"; onActivated: help.visible = !help.visible }
    Shortcut { sequence: "Q"; onActivated: Qt.quit() }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (help.visible) help.visible = false
            else if (win.fullscreen) win.visibility = Window.Windowed
            else Qt.quit()
        }
    }
    // 0–9 jump to that tenth of the file.
    Repeater {
        model: 10
        delegate: Item {
            required property int index
            Shortcut { sequence: String(index); onActivated: player.position = player.duration * index / 10 }
        }
    }

    // ------------------------------------------------------------ picture
    VideoOutput {
        id: video
        anchors.fill: parent
        anchors.rightMargin: win.playlistVisible ? playlist.width : 0
        fillMode: VideoOutput.PreserveAspectFit
        visible: !win.isAudio
    }

    // A song: what it is, big
    Rectangle {
        visible: win.isAudio
        anchors.fill: video
        color: theme.background
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 520)
            spacing: 14
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 220
                Layout.preferredHeight: 220
                radius: 24
                color: theme.alpha(theme.highlight, 0.16)
                Icon { anchors.centerIn: parent; name: "audio"; size: 100; stroke: 1; color: theme.highlight }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: win.tag(MediaMetaData.Title) || folder.name
                color: theme.text
                font.pixelSize: 24
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: [win.tag(MediaMetaData.ContributingArtist) || win.tag(MediaMetaData.AlbumArtist), win.tag(MediaMetaData.AlbumTitle), win.tag(MediaMetaData.Genre)].filter(t => t).join("  ·  ")
                color: theme.textDim
                font.pixelSize: 14
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: video
        hoverEnabled: true
        onPositionChanged: win.showControls()
        onClicked: { win.toggle(); win.showControls() }
        onDoubleClicked: win.toggleFullscreen()
        cursorShape: win.controlsVisible ? Qt.ArrowCursor : Qt.BlankCursor
    }

    Text {
        anchors.centerIn: video
        visible: player.error !== MediaPlayer.NoError || folder.count === 0
        text: folder.count === 0 ? folder.message : "Lecture impossible : " + player.errorString
        color: "white"
        font.pixelSize: 14
    }

    // ------------------------------------------------------------ top title
    Rectangle {
        anchors.top: parent.top
        width: video.width
        height: 56
        opacity: win.controlsVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.6) }
            GradientStop { position: 1; color: "transparent" }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 10
            AppMark { app: "flair-video"; size: 24 }
            Text {
                Layout.fillWidth: true
                text: folder.name + (folder.count > 1 ? "   " + (folder.index + 1) + " / " + folder.count : "")
                color: "white"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
            }
        }
    }

    // ------------------------------------------------------------ controls
    Rectangle {
        id: controls
        anchors.bottom: parent.bottom
        width: video.width
        height: 96
        opacity: win.controlsVisible || !win.playing ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.75) }
        }
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 14
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: win.format(player.position); color: "white"; font.pixelSize: 12; font.features: { "tnum": 1 } }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, player.duration)
                    value: player.position
                    Material.accent: theme.highlight
                    onMoved: player.position = value
                }
                Text { text: win.format(player.duration); color: "white"; font.pixelSize: 12; font.features: { "tnum": 1 } }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Control2 { icon: "chevron"; flip: true; tip: "Précédent (P)"; onClicked: folder.previous() }
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: theme.highlight
                    Icon { anchors.centerIn: parent; anchors.horizontalCenterOffset: win.playing ? 0 : 2; name: win.playing ? "pause" : "play"; size: 18; stroke: 2; color: theme.highlightText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.toggle() }
                }
                Control2 { icon: "chevron"; tip: "Suivant (N)"; onClicked: folder.next() }
                Control2 { icon: "audio"; tip: audio.muted ? "Remettre le son (M)" : "Couper le son (M)"; active: audio.muted; onClicked: audio.muted = !audio.muted }
                Slider {
                    Layout.preferredWidth: 100
                    from: 0; to: 1
                    value: audio.volume
                    Material.accent: theme.highlight
                    onMoved: audio.volume = value
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (player.playbackRate !== 1 ? "×" + player.playbackRate + "   " : "") + (win.loop === "one" ? "Boucle : ce fichier" : win.loop === "all" ? "Boucle : tout le dossier" : "")
                    color: "white"
                    font.pixelSize: 12
                }
                Control2 { icon: "refresh"; tip: "Boucle (B)"; active: win.loop !== "none"; onClicked: win.loop = win.loop === "none" ? "one" : win.loop === "one" ? "all" : "none" }
                Control2 { icon: "plan"; tip: "Liste de lecture (Tab)"; active: win.playlistVisible; onClicked: win.playlistVisible = !win.playlistVisible }
                Control2 { icon: "info"; tip: "Raccourcis (?)"; onClicked: help.visible = true }
                Control2 { icon: "expand"; tip: "Plein écran (F)"; onClicked: win.toggleFullscreen() }
            }
        }
    }

    // ------------------------------------------------------------ playlist
    Rectangle {
        id: playlist
        visible: win.playlistVisible
        anchors.right: parent.right
        width: 300
        height: parent.height
        color: theme.surface
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            Text { text: "Dans ce dossier"; color: theme.text; font.pixelSize: 14; font.weight: Font.Bold }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: folder.files
                spacing: 2
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    readonly property bool current: index === folder.index
                    width: ListView.view.width
                    height: 38
                    radius: 7
                    color: current ? theme.alpha(theme.highlight, 0.16) : (rowHover.containsMouse ? theme.raised : "transparent")
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        Icon { name: /\.(mp3|flac|ogg|opus|wav|m4a|aac|wma)$/i.test(modelData) ? "audio" : "video"; size: 14; color: parent.parent.current ? theme.highlight : theme.textDim }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.substring(modelData.lastIndexOf("/") + 1)
                            color: theme.text
                            font.pixelSize: 12
                            font.weight: parent.parent.current ? Font.DemiBold : Font.Normal
                            elide: Text.ElideMiddle
                        }
                    }
                    MouseArea { id: rowHover; anchors.fill: parent; hoverEnabled: true; onClicked: folder.go(index) }
                }
            }
        }
    }

    // ------------------------------------------------------------ help
    Rectangle {
        id: help
        visible: false
        anchors.fill: parent
        color: theme.alpha(theme.background, 0.92)
        MouseArea { anchors.fill: parent; onClicked: help.visible = false }
        Rectangle {
            anchors.centerIn: parent
            width: helpColumn.implicitWidth + 56
            height: helpColumn.implicitHeight + 56
            radius: 14
            color: theme.surface
            border.color: theme.line
            ColumnLayout {
                id: helpColumn
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: [["Espace  ·  K  ·  clic", "Lecture / pause"], ["←  ·  →", "Reculer / avancer de 5 s"], ["J  ·  L", "Reculer / avancer de 10 s"],
                            ["0 … 9", "Aller à 0 %, 10 % … 90 %"], ["↑  ·  ↓", "Volume"], ["M", "Couper le son"], ["[  ·  ]  ·  Retour", "Vitesse  ·  vitesse normale"],
                            ["N  ·  P", "Fichier suivant / précédent"], ["B", "Boucle : aucune, ce fichier, tout le dossier"], ["Tab", "Liste de lecture"],
                            ["F  ·  double-clic", "Plein écran"], ["E", "Ouvrir le dossier dans flair"], ["Échap  ·  Q", "Quitter"]]
                    delegate: RowLayout {
                        required property var modelData
                        spacing: 16
                        Item { Layout.preferredWidth: 160; Layout.preferredHeight: 20; Keycap { anchors.verticalCenter: parent.verticalCenter; text: modelData[0] } }
                        Text { text: modelData[1]; color: theme.textDim; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    component Control2: Rectangle {
        id: c
        property string icon
        property string tip
        property bool active: false
        property bool flip: false
        signal clicked()
        width: 34; height: 34; radius: 8
        color: active ? theme.alpha(theme.highlight, 0.3) : (cHover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
        Icon { anchors.centerIn: parent; name: c.icon; size: 16; rotation: c.flip ? 180 : 0; color: c.active ? theme.highlight : "white" }
        ToolTip.visible: cHover.containsMouse
        ToolTip.text: c.tip
        ToolTip.delay: 400
        MouseArea { id: cHover; anchors.fill: parent; hoverEnabled: true; onClicked: c.clicked() }
    }
}
