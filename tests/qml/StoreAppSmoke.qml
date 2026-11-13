import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1050
    height: 720
    visible: true
    title: "Nexora Store smoke test"
    property int stage: 0
    property string candidatePackage: ""

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

    property var storeWindow: null

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
        storeWindow = component.createObject(root.contentItem, {
            shell: fakeShell,
            descriptor: {
                uid: 1400,
                appId: "store",
                title: "Nexora Store",
                glyph: "APP",
                workspace: 0,
                x: 20,
                y: 20,
                width: 950,
                height: 640
            },
            x: 20,
            y: 20,
            width: 950,
            height: 640
        })
        if (!storeWindow) {
            console.error("Store WindowCard instance failed")
            Qt.exit(3)
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            var app = root.findNamed(root.contentItem, "nexoraSoftwareCenter")
            if (!app)
                return
            var backend = app.backendForTests
            if (root.stage === 0 && !backend.busy && backend.packages.length === 12) {
                var availableCount = 0
                var sawVlc = false
                var candidate = ""
                for (var i = 0; i < backend.packages.length; ++i) {
                    var pkg = backend.packages[i]
                    if (pkg.available || pkg.installed)
                        availableCount += 1
                    if (pkg.id === "vlc")
                        sawVlc = pkg.available || pkg.installed
                    if (candidate.length === 0 && pkg.available && !pkg.installed)
                        candidate = pkg.id
                }
                if (availableCount === 0 || !sawVlc) {
                    console.error("APT index scan did not report the expected VLC package")
                    Qt.exit(4)
                    return
                }
                if (backend.isCatalogPackage("bash") || backend.isCatalogPackage("pkexec")) {
                    console.error("Core system packages leaked into the app catalogue")
                    Qt.exit(5)
                    return
                }
                if (backend.confirmInstall("vlc") || backend.confirmRemove("vlc") || backend.previewInstall("bash")) {
                    console.error("A privileged mutation was accepted without a valid simulation")
                    Qt.exit(6)
                    return
                }
                if (candidate.length === 0) {
                    console.log("Store a chargé 12 entrées et les états APT; aucun candidat non installé, simulation ignorée; aucune mutation exécutée.")
                    Qt.exit(0)
                    return
                }
                root.candidatePackage = candidate
                if (!backend.previewInstall(candidate)) {
                    console.error("Could not start read-only APT simulation for", candidate)
                    Qt.exit(7)
                    return
                }
                root.stage = 1
            } else if (root.stage === 1 && backend.simulationReady) {
                if (backend.simulationPackage !== root.candidatePackage || backend.simulationAction !== "install" || backend.simulationOutput.length === 0) {
                    console.error("APT simulation summary did not match the selected package")
                    Qt.exit(8)
                    return
                }
                var dialog = app.confirmationDialogForTests
                if (!dialog || !dialog.visible) {
                    console.error("Store did not display the transaction confirmation dialog")
                    Qt.exit(9)
                    return
                }
                if (backend.confirmInstall("bash") || backend.confirmRemove(root.candidatePackage)) {
                    console.error("Backend accepted a mismatched confirmation payload")
                    Qt.exit(10)
                    return
                }
                console.log("Store a chargé 12 entrées APT et présenté la simulation de", root.candidatePackage, "; le dialogue a été vérifié, sans confirmer l’installation.")
                dialog.close()
                Qt.exit(0)
            }
        }
    }

    Timer {
        interval: 20000
        running: true
        onTriggered: {
            console.error("Store APT smoke test timed out; backend busy:", root.stage)
            Qt.exit(11)
        }
    }
}
