import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1120
    height: 760
    visible: true
    title: "Nexora Image editor smoke test"
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

    property var imageWindow: null

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
        imageWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1100,
                appId: "image",
                title: "Images",
                glyph: "IMG",
                workspace: 0,
                x: 20,
                y: 20,
                width: 1020,
                height: 690
            },
            x: 20,
            y: 20,
            width: 1020,
            height: 690
        })
        if (!imageWindow) {
            console.error("WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            var app = root.findNamed(root.contentItem, "nexoraImageEditor")
            var preview = root.findNamed(root.contentItem, "imagePreview")
            if (!app)
                return
            var backend = app.backendForTests
            if (root.stage === 0) {
                var fixtureUrl = Qt.resolvedUrl("../../tests/fixtures/images/checker.png").toString()
                if (!backend.openImage(fixtureUrl)) {
                    console.error("Image fixture failed to load:", backend.statusMessage)
                    Qt.exit(4)
                    return
                }
                if (backend.imageWidth !== 3 || backend.imageHeight !== 2) {
                    console.error("Unexpected fixture dimensions")
                    Qt.exit(5)
                    return
                }
                root.stage = 1
            } else if (root.stage === 1) {
                if (!preview || preview.status !== Image.Ready)
                    return
                backend.rotateRight()
                if (backend.imageWidth !== 2 || backend.imageHeight !== 3 || !backend.dirty) {
                    console.error("Image transform failed")
                    Qt.exit(6)
                    return
                }
                root.stage = 2
            } else if (root.stage === 2) {
                backend.undo()
                if (backend.imageWidth !== 3 || backend.imageHeight !== 2 || backend.dirty) {
                    console.error("Image undo failed")
                    Qt.exit(7)
                    return
                }
                backend.convertToGrayscale()
                if (!backend.dirty) {
                    console.error("Image grayscale transform was not marked dirty")
                    Qt.exit(8)
                    return
                }
                backend.resetToOriginal()
                if (backend.dirty) {
                    console.error("Reset did not restore original pixels")
                    Qt.exit(9)
                    return
                }
                console.log("WindowCard a chargé l’éditeur d’images; preview, rotation, Undo et Reset sont fonctionnels. Aucun fichier n’a été enregistré.")
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("Image editor UI smoke test timed out at stage", root.stage)
            Qt.exit(10)
        }
    }
}
