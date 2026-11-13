import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1180
    height: 760
    visible: true
    title: "Nexora Monitor smoke test"

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

    property var monitorWindow: null

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
        monitorWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1400,
                appId: "monitor",
                title: "Moniteur système",
                glyph: "SYS",
                workspace: 0,
                x: 20,
                y: 20,
                width: 1080,
                height: 680
            },
            x: 20,
            y: 20,
            width: 1080,
            height: 680
        })
        if (!monitorWindow) {
            console.error("Monitor WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        id: inspectTimer
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            var app = root.findNamed(root.contentItem, "nexoraMonitorApp")
            if (!app)
                return
            var backend = app.monitorBackend
            if (backend.memoryTotalBytes <= 0 || backend.memoryUsedBytes < 0
                    || backend.processCount <= 0 || backend.processes.length <= 0
                    || backend.uptimeText.length <= 0 || backend.lastUpdated.length <= 0) {
                console.error("Moniteur received invalid /proc metrics:", backend.statusMessage)
                Qt.exit(4)
                return
            }
            if (backend.cpuUsagePercent < 0 || backend.cpuUsagePercent > 100
                    || backend.memoryUsagePercent < 0 || backend.memoryUsagePercent > 100) {
                console.error("Moniteur metric is out of range")
                Qt.exit(5)
                return
            }
            var first = backend.processes[0]
            if (first.pid <= 0 || first.name.length <= 0 || first.memoryBytes < 0) {
                console.error("Moniteur process row is invalid")
                Qt.exit(6)
                return
            }
            var filter = root.findNamed(app, "monitorProcessFilter")
            if (!filter) {
                console.error("Moniteur process filter was not loaded")
                Qt.exit(7)
                return
            }
            filter.text = first.name + " " + first.pid
            if (app.filteredProcesses.length <= 0
                    || app.filteredProcesses.length !== 1 || app.filteredProcesses[0].pid !== first.pid) {
                console.error("Moniteur process filter did not restrict its result")
                Qt.exit(8)
                return
            }
            console.log("WindowCard a chargé le Moniteur: CPU/RAM/uptime et", backend.processCount, "processus lus dans /proc; filtre OK, lecture seule.")
            Qt.exit(0)
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("Task manager smoke test timed out")
            Qt.exit(9)
        }
    }
}
