import QtQuick
import QtQuick.Layouts

// Every shortcut, shown with ?.
Rectangle {
    color: Qt.rgba(0, 0, 0, 0.78)

    readonly property var groups: [
        { title: "Naviguer", keys: [
            ["↑ ↓  /  J K", "Se déplacer"],
            ["Entrée  /  →  /  L", "Ouvrir"],
            ["Retour  /  ←  /  H", "Dossier parent"],
            ["~", "Dossier personnel"],
            ["Ctrl+L", "Aller à un chemin"],
            [".", "Afficher les fichiers cachés"]
        ]},
        { title: "IA", keys: [
            ["Espace", "Résumer la sélection"],
            ["/", "Rechercher (par le sens si indexé)"],
            ["I", "Indexer ce dossier"],
            ["C", "Discuter avec ce dossier"],
            [":", "Commande en langage naturel"],
            ["S", "Ranger par type (sans IA)"],
            ["Maj+S", "Rangement intelligent (IA)"],
            ["Ctrl+Entrée", "Appliquer le plan"],
            ["Échap", "Fermer, abandonner, arrêter l'IA"]
        ]},
        { title: "Git et GitHub", keys: [
            ["D", "Expliquer les changements + message de commit"],
            ["G", "Ouvrir le dépôt sur GitHub"],
            ["Ctrl+G", "Cloner un dépôt GitHub ici"]
        ]},
        { title: "Général", keys: [
            ["Ctrl+Z  /  Ctrl+Maj+Z", "Annuler / rétablir un plan"],
            ["1 2 3 4", "Aperçu, recherche, chat, plan"],
            ["Ctrl+,", "Réglages"],
            ["?", "Cette aide"],
            ["Q", "Quitter"]
        ]}
    ]

    MouseArea { anchors.fill: parent; onClicked: parent.visible = false }

    GridLayout {
        anchors.centerIn: parent
        columns: 2
        columnSpacing: 56
        rowSpacing: 28

        Repeater {
            model: parent.parent.groups
            delegate: ColumnLayout {
                required property var modelData
                Layout.alignment: Qt.AlignTop
                spacing: 6
                Text {
                    text: modelData.title
                    color: theme.accent
                    font.pixelSize: 14
                    font.bold: true
                }
                Repeater {
                    model: modelData.keys
                    delegate: RowLayout {
                        required property var modelData
                        spacing: 14
                        Text {
                            Layout.preferredWidth: 170
                            text: modelData[0]
                            color: "#f2f2f5"
                            font.family: "monospace"
                            font.pixelSize: 12
                        }
                        Text {
                            text: modelData[1]
                            color: "#a0a0aa"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
