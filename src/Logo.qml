import QtQuick
import QtQuick.Shapes

// The flair mark: an open folder with a spark rising out of it — your files,
// and the intelligence that reads them. Drawn in the accent colour, so it
// follows the setting; pkgbuild/flair.svg is the same drawing in orange.
Item {
    id: logo
    property real size: 28
    property color tile: theme.highlight

    readonly property color back: Qt.darker(tile, 1.5)
    readonly property color ink: "#1b120b"
    readonly property color spark: "#fff3e8"

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: logo.size * 0.235
        color: logo.tile
    }

    Shape {
        width: 256
        height: 256
        scale: logo.size / 256
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        // Back of the folder, with its tab: the inside, in shadow.
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.back
            PathSvg { path: "M44 98a14 14 0 0 1 14-14h40l18 20h82a14 14 0 0 1 14 14v86a14 14 0 0 1-14 14H58a14 14 0 0 1-14-14z" }
        }
        // The spark rising out of it, and a small one beside.
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.spark
            PathSvg { path: "M148 34C152 70 166 84 202 88C166 92 152 106 148 142C144 106 130 92 94 88C130 84 144 70 148 34zM82 46C83.6 58 88.5 62.9 100.5 64.5C88.5 66.1 83.6 71 82 83C80.4 71 75.5 66.1 63.5 64.5C75.5 62.9 80.4 58 82 46z" }
        }
        // The open front flap, in front of the spark.
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.ink
            PathSvg { path: "M40 132h176c4 0 7 3.4 6.4 7.4l-10.6 63.6a16 16 0 0 1-15.8 13.4H66a16 16 0 0 1-15.8-13.4L33.6 139.4c-.6-4 2.4-7.4 6.4-7.4z" }
        }
    }
}
