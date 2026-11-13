import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Nexora.Terminal 1.0

Item {
    id: terminalApp
    objectName: "nexoraTerminal"
    required property var shell
    property string notice: ""

    TerminalBackend {
        id: backend
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 9
                Layout.preferredHeight: 9
                radius: 5
                color: backend.running ? "#ffd479" : "#6ce6b3"
            }
            Text {
                Layout.fillWidth: true
                text: backend.running ? "Commande en cours…" : backend.workingDirectory
                color: terminalApp.shell.palette.muted
                font.family: "monospace"
                font.pixelSize: 9
                elide: Text.ElideMiddle
            }
            Text {
                visible: backend.lastExitCode >= 0
                text: "code " + backend.lastExitCode
                color: backend.lastExitCode === 0 ? terminalApp.shell.palette.good : "#ff9f9f"
                font.family: "monospace"
                font.pixelSize: 9
            }
            Button {
                visible: backend.running
                text: "Annuler"
                onClicked: backend.cancel()
                background: Rectangle { radius: 8; color: "#71334a" }
                contentItem: Text {
                    text: "Annuler"
                    color: "#ffffff"
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                text: "Effacer"
                enabled: !backend.running
                onClicked: backend.clearOutput()
                background: Rectangle { radius: 8; color: terminalApp.shell.palette.raised; border.color: terminalApp.shell.palette.border }
                contentItem: Text {
                    text: "Effacer"
                    color: terminalApp.shell.palette.text
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 11
            color: terminalApp.shell.palette.background
            border.color: terminalApp.shell.palette.border
            clip: true

            ScrollView {
                id: outputScroll
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                TextArea {
                    id: outputArea
                    objectName: "terminalOutput"
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    text: backend.output
                    color: terminalApp.shell.palette.text
                    selectedTextColor: terminalApp.shell.palette.text
                    selectionColor: terminalApp.shell.palette.indigo
                    font.family: "monospace"
                    font.pixelSize: 10
                    background: null
                    onTextChanged: cursorPosition = length
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Text {
                text: "›"
                color: terminalApp.shell.palette.cyan
                font.family: "monospace"
                font.pixelSize: 18
            }
            TextField {
                id: commandInput
                objectName: "terminalCommandInput"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                enabled: !backend.running
                placeholderText: "Commande Bash…"
                color: terminalApp.shell.palette.text
                placeholderTextColor: terminalApp.shell.palette.muted
                font.family: "monospace"
                font.pixelSize: 10
                leftPadding: 10
                background: Rectangle {
                    radius: 8
                    color: terminalApp.shell.palette.raised
                    border.color: commandInput.activeFocus ? terminalApp.shell.palette.cyan : terminalApp.shell.palette.border
                }
                onAccepted: terminalApp.runCommand()
            }
            Button {
                text: backend.running ? "En cours" : "Exécuter"
                enabled: !backend.running && commandInput.text.trim().length > 0
                onClicked: terminalApp.runCommand()
                background: Rectangle { radius: 8; color: terminalApp.shell.palette.indigo }
                contentItem: Text {
                    text: "Exécuter"
                    color: "#ffffff"
                    font.pixelSize: 9
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Terminal réel : les commandes Bash s’exécutent avec les permissions de votre compte. Évitez les opérations de disque; testez Nexora en VM et sauvegardez vos données."
            color: "#ffd479"
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            visible: terminalApp.notice.length > 0
            text: terminalApp.notice
            color: terminalApp.shell.palette.muted
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }
    }

    function runCommand() {
        var command = commandInput.text
        if (command.trim().length === 0)
            return
        commandInput.text = ""
        if (!backend.execute(command))
            notice = "Une commande est déjà en cours ou la saisie est vide."
        else
            notice = ""
    }
}
