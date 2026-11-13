import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: game
    objectName: "nexoraMemoryGame"
    required property var shell
    property var memoryCards: []
    property int matchedCount: 0
    property int moves: 0
    property int firstCard: -1
    property int secondCard: -1
    property bool locked: false
    property string message: "Retrouvez les six paires."

    function resetGame() {
        mismatchTimer.stop()
        var symbols = ["✦", "✦", "◈", "◈", "●", "●", "◆", "◆", "▲", "▲", "✧", "✧"]
        for (var i = symbols.length - 1; i > 0; --i) {
            var j = Math.floor(Math.random() * (i + 1))
            var swap = symbols[i]
            symbols[i] = symbols[j]
            symbols[j] = swap
        }
        var cards = []
        for (var k = 0; k < symbols.length; ++k)
            cards.push({ value: symbols[k], revealed: false, matched: false })
        memoryCards = cards
        matchedCount = 0
        moves = 0
        firstCard = -1
        secondCard = -1
        locked = false
        message = "Retrouvez les six paires."
    }

    function flipCard(index) {
        if (locked || index < 0 || index >= memoryCards.length || memoryCards[index].revealed || memoryCards[index].matched)
            return false
        var cards = memoryCards.map(function(card) { return ({ value: card.value, revealed: card.revealed, matched: card.matched }) })
        cards[index].revealed = true
        memoryCards = cards
        if (firstCard < 0) {
            firstCard = index
            return true
        }

        secondCard = index
        moves += 1
        if (memoryCards[firstCard].value === memoryCards[secondCard].value) {
            var matchedCards = memoryCards.map(function(card) { return ({ value: card.value, revealed: card.revealed, matched: card.matched }) })
            matchedCards[firstCard].matched = true
            matchedCards[secondCard].matched = true
            memoryCards = matchedCards
            matchedCount += 2
            firstCard = -1
            secondCard = -1
            message = matchedCount === memoryCards.length ? "Toutes les paires trouvées en " + moves + " coups !" : "Bonne paire — continuez."
        } else {
            locked = true
            message = "Pas de correspondance — mémorisez les cartes."
            mismatchTimer.start()
        }
        return true
    }

    Component.onCompleted: resetGame()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Memory"; color: shell.palette.text; font.pixelSize: 14; font.bold: true }
                Text { text: game.message; color: game.matchedCount === game.memoryCards.length ? shell.palette.good : shell.palette.muted; font.pixelSize: 9 }
            }
            Text { text: "PAIRES  " + (game.matchedCount / 2) + "/6   ·   COUPS  " + game.moves; color: shell.palette.cyan; font.pixelSize: 10; font.bold: true; font.family: "monospace" }
            Button {
                text: "Nouvelle partie"
                onClicked: game.resetGame()
                background: Rectangle { radius: 8; color: shell.palette.raised; border.color: shell.palette.border }
                contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        Item { Layout.fillHeight: true }
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 4
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: game.memoryCards
                delegate: Button {
                    required property var modelData
                    required property int index
                    Layout.preferredWidth: Math.min(116, Math.max(72, game.width * 0.13))
                    Layout.preferredHeight: Math.min(92, Math.max(62, game.height * 0.15))
                    onClicked: game.flipCard(index)
                    background: Rectangle {
                        radius: 12
                        color: modelData.matched ? Qt.rgba(108 / 255, 230 / 255, 179 / 255, 0.13)
                                                  : (modelData.revealed ? shell.palette.hover : shell.palette.surface)
                        border.color: modelData.matched ? shell.palette.good : (modelData.revealed ? shell.palette.cyan : shell.palette.border)
                    }
                    contentItem: Text {
                        text: modelData.revealed || modelData.matched ? modelData.value : "✦"
                        color: modelData.matched ? shell.palette.good : (modelData.revealed ? shell.palette.cyan : shell.palette.muted)
                        font.pixelSize: modelData.revealed || modelData.matched ? 27 : 19
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }

        Timer {
            id: mismatchTimer
            interval: 700
            repeat: false
            onTriggered: {
                var cards = game.memoryCards.map(function(card) { return ({ value: card.value, revealed: card.revealed, matched: card.matched }) })
                if (game.firstCard >= 0)
                    cards[game.firstCard].revealed = false
                if (game.secondCard >= 0)
                    cards[game.secondCard].revealed = false
                game.memoryCards = cards
                game.firstCard = -1
                game.secondCard = -1
                game.locked = false
                game.message = "Retrouvez les six paires."
            }
        }
    }
}
