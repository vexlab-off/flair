import QtQuick
import QtQuick.Shapes

// Flair Code's mark, so flair's settings can preview both logos of the suite.
Item {
    id: logo
    property real size: 28
    property string variant: ""
    readonly property var colors: (theme.highlight, theme.logoStyle, theme.logoColors("flaircode", variant))
    readonly property color tile: colors.tile
    readonly property color ink: colors.front
    readonly property color spark: colors.spark

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
        ShapePath {
            strokeColor: logo.ink
            strokeWidth: 26
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M92 72L44 128l48 56M164 72l48 56-48 56" }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.spark
            PathSvg { path: "M128 76C131.6 108 143 119.4 175 123C143 126.6 131.6 138 128 170C124.4 138 113 126.6 81 123C113 119.4 124.4 108 128 76z" }
        }
    }
}
