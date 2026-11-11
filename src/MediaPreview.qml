import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtMultimedia

// Pictures, songs and videos in the preview: the picture on a checkerboard,
// a player with its controls, and what the file's tags say about it.
Item {
    id: media
    property string path
    property string kind // image, audio, video
    readonly property url source: path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : ""
    readonly property bool playable: kind === "audio" || kind === "video"

    function format(ms) {
        const s = Math.floor(ms / 1000)
        const m = Math.floor(s / 60)
        const h = Math.floor(m / 60)
        const pad = n => (n < 10 ? "0" : "") + n
        return h > 0 ? h + ":" + pad(m % 60) + ":" + pad(s % 60) : m + ":" + pad(s % 60)
    }
    function tag(key) {
        const value = player.metaData.value(key)
        return value === undefined || value === null ? "" : String(value)
    }

    // A new file stops whatever was playing.
    onPathChanged: player.stop()
    Component.onDestruction: player.stop()

    MediaPlayer {
        id: player
        source: media.playable ? media.source : ""
        audioOutput: AudioOutput { id: audio; volume: volumeSlider.value }
        videoOutput: video
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ---------------------------------------------- picture
        Rectangle {
            visible: media.kind === "image"
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            clip: true
            color: theme.surface
            Canvas {
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d")
                    for (let y = 0; y < height; y += 10)
                        for (let x = 0; x < width; x += 10) {
                            ctx.fillStyle = ((x + y) / 10) % 2 === 0 ? theme.raised : theme.surface
                            ctx.fillRect(x, y, 10, 10)
                        }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
            Image {
                id: picture
                anchors.fill: parent
                anchors.margins: 8
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                source: media.kind === "image" ? media.source : ""
            }
            BusyIndicator { anchors.centerIn: parent; running: picture.status === Image.Loading }
            Text {
                anchors.centerIn: parent
                visible: picture.status === Image.Error
                text: "Ce format d'image ne peut pas s'afficher ici."
                color: theme.textDim
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                visible: media.kind === "image" && picture.status === Image.Ready
                text: picture.sourceSize.width + " × " + picture.sourceSize.height + " px"
                color: theme.textDim
                font.pixelSize: 12
                font.features: { "tnum": 1 }
            }
            Item { Layout.fillWidth: true; visible: media.kind !== "image" }
            Button {
                text: media.kind === "image" ? "Ouvrir dans Flair Image" : "Ouvrir dans Flair Vidéo"
                flat: true
                onClicked: { player.pause(); backend.openInViewer(media.path) }
            }
        }
        Text {
            visible: false
            text: picture.sourceSize.width + " × " + picture.sourceSize.height + " px"
            color: theme.textDim
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }

        // ---------------------------------------------- video
        Rectangle {
            visible: media.kind === "video"
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            clip: true
            color: "black"
            VideoOutput {
                id: video
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
            }
            // Click the picture to play or pause.
            MouseArea { anchors.fill: parent; onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play() }
            Rectangle {
                visible: player.playbackState !== MediaPlayer.PlayingState
                anchors.centerIn: parent
                width: 64; height: 64; radius: 32
                color: theme.alpha(theme.highlight, 0.9)
                Icon { anchors.centerIn: parent; anchors.horizontalCenterOffset: 3; name: "play"; size: 26; color: theme.highlightText; stroke: 2 }
            }
        }

        // ---------------------------------------------- audio
        Rectangle {
            visible: media.kind === "audio"
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            radius: 10
            color: theme.alpha(theme.highlight, 0.1)
            border.color: theme.line
            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 18
                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    radius: 12
                    color: theme.alpha(theme.highlight, 0.18)
                    Icon { anchors.centerIn: parent; name: "audio"; size: 56; stroke: 1.2; color: theme.highlight }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        Layout.fillWidth: true
                        text: media.tag(MediaMetaData.Title) || media.path.substring(media.path.lastIndexOf("/") + 1)
                        color: theme.text
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: media.tag(MediaMetaData.ContributingArtist) || media.tag(MediaMetaData.AlbumArtist) || "Artiste inconnu"
                        color: theme.textDim
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: [media.tag(MediaMetaData.AlbumTitle), media.tag(MediaMetaData.Genre), media.tag(MediaMetaData.Date).substring(0, 4)].filter(t => t).join("  ·  ")
                        color: theme.textFaint
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // ---------------------------------------------- transport
        RowLayout {
            visible: media.playable
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                width: 34; height: 34; radius: 17
                color: theme.highlight
                Icon {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: player.playbackState === MediaPlayer.PlayingState ? 0 : 1
                    name: player.playbackState === MediaPlayer.PlayingState ? "pause" : "play"
                    size: 15
                    stroke: 2
                    color: theme.highlightText
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play() }
            }
            Text { text: media.format(player.position); color: theme.textDim; font.pixelSize: 11; font.features: { "tnum": 1 } }
            Slider {
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, player.duration)
                value: player.position
                Material.accent: theme.highlight
                onMoved: player.position = value
            }
            Text { text: media.format(player.duration); color: theme.textDim; font.pixelSize: 11; font.features: { "tnum": 1 } }
            Icon { name: "audio"; size: 14; color: theme.textFaint }
            Slider {
                id: volumeSlider
                Layout.preferredWidth: 80
                from: 0; to: 1; value: 0.8
                Material.accent: theme.highlight
            }
        }
        Text {
            visible: media.playable && player.error !== MediaPlayer.NoError
            Layout.fillWidth: true
            text: "Lecture impossible : " + player.errorString
            color: theme.danger
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        Text {
            visible: media.kind === "video" && player.metaData.value(MediaMetaData.Resolution) !== undefined
            text: {
                const r = player.metaData.value(MediaMetaData.Resolution)
                return r ? r.width + " × " + r.height + " px  ·  " + media.format(player.duration) : ""
            }
            color: theme.textDim
            font.pixelSize: 12
        }
    }
}
