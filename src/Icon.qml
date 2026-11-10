import QtQuick
import QtQuick.Shapes

// One drawn icon set for the whole app: 24-unit line drawings at a single
// stroke weight, recoloured live from the theme.
Item {
    id: icon
    property string name: "file"
    property color color: theme.textDim
    property real size: 18
    property real stroke: 1.6
    // A Brands.js entry; when set, the logo is drawn instead of a line icon.
    property var brand: null

    implicitWidth: size
    implicitHeight: size

    readonly property var paths: ({
        folder: "M3 7.5A1.5 1.5 0 0 1 4.5 6H9l2 2.5h8.5A1.5 1.5 0 0 1 21 10v8.5a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18.5z",
        file: "M14 3H6.5A1.5 1.5 0 0 0 5 4.5v15A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V8zM14 3v5h5",
        image: "M4.5 4h15A1.5 1.5 0 0 1 21 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18.5v-13A1.5 1.5 0 0 1 4.5 4zM3 16l5-5 4 4 3-3 6 6M15 8.5a1 1 0 1 0 2 0a1 1 0 1 0-2 0",
        video: "M4.5 5h11A1.5 1.5 0 0 1 17 6.5v11a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 3 17.5v-11A1.5 1.5 0 0 1 4.5 5zM17 10l4-2.5v9L17 14",
        audio: "M9 18V5l11-2v13M3 18a3 3 0 1 0 6 0a3 3 0 1 0-6 0M14 16a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
        document: "M14 3H6.5A1.5 1.5 0 0 0 5 4.5v15A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V8zM14 3v5h5M8.5 13h7M8.5 16.5h5",
        tableur: "M14 3H6.5A1.5 1.5 0 0 0 5 4.5v15A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V8zM14 3v5h5M8 12h8v6H8zM12 12v6M8 15h8",
        presentation: "M3 4h18M4.5 4v10.5A1.5 1.5 0 0 0 6 16h12a1.5 1.5 0 0 0 1.5-1.5V4M12 16v4M8.5 20h7",
        archive: "M3 5h18v4H3zM4.5 9v10.5h15V9M10 13h4",
        code: "M8.5 7 3.5 12l5 5M15.5 7l5 5-5 5M13.5 4.5l-3 15",
        installeur: "M12 3 20 7.5v9L12 21l-8-4.5v-9zM4 7.5l8 4.5 8-4.5M12 12v9",
        texte: "M5 6h14M5 10h14M5 14h10M5 18h7",
        autre: "M14 3H6.5A1.5 1.5 0 0 0 5 4.5v15A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V8zM14 3v5h5",
        home: "M3.5 11 12 4l8.5 7M5.5 9.5V20h4.5v-5.5h4V20h4.5V9.5",
        desktop: "M3 4.5h18v11.5H3zM9 20h6M12 16v4",
        download: "M12 4v11M7 10.5l5 5 5-5M4.5 19.5h15",
        search: "M4 10.5a6.5 6.5 0 1 0 13 0a6.5 6.5 0 1 0-13 0M15.5 15.5 20 20",
        chat: "M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v9a1.5 1.5 0 0 1-1.5 1.5H10l-4.5 4v-4A1.5 1.5 0 0 1 4 14.5z",
        sparkle: "M12 3c.6 4.2 2.8 6.4 7 7-4.2.6-6.4 2.8-7 7-.6-4.2-2.8-6.4-7-7 4.2-.6 6.4-2.8 7-7zM19 16c.25 1.6 1 2.35 2.5 2.5-1.5.25-2.25 1-2.5 2.5-.25-1.5-1-2.25-2.5-2.5 1.5-.15 2.25-.9 2.5-2.5z",
        plan: "M4 6.5l1.5 1.5L8.5 5M11.5 6.5H20M4 12.5 5.5 14l3-3M11.5 12.5H20M11.5 18.5H20M5 18.5h2",
        sliders: "M4 7h10M18 7h2M4 17h4M12 17h8M16 5v4M10 15v4",
        branch: "M6 3v12M15 6a3 3 0 1 0 6 0a3 3 0 1 0-6 0M3 18a3 3 0 1 0 6 0a3 3 0 1 0-6 0M18 9c0 6-12 3-12 6",
        lock: "M6.5 10.5h11A1.5 1.5 0 0 1 19 12v7a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 19v-7a1.5 1.5 0 0 1 1.5-1.5zM8 10.5V8a4 4 0 0 1 8 0v2.5",
        star: "M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z",
        chevron: "M9 6l6 6-6 6",
        external: "M14 4h6v6M20 4l-9 9M18 14v4.5a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 4 18.5v-11A1.5 1.5 0 0 1 5.5 6H10",
        clone: "M7 18a4.5 4.5 0 0 1-.5-9A6 6 0 0 1 18 8.5a4 4 0 0 1 0 8M12 12v8M9 17l3 3 3-3",
        eye: "M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12zM9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
        layers: "M12 3 3 8l9 5 9-5zM3 12.5l9 5 9-5M3 17l9 5 9-5",
        refresh: "M20 11a8 8 0 1 0-2.3 5.7M20 5v6h-6",
        fork: "M6 3v4a3 3 0 0 0 3 3h6a3 3 0 0 0 3-3V3M12 10v11",
        check: "M5 12.5l4.5 4.5L19 7",
        alert: "M12 4 2.5 20h19zM12 10v4.5M12 17.5v.01",
        arrowUp: "M12 19V5M6 11l6-6 6 6",
        arrowDown: "M12 5v14M6 13l6 6 6-6",
        sort: "M7 4v16M3.5 16.5 7 20l3.5-3.5M14 6h7M14 12h5M14 18h3",
        close: "M6 6l12 12M18 6 6 18",
        phone: "M7 3h10a1.5 1.5 0 0 1 1.5 1.5v15A1.5 1.5 0 0 1 17 21H7a1.5 1.5 0 0 1-1.5-1.5v-15A1.5 1.5 0 0 1 7 3zM11 18h2",
        expand: "M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5",
        shrink: "M9 4v5H4M15 4v5h5M9 20v-5H4M15 20v-5h5",
        minus: "M5 12h14",
        play: "M7 4.5v15l12-7.5z",
        pause: "M7 4.5h3.5v15H7zM13.5 4.5H17v15h-3.5z",
        terminal: "M4.5 4h15A1.5 1.5 0 0 1 21 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18.5v-13A1.5 1.5 0 0 1 4.5 4zM7 9l3 3-3 3M12.5 15H17",
        copy: "M9 9h10.5v11.5H9zM15 9V5.5A1.5 1.5 0 0 0 13.5 4h-8A1.5 1.5 0 0 0 4 5.5v8A1.5 1.5 0 0 0 5.5 15H9",
        pencil: "M4 20l1-4.5L16 4.5a2.1 2.1 0 0 1 3 3L8 18.5zM14 7l3 3",
        trash: "M4 7h16M10 11v6M14 11v6M5.5 7l1 12a1.5 1.5 0 0 0 1.5 1.5h8a1.5 1.5 0 0 0 1.5-1.5l1-12M9 7V4.5h6V7",
        info: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0M12 11v5.5M12 7.5v.01",
        plus: "M12 5v14M5 12h14",
        globe: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0M3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9M12 3c-2.5 2.6-3.8 5.6-3.8 9s1.3 6.4 3.8 9"
    })

    // The GitHub mark is a filled 16-unit drawing (Octicons, MIT).
    readonly property string githubMark: "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
    readonly property bool isBrand: brand !== null && brand !== undefined
    readonly property bool filled: isBrand || name === "github"
    readonly property real unit: isBrand ? 24 : (filled ? 16 : 24)
    // Logos whose brand colour is too dark for the window take the text colour.
    readonly property color fillColor: isBrand ? (brand.dark ? theme.text : brand.color) : icon.color

    Shape {
        width: icon.unit
        height: icon.unit
        scale: icon.size / icon.unit
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: icon.filled ? "transparent" : icon.color
            strokeWidth: icon.filled ? 0 : icon.stroke * icon.unit / icon.size
            fillColor: icon.filled ? icon.fillColor : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.isBrand ? icon.brand.d : icon.filled ? icon.githubMark : (icon.paths[icon.name] || icon.paths.file) }
        }
    }
}
