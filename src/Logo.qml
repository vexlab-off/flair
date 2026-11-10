import QtQuick
import QtQuick.Shapes

// The flair mark: a folder with a spark at its corner — the files, and the
// thing that reads them. Drawn in the theme's colours so it follows Vex.
Item {
    id: logo
    property real size: 28
    property color tile: theme.highlight
    property color ink: theme.background

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: logo.size * 0.28
        color: logo.tile
    }

    Shape {
        width: 32
        height: 32
        scale: logo.size / 32
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        // Folder body
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.ink
            PathSvg { path: "M7 10.5A1.5 1.5 0 0 1 8.5 9h4.6l1.9 2.2h8.5A1.5 1.5 0 0 1 25 12.7v8.8a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 7 21.5z" }
        }
        // Spark, cut out of the folder in the tile colour
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.tile
            PathSvg { path: "M19.5 13.2c.35 2.3 1.5 3.45 3.8 3.8-2.3.35-3.45 1.5-3.8 3.8-.35-2.3-1.5-3.45-3.8-3.8 2.3-.35 3.45-1.5 3.8-3.8z" }
        }
    }
}
