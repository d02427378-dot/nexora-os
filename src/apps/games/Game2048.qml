import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: game
    objectName: "nexora2048Game"
    required property var shell
    property var board: []
    property int score: 0
    property bool gameOver: false
    property string message: "Fusionnez les tuiles jusqu’à atteindre 2048."
    property real boardSize: Math.min(430, width * 0.58, height * 0.88)

    function resetGame() {
        board = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        score = 0
        gameOver = false
        message = "Fusionnez les tuiles jusqu’à atteindre 2048."
        spawnTile()
        spawnTile()
    }

    function spawnTile() {
        var empty = []
        for (var i = 0; i < board.length; ++i) {
            if (board[i] === 0)
                empty.push(i)
        }
        if (empty.length === 0)
            return false
        var index = empty[Math.floor(Math.random() * empty.length)]
        var nextBoard = board.slice()
        nextBoard[index] = Math.random() < 0.9 ? 2 : 4
        board = nextBoard
        return true
    }

    function slideLine(line) {
        var packed = line.filter(function(value) { return value !== 0 })
        var merged = []
        var gained = 0
        for (var i = 0; i < packed.length; ++i) {
            if (i + 1 < packed.length && packed[i] === packed[i + 1]) {
                var value = packed[i] * 2
                merged.push(value)
                gained += value
                ++i
            } else {
                merged.push(packed[i])
            }
        }
        while (merged.length < 4)
            merged.push(0)
        return { values: merged, points: gained }
    }

    function hasMoves(cells) {
        for (var row = 0; row < 4; ++row) {
            for (var col = 0; col < 4; ++col) {
                var index = row * 4 + col
                if (cells[index] === 0)
                    return true
                if (col < 3 && cells[index] === cells[index + 1])
                    return true
                if (row < 3 && cells[index] === cells[index + 4])
                    return true
            }
        }
        return false
    }

    function move2048(direction) {
        if (gameOver)
            return false
        var nextBoard = board.slice()
        var gained = 0
        for (var lineIndex = 0; lineIndex < 4; ++lineIndex) {
            var line = []
            for (var offset = 0; offset < 4; ++offset) {
                var row = direction === "up" || direction === "down" ? offset : lineIndex
                var col = direction === "up" || direction === "down" ? lineIndex : offset
                line.push(board[row * 4 + col])
            }
            if (direction === "right" || direction === "down")
                line.reverse()
            var shifted = slideLine(line)
            if (direction === "right" || direction === "down")
                shifted.values.reverse()
            gained += shifted.points
            for (var cell = 0; cell < 4; ++cell) {
                var outRow = direction === "up" || direction === "down" ? cell : lineIndex
                var outCol = direction === "up" || direction === "down" ? lineIndex : cell
                nextBoard[outRow * 4 + outCol] = shifted.values[cell]
            }
        }

        var changed = nextBoard.some(function(value, index) { return value !== board[index] })
        if (!changed)
            return false
        board = nextBoard
        score += gained
        spawnTile()
        if (!hasMoves(board)) {
            gameOver = true
            message = "Plus de mouvements — score final : " + score + "."
        } else if (board.some(function(value) { return value >= 2048 })) {
            message = "2048 atteint ! Vous pouvez continuer ou recommencer."
        } else {
            message = gained > 0 ? "+" + gained + " points — continuez." : "Bonne avancée — continuez."
        }
        return true
    }

    function tileColor(value) {
        var colors = {
            0: shell.palette.surface,
            2: "#26334b",
            4: "#304461",
            8: "#57407d",
            16: "#73428d",
            32: "#a14687",
            64: "#cb568b",
            128: "#bb7b37",
            256: "#d29434",
            512: "#e0b347",
            1024: "#57a8a5",
            2048: "#41e7ff"
        }
        return colors[value] || shell.palette.violet
    }

    function focusBoard() {
        boardArea.forceActiveFocus()
    }

    Component.onCompleted: resetGame()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "2048"; color: shell.palette.text; font.pixelSize: 14; font.bold: true }
                Text { text: game.message; color: game.gameOver ? shell.palette.violet : shell.palette.muted; font.pixelSize: 9; elide: Text.ElideRight }
            }
            Text { text: "SCORE  " + game.score; color: shell.palette.cyan; font.pixelSize: 11; font.bold: true; font.family: "monospace" }
            Button {
                text: "Nouvelle partie"
                onClicked: game.resetGame()
                background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Item {
                id: boardArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                focus: true
                GridLayout {
                    anchors.centerIn: parent
                    width: game.boardSize
                    height: game.boardSize
                    columns: 4
                    rowSpacing: 7
                    columnSpacing: 7
                    Repeater {
                        model: 16
                        delegate: Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: game.tileColor(game.board[index] || 0)
                            border.color: game.board[index] ? Qt.rgba(255, 255, 255, 0.12) : shell.palette.border
                            Text {
                                anchors.centerIn: parent
                                text: game.board[index] === 0 ? "" : game.board[index]
                                color: game.board[index] >= 128 ? "#07131d" : shell.palette.text
                                font.pixelSize: game.board[index] >= 1024 ? 18 : game.board[index] >= 128 ? 22 : 26
                                font.bold: true
                                font.family: "monospace"
                            }
                        }
                    }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_W) game.move2048("up")
                    else if (event.key === Qt.Key_Down || event.key === Qt.Key_S) game.move2048("down")
                    else if (event.key === Qt.Key_Left || event.key === Qt.Key_A) game.move2048("left")
                    else if (event.key === Qt.Key_Right || event.key === Qt.Key_D) game.move2048("right")
                    else return
                    event.accepted = true
                }
                Component.onCompleted: forceActiveFocus()
            }
            ColumnLayout {
                Layout.preferredWidth: 150
                Layout.alignment: Qt.AlignVCenter
                spacing: 8
                Text {
                    text: "COMMANDES"
                    color: shell.palette.muted
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1
                }
                Button {
                    Layout.fillWidth: true
                    text: "↑  Haut"
                    onClicked: {
                        game.move2048("up")
                        boardArea.forceActiveFocus()
                    }
                    background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                    contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        Layout.fillWidth: true
                        text: "←"
                        onClicked: { game.move2048("left"); boardArea.forceActiveFocus() }
                        background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                        contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        Layout.fillWidth: true
                        text: "↓"
                        onClicked: { game.move2048("down"); boardArea.forceActiveFocus() }
                        background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                        contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        Layout.fillWidth: true
                        text: "→"
                        onClicked: { game.move2048("right"); boardArea.forceActiveFocus() }
                        background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                        contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Utilisez les flèches ou WASD. Les tuiles identiques fusionnent une seule fois par mouvement."
                    color: shell.palette.muted
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
