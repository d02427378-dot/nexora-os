import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Qt.labs.settings 1.0 as LabSettings

ApplicationWindow {
    id: root
    objectName: "nexoraShell"
    visible: true
    width: 1440
    height: 900
    minimumWidth: 980
    minimumHeight: 640
    title: "Nexora OS — aperçu du bureau"
    color: palette.background
    visibility: Window.Maximized

    property string preferencesFileName: ""
    property bool useMemoryPreferences: false
    property var testPreferences: null
    property var memoryPreferences: ({
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
    property var persistentPreferences: null
    property var preferencesStore: useMemoryPreferences ? (testPreferences || memoryPreferences) : (persistentPreferences || memoryPreferences)

    property var themes: ({
            "Obsidian": {
                "background": "#090c16",
                "surface": "#101629",
                "raised": "#171f35",
                "hover": "#202b46",
                "border": "#293550",
                "text": "#edf0ff",
                "muted": "#93a0bf",
                "violet": "#a56bff",
                "indigo": "#7771ff",
                "cyan": "#41e7ff",
                "focus": "#70eaff",
                "good": "#6ce6b3"
            },
            "Aurora": {
                "background": "#071518",
                "surface": "#0d2227",
                "raised": "#14323a",
                "hover": "#1b4148",
                "border": "#28505a",
                "text": "#e6fbf7",
                "muted": "#8fb8b8",
                "violet": "#61e6c1",
                "indigo": "#5aa9d8",
                "cyan": "#82f3ed",
                "focus": "#82f3ed",
                "good": "#76edbb"
            },
            "Nebula": {
                "background": "#130b1b",
                "surface": "#20142c",
                "raised": "#2c1d3c",
                "hover": "#3b2851",
                "border": "#503563",
                "text": "#f4eaff",
                "muted": "#b7a2c9",
                "violet": "#ff74c8",
                "indigo": "#a56bff",
                "cyan": "#77dfff",
                "focus": "#9cecff",
                "good": "#78e8b4"
            }
        })
    property var themeNames: ["Obsidian", "Aurora", "Nebula"]
    property var palette: themes[currentTheme] || themes["Obsidian"]
    property string currentTheme: themes[preferencesStore.value("themeName", "Obsidian")] !== undefined ? preferencesStore.value("themeName", "Obsidian") : "Obsidian"
    property bool gamerMode: Boolean(preferencesStore.value("gamerModeEnabled", false))
    property bool reduceMotion: Boolean(preferencesStore.value("reducedMotionEnabled", false))
    property bool launcherOpen: false
    property bool commandOpen: false
    property bool quickPanelOpen: false
    property int currentWorkspace: 0
    property var workspaceNames: ["Focus", "Studio", "Play", "Lab"]
    property int nextWindowId: 1
    property int zCounter: 20
    property var openWindows: []
    property var pinnedApps: [{
            "id": "browser",
            "label": "Navigateur",
            "glyph": "WEB",
            "color": "#70c9ff"
        }, {
            "id": "files",
            "label": "Fichiers",
            "glyph": "DOC",
            "color": "#ffd479"
        }, {
            "id": "editor",
            "label": "Éditeur",
            "glyph": "</>",
            "color": "#b59aff"
        }, {
            "id": "terminal",
            "label": "Terminal",
            "glyph": ">_",
            "color": "#6ce6b3"
        }, {
            "id": "media",
            "label": "Média",
            "glyph": "PLAY",
            "color": "#ff87b5"
        }, {
            "id": "music",
            "label": "Musique",
            "glyph": "♫",
            "color": "#69d9e8"
        }, {
            "id": "settings",
            "label": "Paramètres",
            "glyph": "SET",
            "color": "#a9b8d7"
        }]
    property var launcherApps: pinnedApps.concat([{
                "id": "image",
                "label": "Images",
                "glyph": "IMG",
                "color": "#69d9e8"
            }, {
                "id": "monitor",
                "label": "Moniteur",
                "glyph": "SYS",
                "color": "#78d7bd"
            }, {
                "id": "store",
                "label": "Boutique",
                "glyph": "APP",
                "color": "#f5a7d3"
            }, {
                "id": "games",
                "label": "Mini-jeux",
                "glyph": "GAME",
                "color": "#41e7ff"
            }, {
                "id": "assistant",
                "label": "Assistant IA",
                "glyph": "AI",
                "color": "#a56bff"
            }])
    property var commandCatalog: [{
            "id": "open:browser",
            "title": "Ouvrir le Navigateur",
            "detail": "WebEngine · HTTP et HTTPS",
            "kind": "application"
        }, {
            "id": "open:files",
            "title": "Ouvrir Fichiers",
            "detail": "Parcourir les dossiers locaux",
            "kind": "application"
        }, {
            "id": "open:editor",
            "title": "Ouvrir l’Éditeur",
            "detail": "Code UTF-8 · sauvegarde explicite",
            "kind": "application"
        }, {
            "id": "open:image",
            "title": "Ouvrir Images",
            "detail": "Transformations locales · export en copie",
            "kind": "application"
        }, {
            "id": "open:terminal",
            "title": "Ouvrir le Terminal",
            "detail": "Bash local · permissions de l’utilisateur",
            "kind": "application"
        }, {
            "id": "open:media",
            "title": "Ouvrir Média",
            "detail": "Qt Multimedia · fichiers audio/vidéo locaux",
            "kind": "application"
        }, {
            "id": "open:music",
            "title": "Ouvrir Musique",
            "detail": "Bibliothèque audio locale · playlist de dossier",
            "kind": "application"
        }, {
            "id": "open:settings",
            "title": "Ouvrir Paramètres",
            "detail": "Thème, animations, Mode Gamer · mémorisés",
            "kind": "application"
        }, {
            "id": "open:monitor",
            "title": "Ouvrir le Moniteur système",
            "detail": "CPU, mémoire et processus /proc · lecture seule",
            "kind": "application"
        }, {
            "id": "open:games",
            "title": "Ouvrir les Mini-jeux",
            "detail": "Morpion, Snake, Memory, 2048 · hors ligne",
            "kind": "application"
        }, {
            "id": "open:store",
            "title": "Ouvrir la Boutique",
            "detail": "Catalogue APT local · simulation puis confirmation",
            "kind": "application"
        }, {
            "id": "open:assistant",
            "title": "Ouvrir Assistant Nexora",
            "detail": "Brouillons de code · actions limitées avec confirmation",
            "kind": "application"
        }, {
            "id": "action:next-theme",
            "title": "Changer de thème",
            "detail": "Alterner Obsidian, Aurora, Nebula",
            "kind": "action"
        }, {
            "id": "action:gamer",
            "title": "Basculer le Mode Gamer",
            "detail": "Réduire les effets visuels de l’aperçu",
            "kind": "action"
        }, {
            "id": "workspace:0",
            "title": "Espace Focus",
            "detail": "Basculer vers l’espace 1",
            "kind": "workspace"
        }, {
            "id": "workspace:1",
            "title": "Espace Studio",
            "detail": "Basculer vers l’espace 2",
            "kind": "workspace"
        }, {
            "id": "workspace:2",
            "title": "Espace Play",
            "detail": "Basculer vers l’espace 3",
            "kind": "workspace"
        }, {
            "id": "workspace:3",
            "title": "Espace Lab",
            "detail": "Basculer vers l’espace 4",
            "kind": "workspace"
        }]

    onGamerModeChanged: {
        preferencesStore.setValue("gamerModeEnabled", gamerMode);
        preferencesStore.sync();
    }
    onReduceMotionChanged: {
        preferencesStore.setValue("reducedMotionEnabled", reduceMotion);
        preferencesStore.sync();
    }

    Component.onCompleted: {
        if (!useMemoryPreferences) {
            var fileNameLiteral = JSON.stringify(preferencesFileName);
            var qmlSource = "import Qt.labs.settings 1.0; Settings { category: 'Preferences'; fileName: " + fileNameLiteral + " }";
            persistentPreferences = Qt.createQmlObject(qmlSource, root, "NexoraUserPreferences");
            if (persistentPreferences)
                preferencesStore = persistentPreferences;
        }
        Qt.callLater(function() {
            root.requestActivate()
        })
    }

    function setTheme(name) {
        if (themes[name] !== undefined) {
            currentTheme = name;
            palette = themes[name];
            preferencesStore.setValue("themeName", name);
            preferencesStore.sync();
        }
    }

    function resetPreferences() {
        setTheme("Obsidian");
        gamerMode = false;
        reduceMotion = false;
        preferencesStore.setValue("gamerModeEnabled", false);
        preferencesStore.setValue("reducedMotionEnabled", false);
        preferencesStore.sync();
    }

    function nextTheme() {
        var i = themeNames.indexOf(currentTheme);
        setTheme(themeNames[(i + 1) % themeNames.length]);
    }

    function launchApp(appId, options) {
        options = options || ({});
        launcherOpen = false;
        commandOpen = false;
        quickPanelOpen = false;
        var labels = {
            "browser": "Navigateur",
            "files": "Fichiers",
            "editor": "Éditeur de code",
            "image": "Images",
            "terminal": "Terminal",
            "media": "Média",
            "music": "Musique",
            "settings": "Paramètres",
            "monitor": "Moniteur système",
            "store": "Nexora Store",
            "games": "Mini-jeux Nexora",
            "assistant": "Assistant Nexora"
        };
        var glyphs = {
            "browser": "WEB",
            "files": "DOC",
            "editor": "</>",
            "image": "IMG",
            "terminal": ">_",
            "media": "PLAY",
            "music": "♫",
            "settings": "SET",
            "monitor": "SYS",
            "store": "APP",
            "games": "GAME",
            "assistant": "AI"
        };
        var id = nextWindowId++;
        var offset = (openWindows.length % 5) * 34;
        var item = {
            "uid": id,
            "appId": appId,
            "title": labels[appId] || "Application",
            "glyph": glyphs[appId] || "NX",
            "workspace": currentWorkspace,
            "x": Math.max(30, 130 + offset),
            "y": Math.max(92, 112 + offset),
            "initialPrompt": appId === "assistant" ? (options.initialPrompt || "") : "",
            "initialText": appId === "editor" ? (options.initialText || "") : "",
            "backendOverride": appId === "assistant" ? (options.backendOverride || null) : null,
            "width": appId === "assistant" ? Math.min(1040, Math.max(820, root.width * 0.72)) : appId === "image" ? Math.min(1100, Math.max(720, root.width * 0.76)) : appId === "games" ? Math.min(1000, Math.max(820, root.width * 0.70)) : appId === "monitor" ? Math.min(980, Math.max(760, root.width * 0.66)) : appId === "music" ? Math.min(900, Math.max(700, root.width * 0.61)) : Math.min(760, Math.max(480, root.width * 0.53)),
            "height": appId === "assistant" ? Math.min(780, Math.max(620, root.height * 0.78)) : appId === "image" ? Math.min(760, Math.max(560, root.height * 0.74)) : appId === "games" ? Math.min(780, Math.max(620, root.height * 0.74)) : appId === "monitor" ? Math.min(720, Math.max(520, root.height * 0.68)) : appId === "music" ? Math.min(640, Math.max(500, root.height * 0.68)) : Math.min(540, Math.max(360, root.height * 0.55))
        };
        openWindows = openWindows.concat([item]);
    }

    function closeWindow(uid) {
        var remaining = [];
        for (var i = 0; i < openWindows.length; ++i) {
            if (openWindows[i].uid !== uid)
                remaining.push(openWindows[i]);
        }
        openWindows = remaining;
    }

    function raiseWindow(uid) {
        var selected = null;
        var remaining = [];
        for (var i = 0; i < openWindows.length; ++i) {
            if (openWindows[i].uid === uid)
                selected = openWindows[i];
            else
                remaining.push(openWindows[i]);
        }
        if (selected !== null)
            openWindows = remaining.concat([selected]);
    }

    function workspaceWindowCount(workspaceIndex) {
        var count = 0;
        for (var i = 0; i < openWindows.length; ++i) {
            if (openWindows[i].workspace === workspaceIndex)
                count += 1;
        }
        return count;
    }

    function searchCommands(query) {
        var q = query.trim().toLowerCase();
        if (q.length === 0)
            return commandCatalog.slice(0, 7);
        var found = [];
        for (var i = 0; i < commandCatalog.length; ++i) {
            var c = commandCatalog[i];
            if ((c.title + " " + c.detail + " " + c.id).toLowerCase().indexOf(q) !== -1)
                found.push(c);
        }
        if (found.length === 0) {
            return [{
                    "id": "assistant:ask",
                    "title": "Demander à Nexora IA",
                    "detail": "Le texte sera prérempli; l’envoi reste manuel",
                    "kind": "assistant",
                    "prompt": query
                }];
        }
        return found.slice(0, 8);
    }

    function executeCommand(id, payload) {
        if (id.indexOf("open:") === 0) {
            launchApp(id.substring(5));
        } else if (id === "assistant:ask") {
            launchApp("assistant", {
                    "initialPrompt": payload ? payload.prompt : ""
                });
        } else if (id === "action:next-theme") {
            nextTheme();
            commandOpen = false;
        } else if (id === "action:gamer") {
            gamerMode = !gamerMode;
            commandOpen = false;
        } else if (id.indexOf("workspace:") === 0) {
            currentWorkspace = parseInt(id.substring(10));
            commandOpen = false;
        }
    }

    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: {
            commandOpen = !commandOpen;
            launcherOpen = false;
            quickPanelOpen = false;
        }
    }
    Shortcut {
        sequence: "Meta+Space"
        onActivated: {
            commandOpen = !commandOpen;
            launcherOpen = false;
            quickPanelOpen = false;
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            commandOpen = false;
            launcherOpen = false;
            quickPanelOpen = false;
        }
    }
    Shortcut {
        sequence: "F11"
        onActivated: root.visibility = root.visibility === Window.FullScreen ? Window.Maximized : Window.FullScreen
    }
    Shortcut {
        sequence: "Ctrl+Alt+1"
        onActivated: currentWorkspace = 0
    }
    Shortcut {
        sequence: "Ctrl+Alt+2"
        onActivated: currentWorkspace = 1
    }
    Shortcut {
        sequence: "Ctrl+Alt+3"
        onActivated: currentWorkspace = 2
    }
    Shortcut {
        sequence: "Ctrl+Alt+4"
        onActivated: currentWorkspace = 3
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.palette.background
            }
            GradientStop {
                position: 1.0
                color: Qt.darker(root.palette.background, 1.18)
            }
        }
    }

    // Fond décoratif non interactif. Le mode Gamer désactive son mouvement.
    Item {
        anchors.fill: parent
        visible: !root.gamerMode && !root.reduceMotion
        opacity: 0.58
        Repeater {
            model: 26
            Rectangle {
                required property int index
                width: (index % 3) + 2
                height: width
                radius: width / 2
                x: (index * 173 + 83) % Math.max(1, parent.width)
                y: (index * 97 + 31) % Math.max(1, parent.height)
                color: index % 4 === 0 ? root.palette.cyan : root.palette.violet
                opacity: 0.16 + (index % 5) * 0.06
                SequentialAnimation on opacity  {
                    running: !root.gamerMode && !root.reduceMotion
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.05
                        duration: 1900 + (index % 5) * 170
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 0.16 + (index % 5) * 0.06
                        duration: 2100 + (index % 4) * 190
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
        Rectangle {
            width: Math.min(parent.width * 0.4, 560)
            height: width
            radius: width / 2
            x: parent.width * 0.62 - width / 2
            y: parent.height * 0.4 - height / 2
            color: "transparent"
            border.color: root.palette.indigo
            border.width: 1
            opacity: 0.12
        }
    }

    // Barre supérieure.
    Rectangle {
        id: topBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 58
        color: Qt.rgba(15 / 255, 20 / 255, 37 / 255, root.gamerMode ? 0.98 : 0.88)
        border.color: root.palette.border
        border.width: 1
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 14
            Image {
                source: "../../assets/branding/nexora-grub-mark.png"
                sourceSize.width: 32
                sourceSize.height: 32
                fillMode: Image.PreserveAspectFit
            }
            Text {
                text: "NEXORA"
                color: root.palette.text
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 2
            }
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                color: root.palette.border
            }
            Text {
                text: root.workspaceNames[root.currentWorkspace]
                color: root.palette.muted
                font.pixelSize: 13
            }
            Item {
                Layout.fillWidth: true
            }
            Rectangle {
                Layout.preferredWidth: 126
                Layout.preferredHeight: 34
                radius: 17
                color: root.gamerMode ? Qt.rgba(108 / 255, 230 / 255, 179 / 255, 0.12) : root.palette.raised
                border.color: root.gamerMode ? root.palette.good : root.palette.border
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.gamerMode ? root.palette.good : root.palette.cyan
                    }
                    Text {
                        text: root.gamerMode ? "MODE GAMER" : root.currentTheme.toUpperCase()
                        color: root.palette.text
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.7
                    }
                }
                MouseArea {
                    id: themeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.nextTheme()
                }
                ToolTip.visible: themeArea.containsMouse
                ToolTip.text: "Cliquer pour changer de thème"
            }
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 36
                radius: 12
                color: quickPanelOpen ? root.palette.hover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "⋮"
                    color: root.palette.text
                    font.pixelSize: 21
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.quickPanelOpen = !root.quickPanelOpen;
                        root.commandOpen = false;
                        root.launcherOpen = false;
                    }
                }
            }
            Text {
                id: clockText
                color: root.palette.text
                font.pixelSize: 13
                font.family: "monospace"
                text: Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm")
                Timer {
                    interval: 30000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm")
                }
            }
        }
    }

    // Zone de bureau et fenêtres de démonstration.
    Item {
        id: desktopCanvas
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: dock.top
        clip: true

        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 10
            Text {
                text: "BONJOUR"
                color: root.palette.muted
                font.pixelSize: 12
                font.letterSpacing: 3
            }
            Text {
                text: root.workspaceNames[root.currentWorkspace]
                color: root.palette.text
                font.pixelSize: 34
                font.weight: Font.Light
            }
            Text {
                text: root.gamerMode ? "Mode Gamer — effets du shell réduits" : "Votre espace, à votre façon."
                color: root.palette.muted
                font.pixelSize: 14
            }
        }

        Repeater {
            model: root.openWindows
            delegate: WindowCard {
                required property var modelData
                required property int index
                shell: root
                descriptor: modelData
                visible: modelData.workspace === root.currentWorkspace
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                z: index + 1
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 26
            anchors.bottomMargin: 28
            width: 260
            height: 114
            radius: 18
            color: Qt.rgba(16 / 255, 22 / 255, 41 / 255, 0.72)
            border.color: root.palette.border
            visible: !root.gamerMode
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 7
                Text {
                    text: "ESPACE DE TRAVAIL"
                    color: root.palette.muted
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.6
                }
                Text {
                    text: "Ctrl + Alt + 1–4"
                    color: root.palette.text
                    font.pixelSize: 18
                    font.family: "monospace"
                }
                Text {
                    text: "ou choisissez un aperçu dans le dock"
                    color: root.palette.muted
                    font.pixelSize: 11
                }
            }
        }
    }

    // Dock inférieur, espaces visuels et applications épinglées.
    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        width: Math.min(parent.width - 40, 930)
        height: 82
        radius: 24
        color: Qt.rgba(16 / 255, 22 / 255, 41 / 255, root.gamerMode ? 0.98 : 0.93)
        border.color: root.palette.border
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: 17
                color: root.launcherOpen ? root.palette.hover : root.palette.raised
                border.color: root.launcherOpen ? root.palette.cyan : root.palette.border
                Image {
                    anchors.centerIn: parent
                    source: "../../assets/branding/nexora-grub-mark.png"
                    sourceSize.width: 34
                    sourceSize.height: 34
                }
                MouseArea {
                    id: launcherButtonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.launcherOpen = !root.launcherOpen;
                        root.commandOpen = false;
                        root.quickPanelOpen = false;
                    }
                }
                ToolTip.visible: launcherButtonArea.containsMouse
                ToolTip.text: "Lanceur d’applications"
            }
            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    Layout.preferredWidth: 55
                    Layout.preferredHeight: 54
                    radius: 14
                    color: root.currentWorkspace === index ? Qt.rgba(119 / 255, 113 / 255, 1, 0.18) : "transparent"
                    border.color: root.currentWorkspace === index ? root.palette.indigo : "transparent"
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "0" + (index + 1)
                            color: root.currentWorkspace === index ? root.palette.text : root.palette.muted
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Rectangle {
                            width: 38
                            height: 15
                            radius: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: root.palette.background
                            border.color: root.currentWorkspace === index ? root.palette.cyan : root.palette.border
                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Repeater {
                                    model: Math.min(4, root.workspaceWindowCount(index))
                                    delegate: Rectangle {
                                        width: 6
                                        height: 8
                                        radius: 2
                                        color: root.palette.indigo
                                    }
                                }
                                Text {
                                    visible: root.workspaceWindowCount(index) === 0
                                    text: "·"
                                    color: root.palette.muted
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: workspaceArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.currentWorkspace = index;
                            root.launcherOpen = false;
                            root.commandOpen = false;
                        }
                    }
                    ToolTip.visible: workspaceArea.containsMouse
                    ToolTip.text: root.workspaceNames[index]
                }
            }
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 42
                color: root.palette.border
            }
            Repeater {
                model: root.pinnedApps
                delegate: Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 54
                    radius: 15
                    color: mouseArea.containsMouse ? root.palette.hover : "transparent"
                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Rectangle {
                            width: 34
                            height: 32
                            radius: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.045)
                            border.color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.07)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.glyph
                                color: modelData.color
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "monospace"
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: root.palette.muted
                            font.pixelSize: 8
                            elide: Text.ElideRight
                            width: 55
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.launchApp(modelData.id)
                    }
                    ToolTip.visible: mouseArea.containsMouse
                    ToolTip.text: modelData.label
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Rectangle {
                Layout.preferredWidth: 98
                Layout.preferredHeight: 48
                radius: 16
                color: root.gamerMode ? Qt.rgba(108 / 255, 230 / 255, 179 / 255, 0.12) : root.palette.raised
                border.color: root.gamerMode ? root.palette.good : root.palette.border
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.gamerMode ? "GAMER: ON" : "MODE GAMER"
                        color: root.gamerMode ? root.palette.good : root.palette.text
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.gamerMode ? "aperçu" : "effets réduits"
                        color: root.palette.muted
                        font.pixelSize: 8
                    }
                }
                MouseArea {
                    id: gamerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.gamerMode = !root.gamerMode
                }
                ToolTip.visible: gamerArea.containsMouse
                ToolTip.text: "Dans cette phase, réduit seulement les effets visuels de l’aperçu"
            }
        }
    }

    // Lanceur d’applications.
    Rectangle {
        id: launcherPanel
        visible: root.launcherOpen
        anchors.left: parent.left
        anchors.bottom: dock.top
        anchors.leftMargin: Math.max(20, (parent.width - dock.width) / 2)
        anchors.bottomMargin: 12
        width: 376
        height: Math.min(520, Math.max(360, parent.height - 180))
        radius: 24
        color: root.palette.surface
        border.color: root.palette.border
        z: 1000
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16
            RowLayout {
                Text {
                    text: "Applications"
                    color: root.palette.text
                    font.pixelSize: 20
                    font.bold: true
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: "APERÇU"
                    color: root.palette.muted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.4
                }
            }
            TextField {
                id: launcherSearch
                Layout.fillWidth: true
                placeholderText: "Rechercher une application…"
                color: root.palette.text
                placeholderTextColor: root.palette.muted
                leftPadding: 14
                background: Rectangle {
                    radius: 12
                    color: root.palette.raised
                    border.color: launcherSearch.activeFocus ? root.palette.cyan : root.palette.border
                }
                onTextChanged: launcherRepeater.model = filteredApps(text)
                Component.onCompleted: launcherRepeater.model = filteredApps("")
            }
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rowSpacing: 12
                columnSpacing: 10
                Repeater {
                    id: launcherRepeater
                    model: root.launcherApps
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.height < 720 ? 58 : 72
                        radius: 14
                        color: launchMouse.containsMouse ? root.palette.hover : root.palette.raised
                        border.color: launchMouse.containsMouse ? root.palette.indigo : root.palette.border
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.glyph
                                color: modelData.color
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "monospace"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: root.palette.text
                                font.pixelSize: 11
                            }
                        }
                        MouseArea {
                            id: launchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launchApp(modelData.id)
                        }
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Mini-jeux hors ligne · aucune connexion requise"
                color: root.palette.muted
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }

    // Barre de commande universelle : applications, espaces et actions autorisées.
    Rectangle {
        id: commandBackdrop
        visible: root.commandOpen
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        z: 1100
        MouseArea {
            anchors.fill: parent
            onClicked: root.commandOpen = false
        }
        Rectangle {
            id: commandPanel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.max(80, parent.height * 0.16)
            width: Math.min(680, parent.width - 40)
            height: Math.min(520, parent.height - 140)
            radius: 22
            color: root.palette.surface
            border.color: root.palette.border
            MouseArea {
                anchors.fill: parent
                onClicked: function (mouse) {
                    mouse.accepted = true;
                }
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                TextField {
                    id: commandSearch
                    objectName: "commandSearchField"
                    Layout.fillWidth: true
                    placeholderText: "Rechercher, lancer une action ou demander à Nexora…"
                    color: root.palette.text
                    placeholderTextColor: root.palette.muted
                    font.pixelSize: 17
                    leftPadding: 14
                    background: Rectangle {
                        radius: 12
                        color: root.palette.raised
                        border.color: commandSearch.activeFocus ? root.palette.cyan : root.palette.border
                    }
                    onTextChanged: commandResults.model = root.searchCommands(text)
                    onAccepted: {
                        var results = root.searchCommands(text);
                        if (results.length > 0)
                            root.executeCommand(results[0].id, results[0]);
                    }
                    onVisibleChanged: if (visible)
                        forceActiveFocus()
                    Component.onCompleted: commandResults.model = root.searchCommands("")
                }
                Text {
                    text: "RÉSULTATS ET ACTIONS SÛRES"
                    color: root.palette.muted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                ListView {
                    id: commandResults
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: root.searchCommands("")
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: commandResults.width
                        height: 58
                        radius: 12
                        color: resultMouse.containsMouse || index === 0 ? root.palette.raised : "transparent"
                        border.color: resultMouse.containsMouse ? root.palette.indigo : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 13
                            anchors.rightMargin: 13
                            spacing: 12
                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 9
                                color: root.palette.hover
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.kind === "workspace" ? "WS" : (modelData.kind === "action" ? "⚡" : (modelData.kind === "assistant" ? "AI" : "NX"))
                                    color: root.palette.cyan
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    text: modelData.title
                                    color: root.palette.text
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    text: modelData.detail
                                    color: root.palette.muted
                                    font.pixelSize: 10
                                }
                            }
                            Text {
                                text: "↵"
                                color: root.palette.muted
                                font.pixelSize: 16
                            }
                        }
                        MouseArea {
                            id: resultMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.executeCommand(modelData.id, modelData)
                        }
                    }
                }
                Text {
                    text: "Ctrl + Space · Échap pour fermer · Une demande libre est seulement préremplie pour l’assistant"
                    color: root.palette.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Panneau rapide : préférences de l’aperçu, aucune action système privilégiée.
    Rectangle {
        id: quickBackdrop
        visible: root.quickPanelOpen
        anchors.fill: parent
        color: "transparent"
        z: 1200
        MouseArea {
            anchors.fill: parent
            onClicked: root.quickPanelOpen = false
        }
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: topBar.height + 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            width: 310
            height: 344
            radius: 22
            color: root.palette.surface
            border.color: root.palette.border
            MouseArea {
                anchors.fill: parent
                onClicked: function (mouse) {
                    mouse.accepted = true;
                }
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                Text {
                    text: "Centre de contrôle"
                    color: root.palette.text
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    text: "Réglages de l’aperçu du shell"
                    color: root.palette.muted
                    font.pixelSize: 11
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.palette.border
                }
                Text {
                    text: "THÈME"
                    color: root.palette.muted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.4
                }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: root.themeNames
                        delegate: Button {
                            required property string modelData
                            Layout.fillWidth: true
                            text: modelData
                            onClicked: root.setTheme(modelData)
                            background: Rectangle {
                                radius: 9
                                color: root.currentTheme === modelData ? root.palette.hover : root.palette.raised
                                border.color: root.currentTheme === modelData ? root.palette.cyan : root.palette.border
                            }
                            contentItem: Text {
                                text: parent.text
                                color: root.palette.text
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.palette.border
                }
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            text: "Mode Gamer"
                            color: root.palette.text
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            text: "Réduit les décorations du prototype"
                            color: root.palette.muted
                            font.pixelSize: 10
                        }
                    }
                    Switch {
                        checked: root.gamerMode
                        onToggled: root.gamerMode = checked
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
                Text {
                    Layout.fillWidth: true
                    text: "Le Mode Gamer ne modifie pas les services ni les performances du système dans cette maquette."
                    color: root.palette.muted
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    function filteredApps(query) {
        var q = query.trim().toLowerCase();
        if (q.length === 0)
            return launcherApps;
        var result = [];
        for (var i = 0; i < launcherApps.length; ++i) {
            if (launcherApps[i].label.toLowerCase().indexOf(q) !== -1 || launcherApps[i].id.indexOf(q) !== -1)
                result.push(launcherApps[i]);
        }
        return result;
    }
}
