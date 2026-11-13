import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: windowCard
    required property var shell
    required property var descriptor
    objectName: "windowCard_" + descriptor.uid
    property string appId: descriptor.appId
    property bool mediaPlaying: false

    radius: 18
    color: shell.palette.surface
    border.color: shell.palette.border
    border.width: 1
    clip: true
    focus: true

    Rectangle {
        id: titleBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 48
        color: shell.palette.raised
        radius: 18
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 12
            color: parent.color
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 9
                color: Qt.rgba(119 / 255, 113 / 255, 1, 0.14)
                Text {
                    anchors.centerIn: parent
                    text: descriptor.glyph
                    color: shell.palette.cyan
                    font.pixelSize: 9
                    font.bold: true
                    font.family: "monospace"
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: descriptor.title
                    color: shell.palette.text
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    text: "Espace " + (descriptor.workspace + 1) + (appId === "browser" ? " · Qt WebEngine" : appId === "files" ? " · explorateur local" : appId === "terminal" ? " · Bash local" : appId === "editor" ? " · éditeur UTF-8" : appId === "image" ? " · édition non destructive" : appId === "media" ? " · audio/vidéo local" : appId === "music" ? " · bibliothèque audio locale" : appId === "store" ? " · catalogue APT contrôlé" : appId === "settings" ? " · préférences utilisateur" : appId === "monitor" ? " · métriques /proc en lecture seule" : appId === "games" ? " · arcade locale hors ligne" : appId === "assistant" ? " · fournisseur configurable · actions confirmées" : " · maquette d’application")
                    color: shell.palette.muted
                    font.pixelSize: 9
                }
            }
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 8
                color: closeArea.containsMouse ? "#71334a" : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeArea.containsMouse ? "#ffffff" : shell.palette.muted
                    font.pixelSize: 18
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: shell.closeWindow(descriptor.uid)
                }
                ToolTip.visible: closeArea.containsMouse
                ToolTip.text: "Fermer cette fenêtre"
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 44
            cursorShape: Qt.SizeAllCursor
            drag.target: windowCard
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: Math.max(0, windowCard.parent.width - windowCard.width)
            drag.maximumY: Math.max(0, windowCard.parent.height - windowCard.height)
            onPressed: {
                shell.zCounter += 1;
                windowCard.z = shell.zCounter;
            }
        }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 16
        sourceComponent: windowCard.componentForApp()
    }

    function componentForApp() {
        if (appId === "browser")
            return browserContent;
        if (appId === "files")
            return filesContent;
        if (appId === "editor")
            return editorContent;
        if (appId === "image")
            return imageContent;
        if (appId === "terminal")
            return terminalContent;
        if (appId === "media")
            return mediaContent;
        if (appId === "music")
            return musicContent;
        if (appId === "settings")
            return settingsContent;
        if (appId === "monitor")
            return monitorContent;
        if (appId === "games")
            return gamesContent;
        if (appId === "store")
            return storeContent;
        if (appId === "assistant")
            return assistantContent;
        return genericContent;
    }

    Component {
        id: browserContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/browser/BrowserApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: filesContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/files/FileManagerApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: editorContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/editor/CodeEditorApp.qml", {
                    "shell": windowCard.shell,
                    "initialText": windowCard.descriptor.initialText || ""
                })
        }
    }

    Component {
        id: imageContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/image/ImageEditorApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: terminalContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/terminal/TerminalApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: mediaContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/media/MediaPlayerApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: musicContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/music/MusicApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: settingsContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/settings/SettingsApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: monitorContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/monitor/TaskManagerApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: gamesContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/games/MiniGamesApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: storeContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/store/StoreApp.qml", {
                    "shell": windowCard.shell
                })
        }
    }

    Component {
        id: assistantContent
        Loader {
            anchors.fill: parent
            Component.onCompleted: setSource("../apps/assistant/AssistantApp.qml", {
                    "shell": windowCard.shell,
                    "initialPrompt": windowCard.descriptor.initialPrompt || "",
                    "backendOverride": windowCard.descriptor.backendOverride || null
                })
        }
    }

    Component {
        id: genericContent
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Item {
                Layout.fillHeight: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Prototype d’application"
                color: shell.palette.text
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "L’application dédiée sera construite dans une phase ultérieure."
                color: shell.palette.muted
                font.pixelSize: 11
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
