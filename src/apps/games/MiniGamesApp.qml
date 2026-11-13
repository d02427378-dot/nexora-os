import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: gamesApp
    objectName: "nexoraGamesApp"
    required property var shell
    property int selectedGame: 0
    property var gameCatalog: [
        { title: "Morpion", subtitle: "Duel local", glyph: "XO" },
        { title: "Snake", subtitle: "Réflexes", glyph: "▰" },
        { title: "Memory", subtitle: "Paires", glyph: "◇" },
        { title: "2048", subtitle: "Fusion", glyph: "2⁴" }
    ]

    function restoreGameFocus() {
        Qt.callLater(function() {
            if (gamesApp.selectedGame === 1)
                snakeGame.focusBoard()
            else if (gamesApp.selectedGame === 3)
                game2048.focusBoard()
            else
                gamesApp.forceActiveFocus()
        })
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Arcade Nexora"; color: shell.palette.text; font.pixelSize: 20; font.bold: true }
                Text { text: "Quatre jeux locaux · sans compte, réseau ni installation"; color: shell.palette.muted; font.pixelSize: 9 }
            }
            Text { text: "OFFLINE"; color: shell.palette.cyan; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Repeater {
                model: gamesApp.gameCatalog
                delegate: Button {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    text: modelData.glyph + "   " + modelData.title
                    onClicked: {
                        gamesApp.selectedGame = index
                        gamesApp.restoreGameFocus()
                    }
                    background: Rectangle {
                        radius: 10
                        color: gamesApp.selectedGame === index ? shell.palette.hover : shell.palette.surface
                        border.color: gamesApp.selectedGame === index ? shell.palette.cyan : shell.palette.border
                    }
                    contentItem: Text {
                        text: parent.text
                        color: gamesApp.selectedGame === index ? shell.palette.text : shell.palette.muted
                        font.pixelSize: 10
                        font.bold: gamesApp.selectedGame === index
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        StackLayout {
            id: gameStack
            objectName: "miniGameStack"
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: gamesApp.selectedGame

            TicTacToeGame { id: ticTacToeGame; shell: gamesApp.shell }
            SnakeGame { id: snakeGame; shell: gamesApp.shell; active: gamesApp.selectedGame === 1 }
            MemoryGame { id: memoryGame; shell: gamesApp.shell }
            Game2048 { id: game2048; shell: gamesApp.shell }
        }
    }
}
