import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1180
    height: 800
    visible: true
    title: "Nexora Mini-games smoke test"
    property int stage: 0
    property var gamesWindow: null

    QtObject {
        id: fakeShell
        property int zCounter: 0
        property var palette: ({
            background: "#090c16",
            surface: "#101629",
            raised: "#171f35",
            hover: "#202b46",
            border: "#293550",
            text: "#edf0ff",
            muted: "#93a0bf",
            violet: "#a56bff",
            indigo: "#7771ff",
            cyan: "#41e7ff",
            focus: "#70eaff",
            good: "#6ce6b3"
        })
        function closeWindow(uid) {}
    }

    function findNamed(node, targetName) {
        if (!node)
            return null
        if (node.objectName === targetName)
            return node
        if (node.item) {
            var loaded = findNamed(node.item, targetName)
            if (loaded)
                return loaded
        }
        if (node.contentItem) {
            var content = findNamed(node.contentItem, targetName)
            if (content)
                return content
        }
        if (node.children) {
            for (var i = 0; i < node.children.length; ++i) {
                var found = findNamed(node.children[i], targetName)
                if (found)
                    return found
            }
        }
        return null
    }

    Component.onCompleted: {
        var component = Qt.createComponent(Qt.resolvedUrl("../../src/desktop/WindowCard.qml"))
        if (component.status !== Component.Ready) {
            console.error("WindowCard load failed:", component.errorString())
            Qt.exit(2)
            return
        }
        gamesWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1500,
                appId: "games",
                title: "Mini-jeux Nexora",
                glyph: "GAME",
                workspace: 0,
                x: 20,
                y: 20,
                width: 1080,
                height: 720
            },
            x: 20,
            y: 20,
            width: 1080,
            height: 720
        })
        if (!gamesWindow) {
            console.error("MiniGames WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            var app = root.findNamed(root.contentItem, "nexoraGamesApp")
            if (!app)
                return
            var ticTacToe = root.findNamed(app, "nexoraTicTacToeGame")
            var snake = root.findNamed(app, "nexoraSnakeGame")
            var memory = root.findNamed(app, "nexoraMemoryGame")
            var game2048 = root.findNamed(app, "nexora2048Game")
            if (!ticTacToe || !snake || !memory || !game2048)
                return

            if (root.stage === 0) {
                if (app.gameCatalog.length !== 4) {
                    console.error("Arcade must contain four games")
                    Qt.exit(4)
                    return
                }
                app.selectedGame = 0
                ticTacToe.resetGame()
                var moves = [0, 3, 1, 4, 2]
                for (var i = 0; i < moves.length; ++i) {
                    if (!ticTacToe.playCell(moves[i])) {
                        console.error("Tic-tac-toe rejected a legal move", moves[i])
                        Qt.exit(5)
                        return
                    }
                }
                if (ticTacToe.winner !== "X" || ticTacToe.playCell(5)) {
                    console.error("Tic-tac-toe win detection or terminal lock failed")
                    Qt.exit(6)
                    return
                }
                root.stage = 1
            } else if (root.stage === 1) {
                app.selectedGame = 1
                snake.resetGame()
                snake.snake = [{ x: 5, y: 5 }, { x: 4, y: 5 }, { x: 3, y: 5 }]
                snake.snakeFood = { x: 16, y: 12 }
                snake.snakeDirection = "right"
                snake.queuedDirection = "right"
                snake.startGame()
                if (!snake.advanceSnake() || snake.snake[0].x !== 6 || snake.snake[0].y !== 5 || snake.snake.length !== 3) {
                    console.error("Snake forward movement failed")
                    Qt.exit(7)
                    return
                }
                snake.snake = [{ x: 17, y: 5 }, { x: 16, y: 5 }, { x: 15, y: 5 }]
                snake.snakeFood = { x: 3, y: 3 }
                snake.snakeDirection = "right"
                snake.queuedDirection = "right"
                snake.snakeRunning = true
                if (snake.advanceSnake() || !snake.snakeGameOver || snake.snakeRunning) {
                    console.error("Snake wall collision did not end the game")
                    Qt.exit(8)
                    return
                }
                root.stage = 2
            } else if (root.stage === 2) {
                app.selectedGame = 2
                memory.resetGame()
                var pairA = -1
                var pairB = -1
                for (var a = 0; a < memory.memoryCards.length; ++a) {
                    for (var b = a + 1; b < memory.memoryCards.length; ++b) {
                        if (memory.memoryCards[a].value === memory.memoryCards[b].value) {
                            pairA = a
                            pairB = b
                            break
                        }
                    }
                    if (pairA >= 0)
                        break
                }
                if (pairA < 0 || !memory.flipCard(pairA) || !memory.flipCard(pairB) || memory.matchedCount !== 2 || memory.moves !== 1) {
                    console.error("Memory pair matching failed")
                    Qt.exit(9)
                    return
                }
                root.stage = 3
            } else if (root.stage === 3) {
                app.selectedGame = 3
                game2048.board = [2, 2, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                game2048.score = 0
                game2048.gameOver = false
                if (!game2048.move2048("left") || game2048.board[0] !== 4 || game2048.board[1] !== 8 || game2048.score !== 12) {
                    console.error("2048 merge rules or scoring failed", game2048.board, game2048.score)
                    Qt.exit(10)
                    return
                }
                console.log("Arcade Nexora validée : Morpion, Snake, Memory et 2048 jouables; collisions, paires et fusions testées hors ligne.")
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 12000
        running: true
        onTriggered: {
            console.error("Mini-games smoke test timed out at stage", root.stage)
            Qt.exit(11)
        }
    }
}
