import QtQuick
import QtQuick.Layouts

// Every shortcut, shown with ?.
Rectangle {
    id: overlay
    color: theme.alpha(theme.background, 0.88)

    readonly property var groups: [
        { title: "Naviguer", icon: "folder", keys: [
            ["↑ ↓  ·  J K", "Se déplacer"],
            ["Entrée  ·  →  ·  L", "Ouvrir (HTML : aperçu, code : éditeur)"],
            ["E", "Ouvrir dans l'éditeur de code"],
            ["Retour  ·  ←  ·  H", "Dossier parent"],
            ["~", "Dossier personnel"],
            ["Ctrl+L", "Aller à un chemin"],
            [".", "Fichiers cachés"],
            ["O", "Changer le tri (auto, nom, date, taille, type)"]
        ]},
        { title: "IA", icon: "sparkle", keys: [
            ["Espace", "Aperçu : page HTML rendue, sinon résumé"],
            ["F", "Agrandir l'aperçu HTML"],
            ["/", "Rechercher (par le sens si indexé)"],
            ["I", "Indexer ce dossier"],
            ["C", "Discuter avec ce dossier"],
            [":", "Commande en langage naturel"],
            ["S  ·  Maj+S", "Ranger par type  ·  avec l'IA"],
            ["Ctrl+Entrée", "Appliquer le plan"],
            ["Échap", "Fermer, abandonner, arrêter l'IA"]
        ]},
        { title: "GitHub", icon: "github", keys: [
            ["Ctrl+G", "Tes dépôts GitHub"],
            ["Entrée", "Ouvrir le clone, ou cloner"],
            ["/", "Filtrer les dépôts"],
            ["R", "Recharger la liste"],
            ["G", "Ouvrir sur github.com"],
            ["Ctrl+Maj+G", "Cloner un dépôt par son nom"],
            ["D", "Expliquer les changements Git"]
        ]},
        { title: "Général", icon: "sliders", keys: [
            ["Ctrl+Z  ·  Ctrl+Maj+Z", "Annuler  ·  rétablir"],
            ["1 2 3 4", "Aperçu, recherche, chat, plan"],
            ["Ctrl+,", "Réglages"],
            ["?", "Cette aide"],
            ["Q", "Quitter"]
        ]}
    ]

    MouseArea { anchors.fill: parent; onClicked: overlay.visible = false }

    Rectangle {
        anchors.centerIn: parent
        width: grid.implicitWidth + 64
        height: grid.implicitHeight + 64
        radius: 16
        color: theme.surface
        border.color: theme.line

        GridLayout {
            id: grid
            anchors.centerIn: parent
            columns: 2
            columnSpacing: 56
            rowSpacing: 28

            Repeater {
                model: overlay.groups
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.alignment: Qt.AlignTop
                    spacing: 8
                    RowLayout {
                        spacing: 8
                        Layout.bottomMargin: 2
                        Icon { name: modelData.icon; size: 16; color: theme.highlight }
                        Text {
                            text: modelData.title
                            color: theme.text
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }
                    Repeater {
                        model: modelData.keys
                        delegate: RowLayout {
                            required property var modelData
                            spacing: 14
                            Item {
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 20
                                Keycap { anchors.verticalCenter: parent.verticalCenter; text: modelData[0] }
                            }
                            Text {
                                text: modelData[1]
                                color: theme.textDim
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
