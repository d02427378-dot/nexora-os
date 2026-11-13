import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Nexora.System 1.0

Item {
    id: monitorApp
    objectName: "nexoraMonitorApp"
    required property var shell
    property alias monitorBackend: backend
    property var filteredProcesses: []

    SystemMonitorBackend {
        id: backend
        objectName: "systemMonitorBackend"
        onProcessesChanged: monitorApp.updateProcessFilter()
    }

    Component.onCompleted: updateProcessFilter()

    function updateProcessFilter() {
        var query = processFilter.text.trim().toLowerCase()
        var source = backend.processes
        var visible = []
        for (var i = 0; i < source.length; ++i) {
            var entry = source[i]
            if (query.length === 0 || (entry.name + " " + entry.pid).toLowerCase().indexOf(query) !== -1)
                visible.push(entry)
        }
        filteredProcesses = visible
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Moniteur système"; color: shell.palette.text; font.pixelSize: 19; font.bold: true }
                Text { text: "Ressources Linux et processus · actualisé " + backend.lastUpdated; color: shell.palette.muted; font.pixelSize: 9 }
            }
            Button {
                text: "Actualiser"
                onClicked: backend.refresh()
                background: Rectangle { radius: 9; color: parent.down ? shell.palette.hover : shell.palette.raised; border.color: shell.palette.border }
                contentItem: Text { text: parent.text; color: shell.palette.text; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: shell.palette.surface
                border.color: shell.palette.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 5
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU"; color: shell.palette.muted; font.pixelSize: 10; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: backend.cpuUsagePercent.toFixed(1) + "%"; color: shell.palette.cyan; font.pixelSize: 16; font.bold: true; font.family: "monospace" }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 7
                        radius: 4
                        color: shell.palette.raised
                        Rectangle { width: parent.width * Math.max(0, Math.min(100, backend.cpuUsagePercent)) / 100; height: parent.height; radius: 4; color: shell.palette.cyan }
                    }
                    Text { text: "occupation globale"; color: shell.palette.muted; font.pixelSize: 8 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: shell.palette.surface
                border.color: shell.palette.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 5
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Mémoire"; color: shell.palette.muted; font.pixelSize: 10; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: backend.memoryUsagePercent.toFixed(1) + "%"; color: shell.palette.violet; font.pixelSize: 16; font.bold: true; font.family: "monospace" }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 7
                        radius: 4
                        color: shell.palette.raised
                        Rectangle { width: parent.width * Math.max(0, Math.min(100, backend.memoryUsagePercent)) / 100; height: parent.height; radius: 4; color: shell.palette.violet }
                    }
                    Text { text: monitorApp.formatBytes(backend.memoryUsedBytes) + " utilisés / " + monitorApp.formatBytes(backend.memoryTotalBytes); color: shell.palette.muted; font.pixelSize: 8 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: shell.palette.surface
                border.color: shell.palette.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 4
                    Text { text: "Système"; color: shell.palette.muted; font.pixelSize: 10; font.bold: true }
                    Text { text: backend.processCount + " processus · uptime " + backend.uptimeText; color: shell.palette.text; font.pixelSize: 11; font.bold: true }
                    Text { text: "Données lues dans /proc"; color: shell.palette.muted; font.pixelSize: 8 }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: processFilter
                objectName: "monitorProcessFilter"
                Layout.fillWidth: true
                placeholderText: "Filtrer par nom ou PID…"
                color: shell.palette.text
                placeholderTextColor: shell.palette.muted
                selectByMouse: true
                leftPadding: 11
                onTextChanged: monitorApp.updateProcessFilter()
                background: Rectangle { radius: 9; color: shell.palette.raised; border.color: processFilter.activeFocus ? shell.palette.cyan : shell.palette.border }
            }
            Text { text: "LECTURE SEULE"; color: shell.palette.good; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1 }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 31
            radius: 8
            color: shell.palette.raised
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                Text { Layout.preferredWidth: 65; text: "PID"; color: shell.palette.muted; font.pixelSize: 8; font.bold: true }
                Text { Layout.fillWidth: true; text: "PROCESSUS"; color: shell.palette.muted; font.pixelSize: 8; font.bold: true }
                Text { Layout.preferredWidth: 68; text: "CPU"; color: shell.palette.muted; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignRight }
                Text { Layout.preferredWidth: 78; text: "MÉMOIRE"; color: shell.palette.muted; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignRight }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: processList
                anchors.fill: parent
                clip: true
                spacing: 3
                model: monitorApp.filteredProcesses
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: processList.width
                    height: 33
                    radius: 7
                    color: index % 2 === 0 ? shell.palette.surface : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text { Layout.preferredWidth: 65; text: modelData.pid; color: shell.palette.muted; font.pixelSize: 9; font.family: "monospace" }
                        Text { Layout.fillWidth: true; text: modelData.name; color: shell.palette.text; font.pixelSize: 10; elide: Text.ElideRight }
                        Text { Layout.preferredWidth: 68; text: Number(modelData.cpuPercent).toFixed(2) + "%"; color: shell.palette.cyan; font.pixelSize: 9; font.family: "monospace"; horizontalAlignment: Text.AlignRight }
                        Text { Layout.preferredWidth: 78; text: monitorApp.formatBytes(modelData.memoryBytes); color: shell.palette.violet; font.pixelSize: 9; font.family: "monospace"; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: monitorApp.filteredProcesses.length === 0
                text: "Aucun processus ne correspond à ce filtre."
                color: shell.palette.muted
                font.pixelSize: 10
            }
        }

        Text {
            Layout.fillWidth: true
            text: backend.statusMessage + " · aucune action d’arrêt, suspension ou modification système."
            color: shell.palette.muted
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }

    function formatBytes(bytes) {
        var value = Number(bytes)
        if (!isFinite(value) || value < 0)
            return "—"
        if (value >= 1024 * 1024 * 1024)
            return (value / (1024 * 1024 * 1024)).toFixed(1) + " Gio"
        if (value >= 1024 * 1024)
            return (value / (1024 * 1024)).toFixed(1) + " Mio"
        if (value >= 1024)
            return (value / 1024).toFixed(0) + " Kio"
        return value.toFixed(0) + " o"
    }
}
