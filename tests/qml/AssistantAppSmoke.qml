import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1320
    height: 880
    visible: true
    title: "Nexora Assistant smoke test"
    property int stage: 0
    property var shellObject: null
    property var assistantApp: null
    property string freeformPrompt: "Ouvre les mini-jeux"
    property string generatedDraft: "import QtQuick 2.15\nItem {\n    Text { text: \"Brouillon local\" }\n}\n"

    QtObject {
        id: testPreferences
        property var values: ({
                "themeName": "Obsidian",
                "gamerModeEnabled": false,
                "reducedMotionEnabled": false
            })
        function value(key, defaultValue) {
            return values[key] === undefined ? defaultValue : values[key];
        }
        function setValue(key, value) {
            values[key] = value;
        }
        function sync() {
        }
    }

    QtObject {
        id: fakeBackend
        property bool busy: false
        property string answer: "Réponse simulée pour les tests."
        property string codeDraft: ""
        property string actionType: "none"
        property string actionValue: ""
        property string error: ""
        property string lastPrompt: ""
        signal requestCompleted(bool success)
        function ask(prompt, endpoint, model, apiKey) {
            lastPrompt = prompt;
            answer = "Voici un brouillon, non exécuté.";
            codeDraft = root.generatedDraft;
            actionType = "open_app";
            actionValue = "games";
            error = "";
            requestCompleted(true);
            return true;
        }
        function cancel() {
        }
        function clear() {
            answer = "";
            codeDraft = "";
            actionType = "none";
            actionValue = "";
            error = "";
        }
    }

    function findNamed(node, targetName) {
        if (!node)
            return null;
        if (node.objectName === targetName)
            return node;
        if (node.item) {
            var loaded = findNamed(node.item, targetName);
            if (loaded)
                return loaded;
        }
        if (node.contentItem) {
            var content = findNamed(node.contentItem, targetName);
            if (content)
                return content;
        }
        if (node.children) {
            for (var i = 0; i < node.children.length; ++i) {
                var found = findNamed(node.children[i], targetName);
                if (found)
                    return found;
            }
        }
        return null;
    }

    function fail(message, code) {
        console.error(message);
        Qt.exit(code);
    }

    Component.onCompleted: {
        var component = Qt.createComponent(Qt.resolvedUrl("../../src/desktop/NexoraShell.qml"));
        if (component.status !== Component.Ready) {
            fail("NexoraShell load failed: " + component.errorString(), 2);
            return;
        }
        shellObject = component.createObject(null, {
                "useMemoryPreferences": true,
                "testPreferences": testPreferences
            });
        if (!shellObject) {
            fail("NexoraShell instance failed", 3);
            return;
        }
        shellObject.commandOpen = true;
        var commandField = findNamed(shellObject.contentItem, "commandSearchField");
        if (!commandField) {
            fail("Universal command field was not found", 4);
            return;
        }
        commandField.text = freeformPrompt;
        commandField.accepted();
    }

    Timer {
        interval: 60
        repeat: true
        running: true
        onTriggered: {
            if (!root.shellObject)
                return;
            if (root.stage === 0) {
                var app = root.findNamed(root.shellObject.contentItem, "nexoraAssistantApp");
                if (!app)
                    return;
                if (app.promptField.text !== root.freeformPrompt) {
                    root.fail("Universal command bar did not prefill the assistant prompt", 5);
                    return;
                }
                if (!app.backendInstance || app.backendInstance.busy) {
                    root.fail("Assistant backend was not initialized without a network request", 6);
                    return;
                }
                var firstWindow = root.shellObject.openWindows[root.shellObject.openWindows.length - 1];
                root.shellObject.closeWindow(firstWindow.uid);
                root.shellObject.launchApp("assistant", {
                        "initialPrompt": "Crée une application de notes en QML",
                        "backendOverride": fakeBackend
                    });
                root.stage = 1;
            } else if (root.stage === 1) {
                var secondApp = root.findNamed(root.shellObject.contentItem, "nexoraAssistantApp");
                if (!secondApp || secondApp.backendInstance !== fakeBackend)
                    return;
                secondApp.sendPrompt();
                if (fakeBackend.lastPrompt !== "Crée une application de notes en QML" || fakeBackend.codeDraft !== root.generatedDraft || fakeBackend.actionType !== "open_app") {
                    root.fail("Assistant did not process the local test response", 7);
                    return;
                }
                if (!secondApp.actionConfirmationDialog) {
                    root.fail("Assistant action confirmation dialog is unavailable", 8);
                    return;
                }
                secondApp.actionConfirmationDialog.open();
                secondApp.actionConfirmationDialog.accept();
                var openedGames = false;
                for (var i = 0; i < root.shellObject.openWindows.length; ++i) {
                    if (root.shellObject.openWindows[i].appId === "games")
                        openedGames = true;
                }
                if (!openedGames || !secondApp.actionConsumed) {
                    root.fail("Assistant action did not require and pass through explicit confirmation", 9);
                    return;
                }
                var currentAssistant = root.findNamed(root.shellObject.contentItem, "nexoraAssistantApp");
                if (!currentAssistant) {
                    root.fail("Assistant window disappeared after the confirmed action", 10);
                    return;
                }
                currentAssistant.copyCodeToEditor();
                root.stage = 2;
            } else if (root.stage === 2) {
                var editor = root.findNamed(root.shellObject.contentItem, "nexoraCodeEditor");
                if (!editor)
                    return;
                if (editor.backendForTests.content !== root.generatedDraft || !editor.backendForTests.dirty || editor.backendForTests.hasDocument) {
                    root.fail("AI draft was not transferred as an unsaved editor buffer", 10);
                    return;
                }
                console.log("Assistant Nexora validé: requête libre préremplie sans envoi automatique, action allowlistée confirmée, code remis à l’Éditeur non enregistré; aucun fournisseur externe contacté.");
                Qt.exit(0);
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail("Assistant smoke test timed out at stage " + root.stage, 11)
    }
}
