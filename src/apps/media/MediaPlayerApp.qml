import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.0 as Labs
import QtMultimedia 6.4

Item {
    id: mediaApp
    objectName: "nexoraMediaPlayer"
    required property var shell
    property alias playerForTests: mediaPlayer
    property alias audioForTests: audioOutput
    property string currentName: "Aucun média ouvert"
    property string mediaError: ""

    MediaPlayer {
        id: mediaPlayer
        objectName: "nexoraQtMediaPlayer"
        audioOutput: audioOutput
        videoOutput: videoOutput
        onErrorOccurred: function(error, errorString) {
            mediaApp.mediaError = errorString
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia && errorString.length > 0)
                mediaApp.mediaError = errorString
            else if (mediaStatus === MediaPlayer.LoadedMedia)
                mediaApp.mediaError = ""
        }
    }

    AudioOutput {
        id: audioOutput
        volume: 0.75
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Button {
                text: "Ouvrir un média…"
                onClicked: openDialog.open()
                background: Rectangle { radius: 8; color: mediaApp.shell.palette.indigo }
                contentItem: Text { text: "Ouvrir un média…"; color: "#ffffff"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: mediaApp.currentName; color: mediaApp.shell.palette.text; font.pixelSize: 11; font.bold: true; elide: Text.ElideMiddle; Layout.fillWidth: true }
                Text { text: mediaApp.statusText(); color: mediaApp.mediaError.length > 0 ? "#ff9f9f" : mediaApp.shell.palette.muted; font.pixelSize: 9; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 160
            radius: 12
            color: "#05070c"
            border.color: mediaApp.shell.palette.border
            clip: true

            VideoOutput {
                id: videoOutput
                objectName: "mediaVideoOutput"
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
                visible: mediaPlayer.hasVideo
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: !mediaPlayer.hasVideo
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 108
                    height: 108
                    radius: 28
                    color: mediaApp.shell.palette.raised
                    border.color: mediaApp.shell.palette.border
                    Text { anchors.centerIn: parent; text: "NX"; color: mediaApp.shell.palette.cyan; font.pixelSize: 34; font.bold: true }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mediaPlayer.source.toString().length > 0 ? "Lecture audio locale" : "Choisissez un fichier audio ou vidéo"
                    color: mediaApp.shell.palette.text
                    font.pixelSize: 12
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mediaPlayer.hasAudio ? "Audio · sortie système" : "WAV · MP3 · FLAC · OGG · MP4 · WebM · formats selon codecs installés"
                    color: mediaApp.shell.palette.muted
                    font.pixelSize: 9
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 9
            Text { text: mediaApp.formatTime(mediaPlayer.position); color: mediaApp.shell.palette.muted; font.family: "monospace"; font.pixelSize: 9 }
            Slider {
                id: seekSlider
                objectName: "mediaSeekSlider"
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, mediaPlayer.duration)
                value: mediaPlayer.position
                enabled: mediaPlayer.seekable && mediaPlayer.duration > 0
                onMoved: mediaPlayer.setPosition(value)
            }
            Text { text: mediaApp.formatTime(mediaPlayer.duration); color: mediaApp.shell.palette.muted; font.family: "monospace"; font.pixelSize: 9 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Item { Layout.fillWidth: true }
            Button { text: "■"; enabled: mediaPlayer.source.toString().length > 0; onClicked: { mediaPlayer.stop(); mediaPlayer.setPosition(0) } }
            Button {
                text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "Pause" : "Lecture"
                enabled: mediaPlayer.source.toString().length > 0 && mediaApp.mediaError.length === 0
                onClicked: mediaPlayer.playbackState === MediaPlayer.PlayingState ? mediaPlayer.pause() : mediaPlayer.play()
                background: Rectangle { radius: 9; color: mediaApp.shell.palette.indigo }
                contentItem: Text { text: parent.text; color: "#ffffff"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button { text: audioOutput.muted ? "Muet" : "Son"; onClicked: audioOutput.muted = !audioOutput.muted }
            Slider {
                id: volumeSlider
                objectName: "mediaVolumeSlider"
                Layout.preferredWidth: 120
                from: 0
                to: 100
                value: audioOutput.volume * 100
                onMoved: audioOutput.volume = value / 100
            }
            Text { text: Math.round(audioOutput.volume * 100) + "%"; color: mediaApp.shell.palette.muted; font.family: "monospace"; font.pixelSize: 9 }
            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            text: mediaApp.mediaError.length > 0 ? mediaApp.mediaError : "Lecture locale seulement · aucun téléchargement ni flux réseau"
            color: mediaApp.mediaError.length > 0 ? "#ff9f9f" : mediaApp.shell.palette.muted
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }

    Labs.FileDialog {
        id: openDialog
        title: "Ouvrir un fichier audio ou vidéo local"
        fileMode: Labs.FileDialog.OpenFile
        folder: Labs.StandardPaths.writableLocation(Labs.StandardPaths.HomeLocation)
        nameFilters: ["Audio/vidéo (*.wav *.mp3 *.flac *.ogg *.opus *.m4a *.aac *.mp4 *.mkv *.webm *.mov *.avi)", "Tous les fichiers (*)"]
        acceptLabel: "Ouvrir"
        onAccepted: mediaApp.openLocalMedia(file.toString())
    }

    function openLocalMedia(urlString) {
        if (!urlString.startsWith("file:///")) {
            mediaError = "Seuls les fichiers locaux sont acceptés."
            return false
        }
        mediaPlayer.stop()
        mediaPlayer.source = ""
        mediaError = ""
        mediaApp.currentName = decodeURIComponent(urlString.substring(urlString.lastIndexOf("/") + 1))
        mediaPlayer.source = urlString
        return true
    }

    function formatTime(milliseconds) {
        if (!isFinite(milliseconds) || milliseconds <= 0)
            return "0:00"
        var totalSeconds = Math.floor(milliseconds / 1000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    function statusText() {
        if (mediaError.length > 0)
            return "Erreur de lecture"
        if (mediaPlayer.mediaStatus === MediaPlayer.LoadingMedia)
            return "Chargement…"
        if (mediaPlayer.mediaStatus === MediaPlayer.LoadedMedia || mediaPlayer.mediaStatus === MediaPlayer.BufferedMedia)
            return mediaPlayer.playbackState === MediaPlayer.PlayingState ? "En lecture" : "Prêt"
        if (mediaPlayer.mediaStatus === MediaPlayer.EndOfMedia)
            return "Terminé"
        if (mediaPlayer.mediaStatus === MediaPlayer.StalledMedia)
            return "Décodage en attente"
        return "En attente d’un fichier local"
    }
}
