import QtQuick 2.15
import QtTest 1.3

TestCase {
    name: "NexoraDesktopShell"
    when: windowShown

    property var shellObject: null
    property var sharedTestPreferences: ({
            "values": ({
                    "themeName": "Obsidian",
                    "gamerModeEnabled": false,
                    "reducedMotionEnabled": false
                }),
            "value": function (key, defaultValue) {
                return this.values[key] === undefined ? defaultValue : this.values[key];
            },
            "setValue": function (key, value) {
                this.values[key] = value;
            },
            "sync": function () {}
        })

    function initTestCase() {
        var componentUrl = Qt.resolvedUrl("../../src/desktop/NexoraShell.qml");
        var component = Qt.createComponent(componentUrl);
        compare(component.status, Component.Ready, component.errorString());
        sharedTestPreferences.values = ({
                "themeName": "Obsidian",
                "gamerModeEnabled": false,
                "reducedMotionEnabled": false
            });
        shellObject = component.createObject(null, {
                "useMemoryPreferences": true,
                "testPreferences": sharedTestPreferences
            });
        verify(shellObject !== null, "Le shell doit être instanciable");
        wait(100);
    }

    function cleanupTestCase() {
        if (shellObject !== null) {
            shellObject.close();
            shellObject.destroy();
            shellObject = null;
        }
    }

    function findLoadedItem(node, targetName) {
        if (!node)
            return null;
        if (node.objectName === targetName)
            return node;
        if (node.item) {
            var loaded = findLoadedItem(node.item, targetName);
            if (loaded)
                return loaded;
        }
        if (node.contentItem) {
            var content = findLoadedItem(node.contentItem, targetName);
            if (content)
                return content;
        }
        if (node.children) {
            for (var i = 0; i < node.children.length; ++i) {
                var found = findLoadedItem(node.children[i], targetName);
                if (found)
                    return found;
            }
        }
        return null;
    }

    function test_theme_switching() {
        shellObject.setTheme("Obsidian");
        compare(shellObject.currentTheme, "Obsidian");
        shellObject.nextTheme();
        compare(shellObject.currentTheme, "Aurora");
        compare(shellObject.palette.cyan, "#82f3ed");
        shellObject.setTheme("Nebula");
        compare(shellObject.currentTheme, "Nebula");
    }

    function test_settings_app_updates_preferences() {
        shellObject.resetPreferences();
        shellObject.launchApp("settings");
        var windowId = shellObject.openWindows[shellObject.openWindows.length - 1].uid;
        tryVerify(function () {
                return findLoadedItem(shellObject.contentItem, "nexoraSettingsApp") !== null;
            }, 3000);
        var settingsApp = findLoadedItem(shellObject.contentItem, "nexoraSettingsApp");
        verify(settingsApp !== null);
        compare(settingsApp.shell.currentTheme, "Obsidian");
        var tabs = findChild(settingsApp, "settingsPageTabs");
        verify(tabs !== null);
        tabs.currentIndex = 2;
        compare(settingsApp.selectedPage, 2);
        shellObject.setTheme("Nebula");
        shellObject.gamerMode = true;
        shellObject.reduceMotion = true;
        compare(shellObject.preferencesStore.value("themeName", ""), "Nebula");
        compare(shellObject.preferencesStore.value("gamerModeEnabled", false), true);
        compare(shellObject.preferencesStore.value("reducedMotionEnabled", false), true);
        shellObject.preferencesStore.sync();
        shellObject.resetPreferences();
        shellObject.closeWindow(windowId);
    }

    function test_workspace_navigation() {
        compare(shellObject.currentWorkspace, 0);
        shellObject.executeCommand("workspace:2");
        compare(shellObject.currentWorkspace, 2);
        compare(shellObject.workspaceNames[shellObject.currentWorkspace], "Play");
    }

    function test_app_window_lifecycle() {
        shellObject.openWindows = [];
        compare(shellObject.openWindows.length, 0);
        shellObject.launchApp("media");
        compare(shellObject.openWindows.length, 1);
        compare(shellObject.workspaceWindowCount(0), 1);
        var windowId = shellObject.openWindows[0].uid;
        compare(shellObject.openWindows[0].appId, "media");
        shellObject.closeWindow(windowId);
        compare(shellObject.openWindows.length, 0);
        compare(shellObject.workspaceWindowCount(0), 0);
    }

    function test_file_manager_launches_from_shell() {
        shellObject.launchApp("files");
        var windowId = shellObject.openWindows[shellObject.openWindows.length - 1].uid;
        tryVerify(function () {
                return findLoadedItem(shellObject.contentItem, "nexoraFileManager") !== null;
            }, 3000);
        var fileApp = findLoadedItem(shellObject.contentItem, "nexoraFileManager");
        tryVerify(function () {
                return fileApp.entryCount > 0;
            }, 3000, "L’explorateur doit lire le dossier personnel réel");
        shellObject.closeWindow(windowId);
    }

    function test_universal_command_search() {
        var results = shellObject.searchCommands("terminal");
        verify(results.length > 0);
        verify(results[0].title.indexOf("Terminal") !== -1);
        var themeResults = shellObject.searchCommands("theme");
        compare(themeResults.length, 1);
    }

    function test_launcher_catalog() {
        compare(shellObject.launcherApps.length, 12);
        var settingsResults = shellObject.searchCommands("paramètres");
        compare(settingsResults.length, 1);
        compare(settingsResults[0].detail, "Thème, animations, Mode Gamer · mémorisés");
        var monitorResults = shellObject.searchCommands("moniteur");
        compare(monitorResults.length, 1);
        compare(monitorResults[0].detail, "CPU, mémoire et processus /proc · lecture seule");
        var gamesResults = shellObject.searchCommands("mini-jeux");
        compare(gamesResults.length, 1);
        compare(gamesResults[0].detail, "Morpion, Snake, Memory, 2048 · hors ligne");
        var storeResults = shellObject.searchCommands("boutique");
        compare(storeResults.length, 1);
        compare(storeResults[0].detail, "Catalogue APT local · simulation puis confirmation");
        var musicResults = shellObject.searchCommands("musique");
        compare(musicResults.length, 1);
        compare(musicResults[0].detail, "Bibliothèque audio locale · playlist de dossier");
        var editorResults = shellObject.searchCommands("éditeur");
        verify(editorResults.some(function (item) {
                    return item.detail === "Code UTF-8 · sauvegarde explicite";
                }));
        var imageResults = shellObject.searchCommands("images");
        verify(imageResults.some(function (item) {
                    return item.detail === "Transformations locales · export en copie";
                }));
        var assistantResults = shellObject.searchCommands("assistant");
        compare(assistantResults.length, 1);
        compare(assistantResults[0].id, "open:assistant");
    }

    function test_freeform_command_suggests_assistant_without_sending() {
        var prompt = "Crée un exemple de carnet de notes en QML";
        var results = shellObject.searchCommands(prompt);
        compare(results.length, 1);
        compare(results[0].id, "assistant:ask");
        compare(results[0].kind, "assistant");
        compare(results[0].prompt, prompt);
        verify(results[0].detail.indexOf("envoi reste manuel") !== -1);
    }

    function test_music_app_scans_only_local_folder() {
        shellObject.launchApp("music");
        var windowId = shellObject.openWindows[shellObject.openWindows.length - 1].uid;
        tryVerify(function () {
                return findLoadedItem(shellObject.contentItem, "nexoraMusicApp") !== null;
            }, 3000);
        var musicApp = findLoadedItem(shellObject.contentItem, "nexoraMusicApp");
        verify(musicApp.openFolder(Qt.resolvedUrl("../fixtures/media/").toString()));
        tryVerify(function () {
                return musicApp.trackCount > 0;
            }, 3000, "Musique doit lister la fixture audio locale");
        compare(musicApp.trackCount, 1);
        verify(!musicApp.openFolder("https://example.invalid/music"), "Les dossiers réseau doivent être refusés");
        shellObject.closeWindow(windowId);
    }

    function test_mini_games_launch_from_shell() {
        shellObject.launchApp("games");
        var windowId = shellObject.openWindows[shellObject.openWindows.length - 1].uid;
        tryVerify(function () {
                return findLoadedItem(shellObject.contentItem, "nexoraGamesApp") !== null;
            }, 3000);
        var gamesApp = findLoadedItem(shellObject.contentItem, "nexoraGamesApp");
        compare(gamesApp.gameCatalog.length, 4);
        var ticTacToe = findLoadedItem(gamesApp, "nexoraTicTacToeGame");
        verify(ticTacToe !== null);
        ticTacToe.resetGame();
        verify(ticTacToe.playCell(0));
        verify(ticTacToe.playCell(3));
        verify(ticTacToe.playCell(1));
        verify(ticTacToe.playCell(4));
        verify(ticTacToe.playCell(2));
        compare(ticTacToe.winner, "X");
        shellObject.closeWindow(windowId);
    }

    function test_command_palette_action_on_accept() {
        shellObject.setTheme("Obsidian");
        shellObject.commandOpen = true;
        wait(50);
        var field = findChild(shellObject, "commandSearchField");
        verify(field !== null, "Le champ de commande doit exister");
        field.text = "theme";
        wait(50);
        field.accepted();
        compare(shellObject.currentTheme, "Aurora");
        verify(!shellObject.commandOpen);
    }

    function test_gamer_mode_and_safe_terminal() {
        shellObject.gamerMode = true;
        verify(shellObject.gamerMode);
        var terminal = shellObject.searchCommands("terminal");
        compare(terminal.length, 1);
        compare(terminal[0].detail, "Bash local · permissions de l’utilisateur");
    }
}
