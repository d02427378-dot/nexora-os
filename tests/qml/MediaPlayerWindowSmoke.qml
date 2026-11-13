import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtMultimedia 6.4

ApplicationWindow {
    id: root
    width: 1100
    height: 760
    visible: true
    title: "Nexora Media smoke test"
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

    property var mediaWindow: null

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
        mediaWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1200,
                appId: "media",
                title: "Média",
                glyph: "PLAY",
                workspace: 0,
                x: 20,
                y: 20,
                width: 1000,
                height: 680
            },
            x: 20,
            y: 20,
            width: 1000,
            height: 680
        })
        if (!mediaWindow) {
            console.error("WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            var app = root.findNamed(root.contentItem, "nexoraMediaPlayer")
            if (!app)
                return
            var player = app.playerForTests
            if (root.stage === 0) {
                app.audioForTests.volume = 0
                var fixture = Qt.resolvedUrl("../../tests/fixtures/media/test-tone.wav").toString()
                if (!app.openLocalMedia(fixture)) {
                    console.error("Local WAV rejected:", app.mediaError)
                    Qt.exit(4)
                    return
                }
                root.stage = 1
            } else if (root.stage === 1) {
                if (app.mediaError.length > 0) {
                    console.error("Qt Multimedia decode failed:", app.mediaError)
                    Qt.exit(5)
                    return
                }
                if (player.duration <= 0 || !player.hasAudio)
                    return
                if (!player.seekable) {
                    console.error("WAV fixture unexpectedly is not seekable")
                    Qt.exit(6)
                    return
                }
                player.play()
                root.stage = 2
            } else if (root.stage === 2) {
                if (player.playbackState !== MediaPlayer.PlayingState)
                    return
                player.setPosition(1000)
                root.stage = 3
            } else if (root.stage === 3) {
                if (player.position < 900)
                    return
                player.pause()
                if (player.playbackState !== MediaPlayer.PausedState) {
                    console.error("MediaPlayer did not pause")
                    Qt.exit(7)
                    return
                }
                console.log("WindowCard a chargé Qt Multimedia; WAV décodé, lecture/pause/seek fonctionnels à volume muet.")
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 12000
        running: true
        onTriggered: {
            console.error("Media player smoke test timed out at stage", root.stage)
            Qt.exit(8)
        }
    }
}
