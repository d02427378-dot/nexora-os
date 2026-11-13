import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtMultimedia 6.4

ApplicationWindow {
    id: root
    width: 1080
    height: 720
    visible: true
    title: "Nexora Musique smoke test"
    property int stage: 0

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

    property var musicWindow: null

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
        musicWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1300,
                appId: "music",
                title: "Musique",
                glyph: "♫",
                workspace: 0,
                x: 20,
                y: 20,
                width: 980,
                height: 650
            },
            x: 20,
            y: 20,
            width: 980,
            height: 650
        })
        if (!musicWindow) {
            console.error("Music WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            var app = root.findNamed(root.contentItem, "nexoraMusicApp")
            if (!app)
                return
            var player = app.playerForTests
            if (root.stage === 0) {
                app.audioForTests.volume = 0
                var folder = Qt.resolvedUrl("../../tests/fixtures/media/").toString()
                if (!app.openFolder(folder)) {
                    console.error("Local music folder rejected:", app.libraryMessage)
                    Qt.exit(4)
                    return
                }
                if (!app.openFolder("https://example.invalid/music")) {
                    // Expected path: the remote location is rejected.
                } else {
                    console.error("Music app accepted a remote folder")
                    Qt.exit(5)
                    return
                }
                // Restore the valid local fixture after asserting the remote guard.
                if (!app.openFolder(folder)) {
                    console.error("Could not restore local music fixture")
                    Qt.exit(6)
                    return
                }
                root.stage = 1
            } else if (root.stage === 1) {
                if (app.trackCount === 0)
                    return
                if (!app.playTrack(0)) {
                    console.error("Could not start the local fixture track")
                    Qt.exit(7)
                    return
                }
                if (app.currentTrackName !== "test-tone.wav") {
                    console.error("Unexpected selected track:", app.currentTrackName)
                    Qt.exit(8)
                    return
                }
                root.stage = 2
            } else if (root.stage === 2) {
                if (app.mediaError.length > 0) {
                    console.error("Qt Multimedia decode failed:", app.mediaError)
                    Qt.exit(9)
                    return
                }
                if (player.duration <= 0 || !player.hasAudio || !player.seekable)
                    return
                player.play()
                root.stage = 3
            } else if (root.stage === 3) {
                if (player.playbackState !== MediaPlayer.PlayingState)
                    return
                player.setPosition(1000)
                root.stage = 4
            } else if (root.stage === 4) {
                if (player.position < 900)
                    return
                player.pause()
                if (player.playbackState !== MediaPlayer.PausedState) {
                    console.error("Music player did not pause")
                    Qt.exit(10)
                    return
                }
                app.shuffleEnabled = true
                if (!app.shuffleEnabled) {
                    console.error("Shuffle control did not update its state")
                    Qt.exit(11)
                    return
                }
                app.cycleRepeatMode()
                app.cycleRepeatMode()
                if (app.repeatMode !== 2) {
                    console.error("Repeat mode cycle failed")
                    Qt.exit(12)
                    return
                }
                console.log("WindowCard a chargé Musique; dossier local listé, WAV décodé, lecture/pause/seek fonctionnels à volume muet.")
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 12000
        running: true
        onTriggered: {
            console.error("Music player smoke test timed out at stage", root.stage)
            Qt.exit(13)
        }
    }
}
