import QtQuick

// A small tag that says what kind of file a row is, in place of an icon set.
Rectangle {
    property string kind: "autre"

    readonly property var labels: ({
        dossier: "DIR", image: "IMG", video: "VID", audio: "AUD", document: "DOC",
        tableur: "TAB", presentation: "PRS", archive: "ZIP", installeur: "APP",
        code: "</>", texte: "TXT", autre: "···"
    })

    width: 34
    height: 18
    radius: 4
    color: kind === "dossier" ? theme.accent : "#24242a"

    Text {
        anchors.centerIn: parent
        text: parent.labels[parent.kind] || "···"
        color: parent.kind === "dossier" ? theme.accentForeground : "#a0a0aa"
        font.pixelSize: 9
        font.bold: true
        font.family: "monospace"
    }
}
