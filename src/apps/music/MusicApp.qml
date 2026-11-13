import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.folderlistmodel 2.15
import Qt.labs.platform 1.0 as Labs
import QtMultimedia 6.4

Item {
    id: musicApp
    objectName: "nexoraMusicApp"
    required property var shell

    property string libraryFolder: Labs.StandardPaths.writableLocation(Labs.StandardPaths.MusicLocation).toString()
    property string currentTrackName: "Aucune piste"
    property string currentTrackUrl: ""
    property string mediaError: ""
    property string libraryMessage: "Choisissez votre dossier de musique."
    property int currentIndex: -1
    property int repeatMode: 0 // 0 : désactivé, 1 : tout, 2 : piste
    property bool shuffleEnabled: false

    property alias playerForTests: player
    property alias audioForTests: audioOutput
    property alias musicModelForTests: musicModel
    property alias trackCount: musicModel.count

    FolderListModel {
        id: musicModel
        folder: musicApp.libraryFolder
        nameFilters: ["*.mp3", "*.flac", "*.ogg", "*.opus", "*.m4a", "*.aac", "*.wav", "*.oga", "*.wma"]
        caseSensitive: false
        showFiles: true
        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortReversed: false

        onFolderChanged: {
            musicApp.currentIndex = -1
            musicApp.libraryMessage = "Lecture du dossier musical…"
        }
        onStatusChanged: {
            if (status === FolderListModel.Loading)
                musicApp.libraryMessage = "Lecture du dossier musical…"
            else if (status === FolderListModel.Ready)
                musicApp.libraryMessage = count === 0 ? "Aucun fichier audio pris en charge dans ce dossier." : count + (count === 1 ? " piste trouvée" : " pistes trouvées")
        }
    }

    MediaPlayer {
        id: player
        objectName: "nexoraMusicMediaPlayer"
        audioOutput: audioOutput
        onErrorOccurred: function(error, errorString) {
            musicApp.mediaError = errorString
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia && errorString.length > 0)
                musicApp.mediaError = errorString
            else if (mediaStatus === MediaPlayer.LoadedMedia)
                musicApp.mediaError = ""
            else if (mediaStatus === MediaPlayer.EndOfMedia)
                musicApp.advanceAfterEnd()
        }
    }

    AudioOutput {
        id: audioOutput
        volume: 0.72
    }

    Labs.FolderDialog {
        id: folderDialog
        title: "Choisir un dossier musical local"
        folder: musicApp.libraryFolder
        onAccepted: musicApp.openFolder(folder.toString())
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: Qt.rgba(65 / 255, 231 / 255, 1, 0.12)
                border.color: Qt.rgba(65 / 255, 231 / 255, 1, 0.28)
                Text { anchors.centerIn: parent; text: "♫"; color: musicApp.shell.palette.cyan; font.pixelSize: 23; font.bold: true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: "MUSIQUE"; color: musicApp.shell.palette.text; font.pixelSize: 13; font.bold: true }
                Text { text: "Bibliothèque audio locale"; color: musicApp.shell.palette.muted; font.pixelSize: 9 }
            }
            Button {
                objectName: "musicChooseFolderButton"
                text: "Choisir un dossier…"
                onClicked: folderDialog.open()
                background: Rectangle { radius: 9; color: musicApp.shell.palette.indigo }
                contentItem: Text { text: "Choisir un dossier…"; color: "#ffffff"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 8; rightPadding: 8 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: musicApp.libraryFolder.length > 0 ? musicApp.libraryFolder : "Aucun dossier sélectionné"
                color: musicApp.shell.palette.muted
                font.pixelSize: 9
                elide: Text.ElideMiddle
            }
            ToolButton {
                objectName: "musicParentFolderButton"
                text: "↑"
                enabled: musicModel.folder.toString() !== musicModel.parentFolder.toString()
                onClicked: musicApp.openFolder(musicModel.parentFolder.toString())
                ToolTip.visible: hovered
                ToolTip.text: "Dossier parent"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 230
                radius: 13
                color: musicApp.shell.palette.background
                border.color: musicApp.shell.palette.border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 7
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: "PISTES"; color: musicApp.shell.palette.muted; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.1 }
                        Text { text: musicModel.count.toString().padStart(2, "0"); color: musicApp.shell.palette.cyan; font.pixelSize: 9; font.bold: true }
                    }
                    ListView {
                        id: trackList
                        objectName: "musicTrackList"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 3
                        model: musicModel
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            required property string fileName
                            required property url fileURL
                            required property int index
                            width: trackList.width
                            height: 44
                            radius: 9
                            color: musicApp.currentTrackUrl === fileURL.toString() ? musicApp.shell.palette.hover : trackMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent"
                            border.color: musicApp.currentTrackUrl === fileURL.toString() ? musicApp.shell.palette.indigo : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 8
                                    color: Qt.rgba(119 / 255, 113 / 255, 1, 0.12)
                                    Text { anchors.centerIn: parent; text: musicApp.currentTrackUrl === fileURL.toString() && player.playbackState === MediaPlayer.PlayingState ? "♫" : "♪"; color: musicApp.shell.palette.cyan; font.pixelSize: 14 }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: fileName
                                    color: musicApp.shell.palette.text
                                    font.pixelSize: 10
                                    font.bold: musicApp.currentTrackUrl === fileURL.toString()
                                    elide: Text.ElideRight
                                }
                                Text { text: fileName.split(".").pop().toUpperCase(); color: musicApp.shell.palette.muted; font.pixelSize: 8 }
                            }
                            MouseArea {
                                id: trackMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: musicApp.playTrack(index)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 28
                            visible: musicModel.status === FolderListModel.Ready && musicModel.count === 0
                            text: "Aucune piste ici. Choisissez un autre dossier ou parcourez le dossier parent."
                            color: musicApp.shell.palette.muted
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 228
                Layout.fillHeight: true
                Layout.minimumWidth: 180
                radius: 13
                color: musicApp.shell.palette.raised
                border.color: musicApp.shell.palette.border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 7
                    Item { Layout.fillHeight: true; Layout.minimumHeight: 0 }
                    Rectangle {
                        id: albumDisc
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 118
                        Layout.preferredHeight: 118
                        radius: width / 2
                        color: "#0b1020"
                        border.width: 2
                        border.color: musicApp.shell.palette.cyan
                        Rectangle { anchors.fill: parent; anchors.margins: 13; radius: width / 2; color: Qt.rgba(119 / 255, 113 / 255, 1, 0.15); border.color: musicApp.shell.palette.indigo }
                        Rectangle { anchors.centerIn: parent; width: 28; height: 28; radius: width / 2; color: musicApp.shell.palette.cyan; Text { anchors.centerIn: parent; text: "NX"; color: "#08101b"; font.pixelSize: 8; font.bold: true } }
                        RotationAnimation on rotation { running: player.playbackState === MediaPlayer.PlayingState; from: 0; to: 360; duration: 12000; loops: Animation.Infinite }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: musicApp.currentTrackName
                        color: musicApp.shell.palette.text
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                    }
                    Text {
                        Layout.fillWidth: true
                        text: musicApp.mediaError.length > 0 ? "Erreur de décodage : " + musicApp.mediaError : player.source.toString().length > 0 ? "Fichier audio local" : "Choisissez une piste dans la bibliothèque"
                        color: musicApp.mediaError.length > 0 ? "#ff9f9f" : musicApp.shell.palette.muted
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillHeight: true; Layout.minimumHeight: 0 }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Slider {
                id: seekSlider
                objectName: "musicSeekSlider"
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, player.duration)
                value: player.position
                enabled: player.seekable && player.duration > 0
                onMoved: player.setPosition(value)
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: musicApp.formatTime(player.position); color: musicApp.shell.palette.muted; font.pixelSize: 8 }
                Item { Layout.fillWidth: true }
                Text { text: musicApp.formatTime(player.duration); color: musicApp.shell.palette.muted; font.pixelSize: 8 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ToolButton {
                objectName: "musicShuffleButton"
                text: musicApp.shuffleEnabled ? "⤨" : "⇄"
                onClicked: musicApp.shuffleEnabled = !musicApp.shuffleEnabled
                ToolTip.visible: hovered
                ToolTip.text: musicApp.shuffleEnabled ? "Désactiver la lecture aléatoire" : "Activer la lecture aléatoire"
            }
            ToolButton { objectName: "musicPreviousButton"; text: "|◀"; enabled: musicModel.count > 0; onClicked: musicApp.playPrevious(); ToolTip.visible: hovered; ToolTip.text: "Piste précédente" }
            Button {
                objectName: "musicPlayPauseButton"
                Layout.preferredWidth: 42
                text: player.playbackState === MediaPlayer.PlayingState ? "Ⅱ" : "▶"
                enabled: musicApp.currentTrackUrl.length > 0
                onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
                background: Rectangle { radius: 12; color: musicApp.shell.palette.indigo }
                contentItem: Text { text: parent.text; color: "#ffffff"; font.pixelSize: 15; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            ToolButton { objectName: "musicNextButton"; text: "▶|"; enabled: musicModel.count > 0; onClicked: musicApp.playNext(); ToolTip.visible: hovered; ToolTip.text: "Piste suivante" }
            ToolButton {
                objectName: "musicRepeatButton"
                text: musicApp.repeatMode === 0 ? "↻" : musicApp.repeatMode === 1 ? "↻·" : "↻¹"
                onClicked: musicApp.cycleRepeatMode()
                ToolTip.visible: hovered
                ToolTip.text: musicApp.repeatMode === 0 ? "Répétition désactivée" : musicApp.repeatMode === 1 ? "Répéter toute la bibliothèque" : "Répéter cette piste"
            }
            Item { Layout.fillWidth: true }
            Text { text: "VOL"; color: musicApp.shell.palette.muted; font.pixelSize: 8; font.bold: true }
            Slider {
                id: volumeSlider
                objectName: "musicVolumeSlider"
                Layout.preferredWidth: 90
                from: 0
                to: 1
                value: audioOutput.volume
                onMoved: audioOutput.volume = value
            }
            ToolButton {
                objectName: "musicMuteButton"
                text: audioOutput.muted ? "×" : "◖"
                onClicked: audioOutput.muted = !audioOutput.muted
                ToolTip.visible: hovered
                ToolTip.text: audioOutput.muted ? "Rétablir le son" : "Couper le son"
            }
        }

        Text {
            Layout.fillWidth: true
            text: musicApp.mediaError.length > 0 ? musicApp.mediaError : musicApp.libraryMessage + " · Audio local uniquement · codecs selon plugins Qt/FFmpeg"
            color: musicApp.mediaError.length > 0 ? "#ff9f9f" : musicApp.shell.palette.muted
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }

    function openFolder(input) {
        var target = String(input).trim()
        if (target.charAt(0) === "/")
            target = "file://" + target
        if (target.indexOf("file:///") !== 0) {
            libraryMessage = "Sécurité : seuls les dossiers locaux sont acceptés."
            return false
        }
        player.stop()
        player.source = ""
        currentIndex = -1
        currentTrackName = "Aucune piste"
        currentTrackUrl = ""
        mediaError = ""
        libraryFolder = target
        libraryMessage = "Lecture du dossier musical…"
        return true
    }

    function playTrack(index) {
        if (index < 0 || index >= musicModel.count)
            return false
        var targetUrl = musicModel.get(index, "fileURL")
        var targetName = musicModel.get(index, "fileName")
        if (String(targetUrl).indexOf("file:///") !== 0) {
            mediaError = "Sécurité : seule une piste locale peut être ouverte."
            return false
        }
        currentIndex = index
        currentTrackName = String(targetName)
        currentTrackUrl = String(targetUrl)
        mediaError = ""
        if (player.source.toString() === currentTrackUrl) {
            player.setPosition(0)
            player.play()
        } else {
            player.stop()
            player.source = targetUrl
            player.play()
        }
        return true
    }

    function playNext() {
        if (musicModel.count === 0)
            return false
        if (currentIndex < 0 || currentIndex >= musicModel.count)
            return playTrack(0)
        if (shuffleEnabled && musicModel.count > 1) {
            var randomIndex = Math.floor(Math.random() * (musicModel.count - 1))
            if (randomIndex >= currentIndex)
                randomIndex += 1
            return playTrack(randomIndex)
        }
        if (currentIndex + 1 < musicModel.count)
            return playTrack(currentIndex + 1)
        if (repeatMode === 1)
            return playTrack(0)
        player.stop()
        return true
    }

    function playPrevious() {
        if (musicModel.count === 0)
            return false
        if (currentIndex < 0 || currentIndex >= musicModel.count)
            return playTrack(0)
        if (player.position > 3000) {
            player.setPosition(0)
            return true
        }
        if (shuffleEnabled && musicModel.count > 1) {
            var randomIndex = Math.floor(Math.random() * (musicModel.count - 1))
            if (randomIndex >= currentIndex)
                randomIndex += 1
            return playTrack(randomIndex)
        }
        if (currentIndex > 0)
            return playTrack(currentIndex - 1)
        if (repeatMode === 1)
            return playTrack(musicModel.count - 1)
        return playTrack(0)
    }

    function advanceAfterEnd() {
        if (repeatMode === 2 && currentIndex >= 0) {
            player.setPosition(0)
            player.play()
            return
        }
        if (currentIndex + 1 < musicModel.count || repeatMode === 1 || shuffleEnabled)
            playNext()
    }

    function cycleRepeatMode() {
        repeatMode = (repeatMode + 1) % 3
    }

    function formatTime(milliseconds) {
        if (!isFinite(milliseconds) || milliseconds < 0)
            return "0:00"
        var totalSeconds = Math.floor(milliseconds / 1000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }
}
