import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: smokeWindow
    visible: true
    width: 980
    height: 700
    title: "Nexora browser integration smoke test"
    color: "#090c16"

    property var card: null
    property var browserItem: null

    QtObject {
        id: testShell
        property int zCounter: 20
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
        function closeWindow(uid) { }
    }

    Component.onCompleted: {
        var component = Qt.createComponent(Qt.resolvedUrl("../../src/desktop/WindowCard.qml"))
        if (component.status !== Component.Ready) {
            console.error(component.errorString())
            Qt.exit(2)
            return
        }
        var descriptor = {
            uid: 77,
            appId: "browser",
            title: "Navigateur",
            glyph: "WEB",
            workspace: 0,
            x: 20,
            y: 30,
            width: 760,
            height: 520
        }
        card = component.createObject(smokeWindow.contentItem, {
            shell: testShell,
            descriptor: descriptor
        })
        if (card === null) {
            console.error("La carte Navigateur n’a pas pu être créée.")
            Qt.exit(3)
            return
        }
        startNavigation.start()
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
        if (node.children) {
            for (var i = 0; i < node.children.length; ++i) {
                var found = findNamed(node.children[i], targetName)
                if (found)
                    return found
            }
        }
        return null
    }

    Timer {
        id: startNavigation
        interval: 500
        onTriggered: {
            browserItem = smokeWindow.findNamed(card, "nexoraBrowser")
            if (!browserItem) {
                console.error("BrowserApp n’a pas été chargé par WindowCard.")
                Qt.exit(4)
                return
            }
            if (!browserItem.navigate("http://127.0.0.1:18765/health.html")) {
                console.error("Le navigateur a refusé l’adresse HTTP locale du test.")
                Qt.exit(5)
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            if (browserItem && browserItem.pageLoaded) {
                if (browserItem.pageTitle !== "Nexora smoke page") {
                    console.error("Titre inattendu : " + browserItem.pageTitle)
                    Qt.exit(6)
                } else {
                    console.log("Chargement HTTP local confirmé par Qt WebEngine.")
                    Qt.exit(0)
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("Timeout pendant le chargement HTTP local.")
            Qt.exit(7)
        }
    }
}
