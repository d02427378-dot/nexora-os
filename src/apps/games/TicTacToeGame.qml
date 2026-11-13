import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: game
    objectName: "nexoraTicTacToeGame"
    required property var shell
    property var board: ["", "", "", "", "", "", "", "", ""]
    property string currentPlayer: "X"
    property string winner: ""
    property bool draw: false
    property string message: "X commence — sélectionnez une case."
    property var wins: ({ X: 0, O: 0 })
    property real boardSize: Math.min(390, width * 0.72)

    function findWinner(cells) {
        var lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i]
            if (cells[line[0]] !== "" && cells[line[0]] === cells[line[1]] && cells[line[1]] === cells[line[2]])
                return cells[line[0]]
        }
        return ""
    }

    function playCell(index) {
        if (index < 0 || index >= 9 || winner !== "" || draw || board[index] !== "")
            return false
        var nextBoard = board.slice()
        nextBoard[index] = currentPlayer
        board = nextBoard
        var result = findWinner(nextBoard)
        if (result !== "") {
            winner = result
            wins = result === "X" ? { X: wins.X + 1, O: wins.O } : { X: wins.X, O: wins.O + 1 }
            message = "Victoire de " + result + " — relancez une partie."
        } else if (!nextBoard.some(function(cell) { return cell === "" })) {
            draw = true
            message = "Match nul — relancez une partie."
        } else {
            currentPlayer = currentPlayer === "X" ? "O" : "X"
            message = "Au tour de " + currentPlayer + "."
        }
        return true
    }

    function resetGame() {
        board = ["", "", "", "", "", "", "", "", ""]
        currentPlayer = "X"
        winner = ""
        draw = false
        message = "X commence — sélectionnez une case."
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Morpion"; color: shell.palette.text; font.pixelSize: 14; font.bold: true }
                Text { text: game.message; color: game.winner !== "" ? shell.palette.good : shell.palette.muted; font.pixelSize: 9 }
            }
            Text { text: "X  " + game.wins.X + "   ·   O  " + game.wins.O; color: shell.palette.cyan; font.pixelSize: 10; font.family: "monospace" }
            Button {
                text: "Recommencer"
                onClicked: game.resetGame()
                background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        Item { Layout.fillHeight: true }
        GridLayout {
            id: boardGrid
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: game.boardSize
            Layout.preferredHeight: game.boardSize
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: 9
                delegate: Button {
                    required property int index
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: game.board[index]
                    onClicked: game.playCell(index)
                    background: Rectangle {
                        radius: 14
                        color: game.board[index] === "X" ? Qt.rgba(65 / 255, 231 / 255, 1, 0.12) : game.board[index] === "O" ? Qt.rgba(165 / 255, 107 / 255, 1, 0.14) : shell.palette.surface
                        border.color: game.board[index] === "X" ? shell.palette.cyan : game.board[index] === "O" ? shell.palette.violet : shell.palette.border
                    }
                    contentItem: Text {
                        text: game.board[index]
                        color: game.board[index] === "X" ? shell.palette.cyan : shell.palette.violet
                        font.pixelSize: 38
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
