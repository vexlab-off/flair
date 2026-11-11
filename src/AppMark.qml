import QtQuick
import QtQuick.Shapes

// The marks of Flair Image and Flair Vidéo, drawn like flair's own logo and in
// the same colours and styles (see launcher.cpp for the same drawings in SVG).
Item {
    id: mark
    property string app: "flair-image" // or "flair-video"
    property real size: 28
    property string variant: ""
    readonly property var colors: (theme.highlight, theme.logoStyle, theme.logoColors("flair", variant))

    implicitWidth: size
    implicitHeight: size

    Rectangle { anchors.fill: parent; radius: mark.size * 0.235; color: mark.colors.tile }

    Shape {
        width: 256; height: 256
        scale: mark.size / 256
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillColor: mark.colors.back
            PathSvg { path: mark.app === "flair-video"
                            ? "M36 74a20 20 0 0 1 20-20h144a20 20 0 0 1 20 20v112a20 20 0 0 1-20 20H56a20 20 0 0 1-20-20z"
                            : "M40 64a20 20 0 0 1 20-20h136a20 20 0 0 1 20 20v128a20 20 0 0 1-20 20H60a20 20 0 0 1-20-20z" }
        }
        ShapePath {
            strokeColor: mark.app === "flair-video" ? mark.colors.front : "transparent"
            strokeWidth: 18
            joinStyle: ShapePath.RoundJoin
            fillColor: mark.colors.front
            PathSvg { path: mark.app === "flair-video" ? "M110 100v60l50-30z"
                            : "M40 182l54-62 40 44 28-30 54 58v0a20 20 0 0 1-20 20H60a20 20 0 0 1-20-20z" }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: mark.colors.spark
            PathSvg { path: mark.app === "flair-video"
                            ? "M202 26C204.2 43.4 209.6 48.8 227 51C209.6 53.2 204.2 58.6 202 76C199.8 58.6 194.4 53.2 177 51C194.4 48.8 199.8 43.4 202 26z"
                            : "M164 58C166.6 79 173.4 85.8 194 88.4C173.4 91 166.6 97.8 164 118.8C161.4 97.8 154.6 91 134 88.4C154.6 85.8 161.4 79 164 58z" }
        }
    }
}
