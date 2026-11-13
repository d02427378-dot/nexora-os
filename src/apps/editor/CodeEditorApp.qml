import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.0 as Labs
import Nexora.Editor 1.0

Item {
    id: editorApp
    objectName: "nexoraCodeEditor"
    required property var shell
    property string initialText: ""
    property string pendingAction: ""
    property string pendingOpenUrl: ""
    property string pendingSaveUrl: ""
    property string notice: "Ouvrez un fichier local ou créez un document."
    property bool syncingBackendContent: false
    property alias backendForTests: backend

    CodeEditorBackend {
        id: backend
        objectName: "nexoraCodeEditorBackend"
    }

    Component.onCompleted: {
        if (initialText.length > 0) {
            backend.newDocument();
            backend.setContent(initialText);
            notice = "Brouillon IA chargé · choisissez explicitement où l’enregistrer.";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Button {
                text: "Ouvrir…"
                onClicked: openDialog.open()
                background: Rectangle {
                    radius: 8
                    color: editorApp.shell.palette.raised
                    border.color: editorApp.shell.palette.border
                }
                contentItem: Text {
                    text: "Ouvrir…"
                    color: editorApp.shell.palette.text
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                text: "Nouveau"
                onClicked: editorApp.requestNew()
                background: Rectangle {
                    radius: 8
                    color: editorApp.shell.palette.raised
                    border.color: editorApp.shell.palette.border
                }
                contentItem: Text {
                    text: "Nouveau"
                    color: editorApp.shell.palette.text
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                text: "Enregistrer"
                enabled: backend.dirty && backend.hasDocument
                onClicked: editorApp.saveCurrent()
                background: Rectangle {
                    radius: 8
                    color: editorApp.shell.palette.indigo
                }
                contentItem: Text {
                    text: "Enregistrer"
                    color: "#ffffff"
                    font.pixelSize: 9
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                text: "Enregistrer sous…"
                enabled: backend.dirty || !backend.hasDocument
                onClicked: editorApp.requestSaveAs()
                background: Rectangle {
                    radius: 8
                    color: editorApp.shell.palette.raised
                    border.color: editorApp.shell.palette.border
                }
                contentItem: Text {
                    text: "Enregistrer sous…"
                    color: editorApp.shell.palette.text
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: backend.dirty ? "● Modifié" : "UTF-8"
                color: backend.dirty ? "#ffd479" : editorApp.shell.palette.muted
                font.pixelSize: 9
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: editorApp.shell.palette.raised
            border.color: editorApp.shell.palette.border
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 7
                Text {
                    Layout.fillWidth: true
                    text: backend.hasDocument ? backend.filePath + (backend.dirty ? " •" : "") : "Nouveau document non enregistré"
                    color: editorApp.shell.palette.text
                    font.family: "monospace"
                    font.pixelSize: 9
                    elide: Text.ElideMiddle
                }
                Text {
                    text: "Ln " + editorApp.currentLine() + ", Col " + editorApp.currentColumn()
                    color: editorApp.shell.palette.muted
                    font.family: "monospace"
                    font.pixelSize: 9
                }
            }
        }

        TextArea {
            id: editorTextArea
            objectName: "editorTextArea"
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: ""
            placeholderText: "Écrivez ou collez votre code ici…"
            color: editorApp.shell.palette.text
            placeholderTextColor: editorApp.shell.palette.muted
            selectedTextColor: editorApp.shell.palette.text
            selectionColor: editorApp.shell.palette.indigo
            font.family: "monospace"
            font.pixelSize: 11
            wrapMode: TextEdit.NoWrap
            selectByMouse: true
            persistentSelection: true
            background: Rectangle {
                color: editorApp.shell.palette.background
                radius: 10
                border.color: editorTextArea.activeFocus ? editorApp.shell.palette.cyan : editorApp.shell.palette.border
            }
            onTextChanged: {
                if (!editorApp.syncingBackendContent && text !== backend.content)
                    backend.setContent(text);
            }
        }

        Text {
            Layout.fillWidth: true
            text: backend.dirty ? "Modifications non enregistrées — utilisez Enregistrer ou Enregistrer sous…" : backend.statusMessage.length > 0 ? backend.statusMessage : editorApp.notice
            color: backend.dirty ? "#ffd479" : backend.statusMessage.indexOf("impossible") >= 0 || backend.statusMessage.indexOf("refuse") >= 0 ? "#ff9f9f" : editorApp.shell.palette.muted
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }

    Connections {
        target: backend
        function onContentChanged() {
            if (editorTextArea.text === backend.content)
                return;
            editorApp.syncingBackendContent = true;
            editorTextArea.text = backend.content;
            editorApp.syncingBackendContent = false;
        }
    }

    Labs.FileDialog {
        id: openDialog
        title: "Ouvrir un fichier texte ou code"
        fileMode: Labs.FileDialog.OpenFile
        folder: Labs.StandardPaths.writableLocation(Labs.StandardPaths.DocumentsLocation)
        nameFilters: ["Fichiers texte et code (*.txt *.md *.qml *.js *.json *.html *.css *.cpp *.h *.py)", "Tous les fichiers (*)"]
        acceptLabel: "Ouvrir"
        onAccepted: editorApp.requestOpen(file.toString())
    }

    Labs.FileDialog {
        id: saveDialog
        title: "Enregistrer le document"
        fileMode: Labs.FileDialog.SaveFile
        folder: Labs.StandardPaths.writableLocation(Labs.StandardPaths.DocumentsLocation)
        nameFilters: ["Fichiers texte et code (*.txt *.md *.qml *.js *.json *.html *.css *.cpp *.h *.py)", "Tous les fichiers (*)"]
        defaultSuffix: "txt"
        acceptLabel: "Choisir"
        onAccepted: editorApp.requestSavePath(file.toString())
        onRejected: {
            editorApp.pendingAction = "";
            editorApp.pendingOpenUrl = "";
            editorApp.pendingSaveUrl = "";
        }
    }

    Dialog {
        id: unsavedDialog
        modal: true
        title: "Modifications non enregistrées"
        width: 520
        height: 210
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            implicitWidth: 330
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: "Le document a été modifié. Enregistrez-le avant de continuer, ou abandonnez explicitement les changements."
                color: editorApp.shell.palette.text
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                }
                Button {
                    text: "Annuler"
                    onClicked: {
                        editorApp.pendingAction = "";
                        editorApp.pendingOpenUrl = "";
                        unsavedDialog.close();
                    }
                }
                Button {
                    text: "Abandonner"
                    onClicked: editorApp.discardAndContinue()
                }
                Button {
                    text: "Enregistrer"
                    highlighted: true
                    onClicked: editorApp.saveAndContinue()
                }
            }
        }
    }

    Dialog {
        id: overwriteDialog
        modal: true
        title: "Confirmer le remplacement"
        width: 480
        height: 180
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            var saved = backend.saveAsFile(editorApp.pendingSaveUrl, true);
            editorApp.pendingSaveUrl = "";
            if (saved)
                editorApp.finishPendingAction();
        }
        onRejected: {
            editorApp.pendingAction = "";
            editorApp.pendingOpenUrl = "";
            editorApp.pendingSaveUrl = "";
        }
        contentItem: Text {
            width: 340
            text: "Ce fichier existe déjà. Son contenu sera remplacé atomiquement par le texte affiché dans l’éditeur. Continuer ?"
            color: editorApp.shell.palette.text
            wrapMode: Text.WordWrap
        }
    }

    function currentLine() {
        return editorTextArea.text.substring(0, editorTextArea.cursorPosition).split("\n").length;
    }

    function currentColumn() {
        var beforeCursor = editorTextArea.text.substring(0, editorTextArea.cursorPosition);
        return beforeCursor.length - beforeCursor.lastIndexOf("\n");
    }

    function requestOpen(url) {
        if (backend.dirty) {
            pendingAction = "open";
            pendingOpenUrl = url;
            unsavedDialog.open();
            return;
        }
        backend.openFile(url);
    }

    function requestNew() {
        if (backend.dirty) {
            pendingAction = "new";
            pendingOpenUrl = "";
            unsavedDialog.open();
            return;
        }
        backend.newDocument();
    }

    function requestSaveAs() {
        backend.setContent(editorTextArea.text);
        pendingAction = "";
        saveDialog.open();
    }

    function requestSavePath(url) {
        pendingSaveUrl = url;
        if (backend.pathExists(url)) {
            overwriteDialog.open();
            return;
        }
        if (backend.saveAsFile(url, false))
            finishPendingAction();
    }

    function saveCurrent() {
        backend.setContent(editorTextArea.text);
        if (backend.hasDocument)
            backend.saveCurrent();
        else
            saveDialog.open();
    }

    function saveAndContinue() {
        unsavedDialog.close();
        backend.setContent(editorTextArea.text);
        if (backend.hasDocument) {
            if (backend.saveCurrent())
                finishPendingAction();
        } else {
            saveDialog.open();
        }
    }

    function discardAndContinue() {
        unsavedDialog.close();
        finishPendingAction();
    }

    function finishPendingAction() {
        var action = pendingAction;
        var url = pendingOpenUrl;
        pendingAction = "";
        pendingOpenUrl = "";
        if (action === "new")
            backend.newDocument();
        else if (action === "open" && url.length > 0)
            backend.openFile(url);
    }
}
