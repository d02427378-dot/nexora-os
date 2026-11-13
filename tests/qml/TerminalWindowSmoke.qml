import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1000
    height: 720
    visible: true
    title: "Nexora Terminal smoke test"

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

    property var terminalCard: null
    property bool commandSent: false

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
        terminalCard = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 999,
                appId: "terminal",
                title: "Terminal",
                glyph: ">_",
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
        if (!terminalCard) {
            console.error("WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 60
        repeat: true
        running: true
        onTriggered: {
            var input = root.findNamed(root.contentItem, "terminalCommandInput")
            var output = root.findNamed(root.contentItem, "terminalOutput")
            if (!input || !output)
                return
            if (!root.commandSent) {
                input.text = "printf 'NEXORA_TERMINAL_UI_SMOKE\\n'"
                input.accepted()
                root.commandSent = true
                return
            }
            if (output.text.indexOf("NEXORA_TERMINAL_UI_SMOKE") >= 0) {
                console.log("TerminalApp a exécuté printf dans Bash.")
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("Terminal UI smoke test timed out")
            Qt.exit(4)
        }
    }
}
