import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: assistantApp
    objectName: "nexoraAssistantApp"
    required property var shell
    property string initialPrompt: ""
    property var backendOverride: null
    property var backendInstance: null
    property string localError: ""
    property bool actionConsumed: false
    property string endpointText: "https://api.openai.com/v1/chat/completions"
    property string modelText: ""
    property alias promptField: userPrompt
    property alias apiKeyField: apiKeyInput
    property alias actionConfirmationDialog: confirmationDialog

    function ensureBackend() {
        if (backendOverride !== null) {
            backendInstance = backendOverride;
            return;
        }
        try {
            backendInstance = Qt.createQmlObject("import Nexora.Assistant 1.0; AssistantBackend {}", assistantApp, "NexoraAssistantBackend");
        } catch (error) {
            localError = "Le backend de l’assistant n’est pas disponible dans ce lanceur.";
        }
    }

    function sendPrompt() {
        if (!backendInstance) {
            localError = "Le backend de l’assistant n’est pas disponible.";
            return;
        }
        if (backendInstance.busy)
            return;
        localError = "";
        actionConsumed = false;
        if (backendInstance.ask(userPrompt.text, endpointInput.text, modelInput.text, apiKeyInput.text)) {
            userPrompt.text = "";
        } else if (backendInstance.error.length > 0) {
            localError = backendInstance.error;
        }
    }

    function proposedActionDescription() {
        if (!backendInstance)
            return "";
        var value = backendInstance.actionValue;
        if (backendInstance.actionType === "open_app") {
            var labels = {
                "browser": "Navigateur",
                "files": "Fichiers",
                "editor": "Éditeur",
                "image": "Images",
                "terminal": "Terminal",
                "media": "Média",
                "music": "Musique",
                "settings": "Paramètres",
                "monitor": "Moniteur",
                "store": "Boutique",
                "games": "Mini-jeux"
            };
            return "Ouvrir l’application « " + (labels[value] || value) + " »";
        }
        if (backendInstance.actionType === "switch_workspace")
            return "Basculer vers l’espace visuel " + value;
        if (backendInstance.actionType === "set_theme")
            return "Appliquer le thème « " + value + " »";
        if (backendInstance.actionType === "set_gamer_mode")
            return (value === "true" ? "Activer" : "Désactiver") + " le Mode Gamer du shell";
        return "";
    }

    function applyProposedAction() {
        if (!backendInstance || actionConsumed)
            return;
        var type = backendInstance.actionType;
        var value = backendInstance.actionValue;
        var apps = ["browser", "files", "editor", "image", "terminal", "media", "music", "settings", "monitor", "store", "games"];
        if (type === "open_app" && apps.indexOf(value) !== -1) {
            shell.launchApp(value);
        } else if (type === "switch_workspace" && ["1", "2", "3", "4"].indexOf(value) !== -1) {
            shell.currentWorkspace = parseInt(value) - 1;
        } else if (type === "set_theme" && shell.themeNames.indexOf(value) !== -1) {
            shell.setTheme(value);
        } else if (type === "set_gamer_mode" && (value === "true" || value === "false")) {
            shell.gamerMode = value === "true";
        } else {
            localError = "Action non reconnue; aucune opération n’a été effectuée.";
            return;
        }
        actionConsumed = true;
        confirmationDialog.close();
    }

    function copyCodeToEditor() {
        if (!backendInstance || backendInstance.codeDraft.length === 0)
            return;
        shell.launchApp("editor", {
                "initialText": backendInstance.codeDraft
            });
    }

    Component.onCompleted: {
        ensureBackend();
        userPrompt.text = initialPrompt;
    }

    Connections {
        target: assistantApp.backendInstance
        ignoreUnknownSignals: true
        function onRequestCompleted(success) {
            if (success) {
                assistantApp.localError = assistantApp.backendInstance.error;
                assistantApp.actionConsumed = false;
            }
        }
        function onErrorChanged() {
            if (assistantApp.backendInstance && assistantApp.backendInstance.error.length > 0)
                assistantApp.localError = assistantApp.backendInstance.error;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: assistantApp.shell.palette.hover
                border.color: assistantApp.shell.palette.cyan
                Text {
                    anchors.centerIn: parent
                    text: "NX"
                    color: assistantApp.shell.palette.cyan
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Assistant Nexora"
                    color: assistantApp.shell.palette.text
                    font.pixelSize: 17
                    font.bold: true
                }
                Text {
                    text: "Brouillons de code et actions contrôlées du shell"
                    color: assistantApp.shell.palette.muted
                    font.pixelSize: 10
                }
            }
            Text {
                text: backendInstance && backendInstance.busy ? "EN COURS" : "SESSION PRIVÉE"
                color: backendInstance && backendInstance.busy ? assistantApp.shell.palette.cyan : assistantApp.shell.palette.muted
                font.pixelSize: 9
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 132
            radius: 13
            color: assistantApp.shell.palette.surface
            border.color: assistantApp.shell.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextField {
                        id: endpointInput
                        Layout.fillWidth: true
                        text: assistantApp.endpointText
                        onTextChanged: assistantApp.endpointText = text
                        placeholderText: "URL HTTPS du fournisseur compatible Chat Completions"
                        selectByMouse: true
                        color: assistantApp.shell.palette.text
                        font.pixelSize: 10
                        background: Rectangle {
                            radius: 8
                            color: assistantApp.shell.palette.background
                            border.color: endpointInput.activeFocus ? assistantApp.shell.palette.cyan : assistantApp.shell.palette.border
                        }
                    }
                    TextField {
                        id: modelInput
                        Layout.preferredWidth: 190
                        text: assistantApp.modelText
                        onTextChanged: assistantApp.modelText = text
                        placeholderText: "Identifiant du modèle"
                        selectByMouse: true
                        color: assistantApp.shell.palette.text
                        font.pixelSize: 10
                        background: Rectangle {
                            radius: 8
                            color: assistantApp.shell.palette.background
                            border.color: modelInput.activeFocus ? assistantApp.shell.palette.cyan : assistantApp.shell.palette.border
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextField {
                        id: apiKeyInput
                        objectName: "assistantApiKeyField"
                        Layout.fillWidth: true
                        placeholderText: "Clé API (mémoire de cette session seulement)"
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        selectByMouse: true
                        color: assistantApp.shell.palette.text
                        font.pixelSize: 10
                        background: Rectangle {
                            radius: 8
                            color: assistantApp.shell.palette.background
                            border.color: apiKeyInput.activeFocus ? assistantApp.shell.palette.cyan : assistantApp.shell.palette.border
                        }
                    }
                    Button {
                        text: "Vider la clé"
                        onClicked: apiKeyInput.clear()
                        background: Rectangle {
                            radius: 8
                            color: assistantApp.shell.palette.raised
                            border.color: assistantApp.shell.palette.border
                        }
                        contentItem: Text {
                            text: parent.text
                            color: assistantApp.shell.palette.text
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Le texte saisi est envoyé uniquement après votre clic sur Envoyer. HTTPS obligatoire à distance; HTTP est limité à localhost. Clé et historique non enregistrés."
                    color: assistantApp.shell.palette.muted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            radius: 13
            color: assistantApp.shell.palette.surface
            border.color: assistantApp.shell.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                Text {
                    text: "VOTRE DEMANDE"
                    color: assistantApp.shell.palette.muted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.1
                }
                TextArea {
                    id: userPrompt
                    objectName: "assistantPromptField"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Ex. : crée un exemple d’application de notes en QML, ou ouvre les mini-jeux."
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    color: assistantApp.shell.palette.text
                    placeholderTextColor: assistantApp.shell.palette.muted
                    font.pixelSize: 11
                    background: Rectangle {
                        radius: 8
                        color: assistantApp.shell.palette.background
                        border.color: userPrompt.activeFocus ? assistantApp.shell.palette.cyan : assistantApp.shell.palette.border
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: assistantApp.localError.length > 0 ? assistantApp.localError : (backendInstance ? backendInstance.error : "")
                        color: "#ff9f9f"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                    Button {
                        objectName: "assistantSendButton"
                        text: backendInstance && backendInstance.busy ? "Annuler" : "Envoyer"
                        enabled: backendInstance !== null && (backendInstance.busy || userPrompt.text.trim().length > 0)
                        onClicked: {
                            if (backendInstance.busy)
                                backendInstance.cancel();
                            else
                                assistantApp.sendPrompt();
                        }
                        background: Rectangle {
                            radius: 8
                            color: assistantApp.shell.palette.indigo
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true
                    visible: backendInstance !== null && backendInstance.answer.length > 0
                    implicitHeight: answerColumn.implicitHeight + 20
                    radius: 12
                    color: assistantApp.shell.palette.surface
                    border.color: assistantApp.shell.palette.border
                    ColumnLayout {
                        id: answerColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6
                        Text {
                            text: "RÉPONSE"
                            color: assistantApp.shell.palette.cyan
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.1
                        }
                        Text {
                            Layout.fillWidth: true
                            text: backendInstance ? backendInstance.answer : ""
                            color: assistantApp.shell.palette.text
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    visible: backendInstance !== null && backendInstance.codeDraft.length > 0
                    implicitHeight: codeColumn.implicitHeight + 20
                    radius: 12
                    color: assistantApp.shell.palette.surface
                    border.color: assistantApp.shell.palette.border
                    ColumnLayout {
                        id: codeColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "BROUILLON DE CODE · NON EXÉCUTÉ"
                                color: assistantApp.shell.palette.cyan
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                            }
                            Button {
                                objectName: "assistantCopyToEditorButton"
                                text: "Ouvrir dans l’Éditeur"
                                onClicked: assistantApp.copyCodeToEditor()
                                background: Rectangle {
                                    radius: 8
                                    color: assistantApp.shell.palette.indigo
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "#ffffff"
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                        TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(280, Math.max(110, contentHeight + 14))
                            text: backendInstance ? backendInstance.codeDraft : ""
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.NoWrap
                            color: assistantApp.shell.palette.text
                            font.family: "monospace"
                            font.pixelSize: 10
                            background: Rectangle {
                                radius: 8
                                color: assistantApp.shell.palette.background
                                border.color: assistantApp.shell.palette.border
                            }
                        }
                        Text {
                            text: "Le brouillon est transféré dans un nouveau document non enregistré. Rien n’est exécuté ni sauvegardé automatiquement."
                            color: assistantApp.shell.palette.muted
                            font.pixelSize: 9
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                Rectangle {
                    id: proposedActionCard
                    objectName: "assistantProposedActionCard"
                    Layout.fillWidth: true
                    visible: backendInstance !== null && backendInstance.actionType !== "none" && !assistantApp.actionConsumed
                    implicitHeight: actionColumn.implicitHeight + 20
                    radius: 12
                    color: assistantApp.shell.palette.raised
                    border.color: assistantApp.shell.palette.cyan
                    ColumnLayout {
                        id: actionColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 7
                        Text {
                            text: "ACTION PROPOSÉE · CONFIRMATION REQUISE"
                            color: assistantApp.shell.palette.cyan
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                        Text {
                            Layout.fillWidth: true
                            text: assistantApp.proposedActionDescription()
                            color: assistantApp.shell.palette.text
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                        Button {
                            objectName: "assistantConfirmActionButton"
                            text: "Examiner et confirmer…"
                            onClicked: confirmationDialog.open()
                            background: Rectangle {
                                radius: 8
                                color: assistantApp.shell.palette.indigo
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "#ffffff"
                                font.pixelSize: 9
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmationDialog
        objectName: "assistantActionConfirmation"
        modal: true
        title: "Confirmer une action Nexora"
        width: Math.min(480, assistantApp.width - 40)
        standardButtons: Dialog.Cancel | Dialog.Accept
        contentItem: Text {
            width: 390
            text: "L’assistant propose :\n\n" + assistantApp.proposedActionDescription() + "\n\nCette action est limitée au shell Nexora. Aucun terminal ni fichier ne sera modifié. Voulez-vous l’exécuter ?"
            color: assistantApp.shell.palette.text
            wrapMode: Text.WordWrap
        }
        onAccepted: assistantApp.applyProposedAction()
    }
}
