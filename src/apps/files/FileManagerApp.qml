import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.folderlistmodel 2.15
import Qt.labs.platform 1.0

Item {
    id: fileManager
    objectName: "nexoraFileManager"
    required property var shell
    property string initialFolder: ""
    property string selectedUrl: ""
    property string selectedName: ""
    property bool selectedIsDir: false
    property bool showHiddenFiles: false
    property string statusMessage: ""

    property alias entryCount: folderModel.count
    property alias currentFolderUrl: folderModel.folder
    property alias modelStatus: folderModel.status

    FolderListModel {
        id: folderModel
        folder: fileManager.initialFolder.length > 0
                ? fileManager.initialFolder
                : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        showFiles: true
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: fileManager.showHiddenFiles
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortReversed: false
        nameFilters: filterField.text.trim().length > 0
                     ? ["*" + filterField.text.trim() + "*"]
                     : ["*"]
        onFolderChanged: {
            locationField.text = folder.toString()
            fileManager.selectedUrl = ""
            fileManager.selectedName = ""
            fileManager.statusMessage = ""
        }
        onStatusChanged: {
            if (status === FolderListModel.Loading)
                fileManager.statusMessage = "Lecture du dossier…"
            else if (status === FolderListModel.Ready)
                fileManager.statusMessage = count + " éléments"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            ToolButton {
                text: "‹"
                enabled: folderModel.folder.toString() !== folderModel.parentFolder.toString()
                onClicked: fileManager.goParent()
                ToolTip.visible: hovered
                ToolTip.text: "Dossier parent"
            }
            ToolButton {
                text: "⌂"
                onClicked: fileManager.goHome()
                ToolTip.visible: hovered
                ToolTip.text: "Dossier personnel"
            }
            TextField {
                id: locationField
                objectName: "fileLocationField"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                text: folderModel.folder.toString()
                placeholderText: "Chemin absolu ou URL file://"
                color: fileManager.shell.palette.text
                placeholderTextColor: fileManager.shell.palette.muted
                selectByMouse: true
                leftPadding: 10
                background: Rectangle {
                    radius: 9
                    color: fileManager.shell.palette.raised
                    border.color: locationField.activeFocus ? fileManager.shell.palette.cyan : fileManager.shell.palette.border
                }
                onAccepted: fileManager.navigateTo(text)
            }
            Button {
                text: "Aller"
                onClicked: fileManager.navigateTo(locationField.text)
                background: Rectangle { radius: 9; color: fileManager.shell.palette.indigo }
                contentItem: Text {
                    text: "Aller"; color: "#ffffff"; font.pixelSize: 10; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: filterField
                objectName: "fileFilterField"
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                placeholderText: "Filtrer ce dossier…"
                color: fileManager.shell.palette.text
                placeholderTextColor: fileManager.shell.palette.muted
                leftPadding: 10
                background: Rectangle {
                    radius: 9
                    color: fileManager.shell.palette.raised
                    border.color: fileManager.shell.palette.border
                }
            }
            Button {
                id: hiddenToggle
                text: fileManager.showHiddenFiles ? "Masquer les fichiers cachés" : "Afficher les fichiers cachés"
                onClicked: fileManager.showHiddenFiles = !fileManager.showHiddenFiles
                background: Rectangle { radius: 9; color: fileManager.shell.palette.raised; border.color: fileManager.shell.palette.border }
                contentItem: Text {
                    text: hiddenToggle.text; color: fileManager.shell.palette.text; font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                id: openButton
                text: "Ouvrir"
                enabled: fileManager.selectedUrl.length > 0
                onClicked: fileManager.openSelected()
                background: Rectangle { radius: 9; color: fileManager.selectedUrl.length > 0 ? fileManager.shell.palette.hover : fileManager.shell.palette.raised; border.color: fileManager.shell.palette.border }
                contentItem: Text {
                    text: openButton.text; color: fileManager.shell.palette.text; font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: fileManager.shell.palette.background
            border.color: fileManager.shell.palette.border
            clip: true

            ListView {
                id: fileList
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                spacing: 3
                model: folderModel
                delegate: Rectangle {
                    required property string fileName
                    required property url fileURL
                    required property bool fileIsDir
                    required property double fileSize
                    required property int index
                    width: fileList.width
                    height: 46
                    radius: 9
                    color: fileManager.selectedUrl === fileURL.toString() ? fileManager.shell.palette.hover : fileHover.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent"
                    border.color: fileManager.selectedUrl === fileURL.toString() ? fileManager.shell.palette.indigo : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 9
                            color: fileIsDir ? Qt.rgba(255 / 255, 212 / 255, 121 / 255, 0.12) : Qt.rgba(65 / 255, 231 / 255, 1, 0.10)
                            Text {
                                anchors.centerIn: parent
                                text: fileIsDir ? "DIR" : fileName.split(".").pop().toUpperCase().slice(0, 3)
                                color: fileIsDir ? "#ffd479" : fileManager.shell.palette.cyan
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: fileName
                                color: fileManager.shell.palette.text
                                font.pixelSize: 11
                                font.bold: fileIsDir
                                elide: Text.ElideRight
                            }
                            Text {
                                text: fileIsDir ? "Dossier" : fileManager.formatSize(fileSize)
                                color: fileManager.shell.palette.muted
                                font.pixelSize: 9
                            }
                        }
                        Text {
                            text: fileIsDir ? "›" : ""
                            color: fileManager.shell.palette.cyan
                            font.pixelSize: 17
                        }
                    }

                    MouseArea {
                        id: fileHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            fileManager.selectedUrl = fileURL.toString()
                            fileManager.selectedName = fileName
                            fileManager.selectedIsDir = fileIsDir
                            fileManager.statusMessage = fileIsDir ? "Dossier sélectionné : double-cliquez pour entrer." : "Fichier sélectionné : ouvrez-le avec l’application associée."
                        }
                        onDoubleClicked: fileManager.openSelected()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: folderModel.status === FolderListModel.Ready && folderModel.count === 0
                    text: "Ce dossier ne contient aucun élément visible."
                    color: fileManager.shell.palette.muted
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: fileManager.statusMessage
                color: fileManager.shell.palette.muted
                font.pixelSize: 9
                elide: Text.ElideRight
            }
            Text {
                text: fileManager.selectedName
                color: fileManager.shell.palette.cyan
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    function navigateTo(input) {
        var target = String(input).trim()
        if (target.length === 0) {
            statusMessage = "Indiquez un chemin de dossier."
            return false
        }
        if (target.charAt(0) === "/")
            target = "file://" + target
        if (target.indexOf("file:///") !== 0) {
            statusMessage = "Seuls les chemins locaux ou les URL file:// sont pris en charge."
            return false
        }
        folderModel.folder = target
        return true
    }

    function goParent() {
        if (folderModel.parentFolder.toString() !== folderModel.folder.toString())
            folderModel.folder = folderModel.parentFolder
    }

    function goHome() {
        folderModel.folder = StandardPaths.writableLocation(StandardPaths.HomeLocation)
    }

    function containsName(name) {
        for (var i = 0; i < folderModel.count; ++i) {
            if (folderModel.get(i, "fileName") === name)
                return true
        }
        return false
    }

    function openSelected() {
        if (selectedUrl.length === 0)
            return false
        if (selectedIsDir) {
            folderModel.folder = selectedUrl
            return true
        }
        if (!isSafeOpenFile(selectedName)) {
            statusMessage = "Ouverture bloquée par sécurité : type de fichier non autorisé."
            return false
        }
        Qt.openUrlExternally(selectedUrl)
        statusMessage = "Ouverture demandée à l’application associée."
        return true
    }

    function isSafeOpenFile(name) {
        var dot = name.lastIndexOf(".")
        if (dot < 0)
            return false
        var suffix = name.substring(dot + 1).toLowerCase()
        var allowed = ["txt", "md", "csv", "json", "xml", "yaml", "yml", "toml", "ini", "log", "conf", "css", "js", "qml", "pdf", "png", "jpg", "jpeg", "gif", "webp", "svg", "mp3", "wav", "flac", "ogg", "mp4", "webm", "odt", "docx", "xlsx", "pptx"]
        return allowed.indexOf(suffix) !== -1
    }

    function formatSize(bytes) {
        if (bytes < 1024)
            return bytes + " o"
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " Ko"
        return (bytes / (1024 * 1024)).toFixed(1) + " Mo"
    }
}
