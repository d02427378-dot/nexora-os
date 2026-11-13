import QtQuick 2.15
import Qt.labs.settings 1.0 as LabSettings

Item {
    id: root
    property var restoredShell: null

    LabSettings.Settings {
        id: savedSettings
        category: "Preferences"
        fileName: "/tmp/nexora-settings-persistence-smoke.ini"
    }

    Timer {
        id: verifyTimer
        interval: 50
        repeat: true
        onTriggered: {
            if (!root.restoredShell)
                return
            var valid = root.restoredShell.currentTheme === "Nebula"
                    && root.restoredShell.gamerMode === true
                    && root.restoredShell.reduceMotion === true
            if (!valid) {
                console.error("NexoraShell n’a pas restauré les préférences du fichier QSettings")
                Qt.exit(3)
                return
            }
            console.log("Le vrai NexoraShell a restauré thème, Mode Gamer et réduction des animations depuis QSettings; fichier temporaire isolé.")
            root.restoredShell.close()
            root.restoredShell.destroy()
            Qt.exit(0)
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("Timed out waiting for NexoraShell preferences")
            Qt.exit(4)
        }
    }

    Component.onCompleted: {
        savedSettings.setValue("themeName", "Nebula")
        savedSettings.setValue("gamerModeEnabled", true)
        savedSettings.setValue("reducedMotionEnabled", true)
        savedSettings.sync()
        var component = Qt.createComponent(Qt.resolvedUrl("../../src/desktop/NexoraShell.qml"))
        if (component.status !== Component.Ready) {
            console.error("Could not load NexoraShell:", component.errorString())
            Qt.exit(2)
            return
        }
        root.restoredShell = component.createObject(null, { "preferencesFileName": savedSettings.fileName })
        if (!root.restoredShell) {
            console.error("Could not instantiate NexoraShell")
            Qt.exit(5)
            return
        }
        verifyTimer.start()
    }
}
