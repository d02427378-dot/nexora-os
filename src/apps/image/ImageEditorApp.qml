import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.0 as Labs
import Nexora.Images 1.0

Item {
    id: imageApp
    objectName: "nexoraImageEditor"
    required property var shell
    property alias backendForTests: backend
    property string pendingAction: ""
    property string pendingOpenUrl: ""
    property string pendingSaveUrl: ""

    ImageEditorBackend {
        id: backend
        objectName: "nexoraImageEditorBackend"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Button {
                text: "Ouvrir une image…"
                onClicked: openDialog.open()
                background: Rectangle { radius: 8; color: imageApp.shell.palette.raised; border.color: imageApp.shell.palette.border }
                contentItem: Text { text: "Ouvrir une image…"; color: imageApp.shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button {
                text: "Enregistrer une copie…"
                enabled: backend.hasImage
                onClicked: saveDialog.open()
                background: Rectangle { radius: 8; color: imageApp.shell.palette.indigo }
                contentItem: Text { text: "Enregistrer une copie…"; color: "#ffffff"; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: backend.dirty ? "● Modifiée" : "Original préservé"
                color: backend.dirty ? "#ffd479" : imageApp.shell.palette.good
                font.pixelSize: 9
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Button { text: "↶ Annuler"; enabled: backend.canUndo; onClicked: backend.undo() }
            Button { text: "Réinitialiser"; enabled: backend.hasImage && backend.dirty; onClicked: backend.resetToOriginal() }
            Rectangle { width: 1; Layout.fillHeight: true; color: imageApp.shell.palette.border }
            Button { text: "⟲ Gauche"; enabled: backend.hasImage; onClicked: backend.rotateLeft() }
            Button { text: "⟳ Droite"; enabled: backend.hasImage; onClicked: backend.rotateRight() }
            Button { text: "↔ Miroir H"; enabled: backend.hasImage; onClicked: backend.flipHorizontal() }
            Button { text: "↕ Miroir V"; enabled: backend.hasImage; onClicked: backend.flipVertical() }
            Button { text: "N&B"; enabled: backend.hasImage; onClicked: backend.convertToGrayscale() }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label { text: "Luminosité"; color: imageApp.shell.palette.muted; font.pixelSize: 9 }
            Slider { id: brightnessSlider; Layout.preferredWidth: 105; from: -100; to: 100; value: 0; enabled: backend.hasImage }
            Button { text: "Appliquer"; enabled: backend.hasImage && brightnessSlider.value !== 0; onClicked: { backend.adjustBrightness(Math.round(brightnessSlider.value)); brightnessSlider.value = 0 } }
            Label { text: "Contraste"; color: imageApp.shell.palette.muted; font.pixelSize: 9 }
            Slider { id: contrastSlider; Layout.preferredWidth: 105; from: -100; to: 100; value: 0; enabled: backend.hasImage }
            Button { text: "Appliquer"; enabled: backend.hasImage && contrastSlider.value !== 0; onClicked: { backend.adjustContrast(Math.round(contrastSlider.value)); contrastSlider.value = 0 } }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Label { text: "Redimensionner max. (proportionnel)"; color: imageApp.shell.palette.muted; font.pixelSize: 9 }
            SpinBox { id: resizeWidth; from: 1; to: 8192; value: 1920; editable: true; enabled: backend.hasImage; Layout.preferredWidth: 95 }
            Label { text: "×"; color: imageApp.shell.palette.muted }
            SpinBox { id: resizeHeight; from: 1; to: 8192; value: 1080; editable: true; enabled: backend.hasImage; Layout.preferredWidth: 95 }
            Button { text: "Redimensionner"; enabled: backend.hasImage; onClicked: backend.resizeToFit(resizeWidth.value, resizeHeight.value) }
            Item { Layout.fillWidth: true }
            Text {
                text: backend.hasImage ? backend.imageWidth + " × " + backend.imageHeight + " px" : ""
                color: imageApp.shell.palette.muted
                font.family: "monospace"
                font.pixelSize: 9
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: imageApp.shell.palette.background
            border.color: imageApp.shell.palette.border
            clip: true

            Image {
                id: preview
                objectName: "imagePreview"
                anchors.fill: parent
                anchors.margins: 12
                source: backend.previewUrl
                cache: false
                asynchronous: false
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 2400
                sourceSize.height: 1600
                visible: backend.hasImage
            }

            Column {
                anchors.centerIn: parent
                spacing: 9
                visible: !backend.hasImage
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "NX"; color: imageApp.shell.palette.cyan; font.pixelSize: 42; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ouvrez une image locale pour commencer"; color: imageApp.shell.palette.text; font.pixelSize: 12 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "PNG · JPEG · WebP · BMP · TIFF"; color: imageApp.shell.palette.muted; font.pixelSize: 9 }
            }
        }

        Text {
            Layout.fillWidth: true
            text: backend.statusMessage.length > 0 ? backend.statusMessage : "Les modifications restent en mémoire. Enregistrer une copie n’écrase pas l’original sans confirmation."
            color: backend.statusMessage.indexOf("Impossible") >= 0 || backend.statusMessage.indexOf("refus") >= 0 ? "#ff9f9f" : imageApp.shell.palette.muted
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }

    Labs.FileDialog {
        id: openDialog
        title: "Ouvrir une image locale"
        fileMode: Labs.FileDialog.OpenFile
        folder: Labs.StandardPaths.writableLocation(Labs.StandardPaths.PicturesLocation)
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.tif *.tiff *.gif)", "Tous les fichiers (*)"]
        acceptLabel: "Ouvrir"
        onAccepted: imageApp.requestOpen(file.toString())
    }

    Labs.FileDialog {
        id: saveDialog
        title: "Enregistrer une copie de l’image"
        fileMode: Labs.FileDialog.SaveFile
        folder: Labs.StandardPaths.writableLocation(Labs.StandardPaths.PicturesLocation)
        nameFilters: ["PNG (*.png)", "JPEG (*.jpg *.jpeg)", "WebP (*.webp)", "BMP (*.bmp)", "TIFF (*.tif *.tiff)"]
        defaultSuffix: "png"
        acceptLabel: "Enregistrer la copie"
        onAccepted: imageApp.requestSavePath(file.toString())
        onRejected: {
            imageApp.pendingAction = ""
            imageApp.pendingOpenUrl = ""
            imageApp.pendingSaveUrl = ""
        }
    }

    Dialog {
        id: lossyExportDialog
        modal: true
        title: "Format avec perte"
        width: 470
        height: 180
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: imageApp.confirmSaveDestination()
        onRejected: {
            imageApp.pendingAction = ""
            imageApp.pendingOpenUrl = ""
            imageApp.pendingSaveUrl = ""
        }
        contentItem: Text {
            width: 330
            text: "JPEG et WebP seront encodés avec compression avec perte; JPEG peut aussi supprimer la transparence. Choisissez PNG ou TIFF pour une copie sans perte. Continuer ?"
            color: imageApp.shell.palette.text
            wrapMode: Text.WordWrap
        }
    }

    Dialog {
        id: unsavedDialog
        modal: true
        title: "Modifications en mémoire"
        width: 500
        height: 205
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            implicitWidth: 340
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: "L’image a été modifiée. Les changements ne sont pas enregistrés. Enregistrez une copie avant d’ouvrir une autre image, ou abandonnez-les."
                color: imageApp.shell.palette.text
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Annuler"; onClicked: { imageApp.pendingAction = ""; imageApp.pendingOpenUrl = ""; unsavedDialog.close() } }
                Button { text: "Abandonner"; onClicked: imageApp.discardAndOpen() }
                Button { text: "Enregistrer une copie…"; highlighted: true; onClicked: { unsavedDialog.close(); saveDialog.open() } }
            }
        }
    }

    Dialog {
        id: overwriteDialog
        modal: true
        title: "Confirmer le remplacement"
        width: 470
        height: 180
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            var saved = backend.saveCopyAs(imageApp.pendingSaveUrl, true)
            imageApp.pendingSaveUrl = ""
            if (saved)
                imageApp.finishPendingAction()
        }
        onRejected: {
            imageApp.pendingAction = ""
            imageApp.pendingOpenUrl = ""
            imageApp.pendingSaveUrl = ""
        }
        contentItem: Text {
            width: 330
            text: "Cette destination existe déjà. Confirmez-vous son remplacement par une copie de l’image transformée ? L’image source reste inchangée si vous choisissez un autre fichier."
            color: imageApp.shell.palette.text
            wrapMode: Text.WordWrap
        }
    }

    function requestOpen(url) {
        if (backend.dirty) {
            pendingAction = "open"
            pendingOpenUrl = url
            unsavedDialog.open()
            return
        }
        backend.openImage(url)
    }

    function requestSavePath(url) {
        pendingSaveUrl = url
        var lowerUrl = url.toLowerCase()
        var cleanUrl = lowerUrl.split("?")[0].split("#")[0]
        if (cleanUrl.endsWith(".jpg") || cleanUrl.endsWith(".jpeg") || cleanUrl.endsWith(".webp")) {
            lossyExportDialog.open()
            return
        }
        confirmSaveDestination()
    }

    function confirmSaveDestination() {
        var url = pendingSaveUrl
        if (backend.pathExists(url)) {
            overwriteDialog.open()
            return
        }
        if (backend.saveCopyAs(url, false))
            finishPendingAction()
    }

    function discardAndOpen() {
        unsavedDialog.close()
        finishPendingAction()
    }

    function finishPendingAction() {
        var action = pendingAction
        var url = pendingOpenUrl
        pendingAction = ""
        pendingOpenUrl = ""
        if (action === "open" && url.length > 0)
            backend.openImage(url)
    }
}
