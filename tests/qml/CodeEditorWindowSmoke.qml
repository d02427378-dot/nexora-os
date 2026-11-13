import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1000
    height: 720
    visible: true
    title: "Nexora Code Editor smoke test"

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

    property var editorWindow: null

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
        editorWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1000,
                appId: "editor",
                title: "Éditeur",
                glyph: "</>",
                workspace: 0,
                x: 20,
                y: 20,
                width: 900,
                height: 620
            },
            x: 20,
            y: 20,
            width: 900,
            height: 620
        })
        if (!editorWindow) {
            console.error("WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 60
        repeat: true
        running: true
        onTriggered: {
            var editor = root.findNamed(root.contentItem, "nexoraCodeEditor")
            var area = root.findNamed(root.contentItem, "editorTextArea")
            var backend = editor ? editor.backendForTests : null
            if (!editor || !area || !backend)
                return
            if (backend.hasDocument || backend.dirty) {
                console.error("Editor smoke test expected a clean, unnamed document")
                Qt.exit(4)
                return
            }
            area.text = "// mémoire seulement\nconst nexoraEditorSmoke = true;\n"
            if (backend.dirty && backend.content.indexOf("nexoraEditorSmoke") >= 0) {
                console.log("WindowCard a chargé CodeEditorApp et synchronisé son tampon sans écrire de fichier.")
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("Code editor UI smoke test timed out")
            Qt.exit(5)
        }
    }
}
