import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: game
    objectName: "nexoraSnakeGame"
    required property var shell
    property bool active: false
    readonly property int columns: 18
    readonly property int rows: 14
    property var snake: []
    property var snakeFood: ({ x: 13, y: 7 })
    property string snakeDirection: "right"
    property string queuedDirection: "right"
    property int score: 0
    property bool snakeRunning: false
    property bool snakeGameOver: false
    property string message: "Prêt — démarrez puis utilisez les flèches ou WASD."

    function resetGame() {
        snake = [{ x: 5, y: 7 }, { x: 4, y: 7 }, { x: 3, y: 7 }]
        snakeFood = { x: 13, y: 7 }
        snakeDirection = "right"
        queuedDirection = "right"
        score = 0
        snakeRunning = false
        snakeGameOver = false
        message = "Prêt — démarrez puis utilisez les flèches ou WASD."
    }

    function startGame() {
        if (snakeGameOver)
            resetGame()
        snakeRunning = true
        message = "Partie en cours — évitez les murs et votre corps."
        focusBoard()
    }

    function focusBoard() {
        canvas.forceActiveFocus()
    }

    function directionVector(direction) {
        if (direction === "up") return { x: 0, y: -1 }
        if (direction === "down") return { x: 0, y: 1 }
        if (direction === "left") return { x: -1, y: 0 }
        return { x: 1, y: 0 }
    }

    function setDirection(direction) {
        var current = directionVector(snakeDirection)
        var requested = directionVector(direction)
        if (current.x + requested.x === 0 && current.y + requested.y === 0)
            return false
        queuedDirection = direction
        return true
    }

    function spawnFood(occupied) {
        var freeCells = []
        for (var y = 0; y < rows; ++y) {
            for (var x = 0; x < columns; ++x) {
                var used = occupied.some(function(part) { return part.x === x && part.y === y })
                if (!used)
                    freeCells.push({ x: x, y: y })
            }
        }
        if (freeCells.length === 0)
            return null
        return freeCells[Math.floor(Math.random() * freeCells.length)]
    }

    function advanceSnake() {
        if (!snakeRunning || snake.length === 0)
            return false
        snakeDirection = queuedDirection
        var vector = directionVector(snakeDirection)
        var head = snake[0]
        var nextHead = { x: head.x + vector.x, y: head.y + vector.y }
        var ateFood = nextHead.x === snakeFood.x && nextHead.y === snakeFood.y
        var bodyToCheck = ateFood ? snake : snake.slice(0, snake.length - 1)
        var collision = nextHead.x < 0 || nextHead.x >= columns || nextHead.y < 0 || nextHead.y >= rows
                || bodyToCheck.some(function(part) { return part.x === nextHead.x && part.y === nextHead.y })
        if (collision) {
            snakeRunning = false
            snakeGameOver = true
            message = "Partie terminée — score " + score + ". Recommencez pour rejouer."
            return false
        }

        var nextSnake = [nextHead].concat(snake)
        if (!ateFood)
            nextSnake.pop()
        else {
            score += 10
            snakeFood = spawnFood(nextSnake)
            if (snakeFood === null) {
                snakeRunning = false
                snakeGameOver = true
                message = "Plateau rempli — victoire !"
            }
        }
        snake = nextSnake
        return true
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
                Text { text: "Snake"; color: shell.palette.text; font.pixelSize: 14; font.bold: true }
                Text { text: game.message; color: game.snakeGameOver ? shell.palette.violet : shell.palette.muted; font.pixelSize: 9; elide: Text.ElideRight }
            }
            Text { text: "SCORE  " + game.score; color: shell.palette.cyan; font.pixelSize: 11; font.bold: true; font.family: "monospace" }
            Button {
                text: game.snakeRunning ? "En cours" : game.snakeGameOver ? "Rejouer" : "Démarrer"
                enabled: !game.snakeRunning
                onClicked: game.startGame()
                background: Rectangle { radius: 8; color: parent.enabled ? shell.palette.hover : shell.palette.raised; border.color: shell.palette.cyan }
                contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button {
                text: "Réinitialiser"
                onClicked: game.resetGame()
                background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            Item {
                id: boardArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    id: boardFrame
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height * game.columns / game.rows)
                    height: width * game.rows / game.columns
                    radius: 12
                    color: shell.palette.background
                    border.color: shell.palette.border
                    clip: true
                    Canvas {
                        id: canvas
                        anchors.fill: parent
                        anchors.margins: 1
                        focus: true
                        onPaint: {
                            var context = getContext("2d")
                            var cellWidth = width / game.columns
                            var cellHeight = height / game.rows
                            context.clearRect(0, 0, width, height)
                            context.fillStyle = shell.palette.background
                            context.fillRect(0, 0, width, height)
                            context.strokeStyle = shell.palette.border
                            context.globalAlpha = 0.3
                            context.lineWidth = 1
                            for (var x = 1; x < game.columns; ++x) {
                                context.beginPath()
                                context.moveTo(x * cellWidth, 0)
                                context.lineTo(x * cellWidth, height)
                                context.stroke()
                            }
                            for (var y = 1; y < game.rows; ++y) {
                                context.beginPath()
                                context.moveTo(0, y * cellHeight)
                                context.lineTo(width, y * cellHeight)
                                context.stroke()
                            }
                            context.globalAlpha = 1
                            if (game.snakeFood) {
                                context.fillStyle = shell.palette.violet
                                context.beginPath()
                                context.arc((game.snakeFood.x + 0.5) * cellWidth, (game.snakeFood.y + 0.5) * cellHeight,
                                           Math.min(cellWidth, cellHeight) * 0.32, 0, Math.PI * 2)
                                context.fill()
                            }
                            for (var i = game.snake.length - 1; i >= 0; --i) {
                                var part = game.snake[i]
                                context.fillStyle = i === 0 ? shell.palette.cyan : shell.palette.indigo
                                context.fillRect(part.x * cellWidth + 2, part.y * cellHeight + 2,
                                                 cellWidth - 4, cellHeight - 4)
                            }
                        }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_W) game.setDirection("up")
                            else if (event.key === Qt.Key_Down || event.key === Qt.Key_S) game.setDirection("down")
                            else if (event.key === Qt.Key_Left || event.key === Qt.Key_A) game.setDirection("left")
                            else if (event.key === Qt.Key_Right || event.key === Qt.Key_D) game.setDirection("right")
                            else return
                            event.accepted = true
                        }
                        Component.onCompleted: forceActiveFocus()
                    }
                    Connections {
                        target: game
                        function onSnakeChanged() { canvas.requestPaint() }
                        function onSnakeFoodChanged() { canvas.requestPaint() }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 98
                Layout.fillHeight: true
                spacing: 8
                Item { Layout.fillHeight: true }
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↑"
                    onClicked: { game.setDirection("up"); canvas.forceActiveFocus() }
                    background: Rectangle { radius: 9; color: shell.palette.raised; border.color: shell.palette.border }
                    contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5
                    Button {
                        text: "←"
                        onClicked: { game.setDirection("left"); canvas.forceActiveFocus() }
                        background: Rectangle { radius: 9; color: shell.palette.raised; border.color: shell.palette.border }
                        contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        text: "↓"
                        onClicked: { game.setDirection("down"); canvas.forceActiveFocus() }
                        background: Rectangle { radius: 9; color: shell.palette.raised; border.color: shell.palette.border }
                        contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        text: "→"
                        onClicked: { game.setDirection("right"); canvas.forceActiveFocus() }
                        background: Rectangle { radius: 9; color: shell.palette.raised; border.color: shell.palette.border }
                        contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
                Text { Layout.alignment: Qt.AlignHCenter; text: "WASD / flèches"; color: shell.palette.muted; font.pixelSize: 8 }
                Item { Layout.fillHeight: true }
            }
        }

        Timer {
            interval: 145
            repeat: true
            running: game.snakeRunning && game.active
            onTriggered: game.advanceSnake()
        }
    }
}
