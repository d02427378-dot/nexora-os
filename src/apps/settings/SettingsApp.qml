import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Item {
    id: settingsApp
    objectName: "nexoraSettingsApp"
    required property var shell
    property int selectedPage: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: Qt.rgba(169 / 255, 184 / 255, 215 / 255, 0.14)
                border.color: Qt.rgba(169 / 255, 184 / 255, 215 / 255, 0.3)
                Text { anchors.centerIn: parent; text: "SET"; color: settingsApp.shell.palette.text; font.pixelSize: 10; font.bold: true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Paramètres Nexora"; color: settingsApp.shell.palette.text; font.pixelSize: 14; font.bold: true }
                Text { text: "Préférences utilisateur · enregistrées automatiquement"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
            }
            Text { text: "NEXORA"; color: settingsApp.shell.palette.cyan; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1 }
        }

        TabBar {
            id: pageTabs
            objectName: "settingsPageTabs"
            Layout.fillWidth: true
            currentIndex: settingsApp.selectedPage
            onCurrentIndexChanged: settingsApp.selectedPage = currentIndex
            background: Rectangle { radius: 10; color: settingsApp.shell.palette.background; border.color: settingsApp.shell.palette.border }
            TabButton {
                text: "Apparence"
                contentItem: Text { text: parent.text; color: settingsApp.shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 8; color: pageTabs.currentIndex === 0 ? settingsApp.shell.palette.raised : "transparent" }
            }
            TabButton {
                text: "Bureau"
                contentItem: Text { text: parent.text; color: settingsApp.shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 8; color: pageTabs.currentIndex === 1 ? settingsApp.shell.palette.raised : "transparent" }
            }
            TabButton {
                text: "Système"
                contentItem: Text { text: parent.text; color: settingsApp.shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 8; color: pageTabs.currentIndex === 2 ? settingsApp.shell.palette.raised : "transparent" }
            }
        }

        StackLayout {
            id: pageStack
            objectName: "settingsPageStack"
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: settingsApp.selectedPage

            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ColumnLayout {
                    width: pageStack.width
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 144
                        radius: 12
                        color: settingsApp.shell.palette.surface
                        border.color: settingsApp.shell.palette.border
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            Text { text: "Thème du bureau"; color: settingsApp.shell.palette.text; font.pixelSize: 11; font.bold: true }
                            Text { text: "Change les couleurs du shell et reste mémorisé pour votre prochaine session."; color: settingsApp.shell.palette.muted; font.pixelSize: 9; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 7
                                Repeater {
                                    model: settingsApp.shell.themeNames
                                    delegate: Button {
                                        required property string modelData
                                        objectName: "settingsTheme" + modelData
                                        Layout.fillWidth: true
                                        text: modelData
                                        onClicked: settingsApp.shell.setTheme(modelData)
                                        background: Rectangle {
                                            radius: 8
                                            color: settingsApp.shell.currentTheme === modelData ? settingsApp.shell.palette.hover : settingsApp.shell.palette.raised
                                            border.color: settingsApp.shell.currentTheme === modelData ? settingsApp.shell.palette.cyan : settingsApp.shell.palette.border
                                        }
                                        contentItem: Text { text: parent.text; color: settingsApp.shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        radius: 12
                        color: settingsApp.shell.palette.surface
                        border.color: settingsApp.shell.palette.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: "Réduire les animations"; color: settingsApp.shell.palette.text; font.pixelSize: 10; font.bold: true }
                                Text { text: "Mémorise votre préférence; les transitions du shell sont simplifiées."; color: settingsApp.shell.palette.muted; font.pixelSize: 8; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            }
                            Switch {
                                objectName: "settingsReduceMotionSwitch"
                                checked: settingsApp.shell.reduceMotion
                                onToggled: settingsApp.shell.reduceMotion = checked
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            objectName: "settingsResetButton"
                            text: "Rétablir les préférences"
                            onClicked: settingsApp.shell.resetPreferences()
                            background: Rectangle { radius: 8; color: settingsApp.shell.palette.raised; border.color: settingsApp.shell.palette.border }
                            contentItem: Text { text: parent.text; color: settingsApp.shell.palette.text; font.pixelSize: 8; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 9; rightPadding: 9 }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "Enregistré localement · sans privilèges"; color: settingsApp.shell.palette.good; font.pixelSize: 8 }
                    }
                }
            }

            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ColumnLayout {
                    width: pageStack.width
                    spacing: 10
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90
                        radius: 12
                        color: settingsApp.shell.palette.surface
                        border.color: settingsApp.shell.palette.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: "Mode Gamer"; color: settingsApp.shell.palette.text; font.pixelSize: 11; font.bold: true }
                                Text { text: "Réduit le décor et les panneaux non essentiels de l’aperçu. Ce réglage visuel ne modifie ni les services ni les performances du système."; color: settingsApp.shell.palette.muted; font.pixelSize: 8; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            }
                            Switch {
                                objectName: "settingsGamerModeSwitch"
                                checked: settingsApp.shell.gamerMode
                                onToggled: settingsApp.shell.gamerMode = checked
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 170
                        radius: 12
                        color: settingsApp.shell.palette.surface
                        border.color: settingsApp.shell.palette.border
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            Text { text: "Espaces de travail visuels"; color: settingsApp.shell.palette.text; font.pixelSize: 11; font.bold: true }
                            Repeater {
                                model: settingsApp.shell.workspaceNames
                                delegate: RowLayout {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Text { text: "0" + (index + 1); color: settingsApp.shell.palette.cyan; font.family: "monospace"; font.pixelSize: 9; font.bold: true }
                                    Text { Layout.fillWidth: true; text: modelData; color: settingsApp.shell.palette.text; font.pixelSize: 9 }
                                    Text { text: settingsApp.shell.currentWorkspace === index ? "ACTIF" : "VISUEL"; color: settingsApp.shell.currentWorkspace === index ? settingsApp.shell.palette.good : settingsApp.shell.palette.muted; font.pixelSize: 7; font.bold: true }
                                }
                            }
                            Text { Layout.fillWidth: true; text: "Les espaces du prototype sont visuels; ils ne créent pas encore de bureaux Plasma natifs."; color: settingsApp.shell.palette.muted; font.pixelSize: 8; wrapMode: Text.Wrap }
                        }
                    }
                }
            }

            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ColumnLayout {
                    width: pageStack.width
                    spacing: 10
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 165
                        radius: 12
                        color: settingsApp.shell.palette.surface
                        border.color: settingsApp.shell.palette.border
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            Text { text: "Affichage détecté (lecture seule)"; color: settingsApp.shell.palette.text; font.pixelSize: 11; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Écran"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
                                Text { text: settingsApp.shell.screen ? settingsApp.shell.screen.name : "Non détecté"; color: settingsApp.shell.palette.text; font.pixelSize: 9; elide: Text.ElideRight }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Zone de l’aperçu"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
                                Text { text: Math.round(settingsApp.shell.width) + " × " + Math.round(settingsApp.shell.height) + " px"; color: settingsApp.shell.palette.text; font.pixelSize: 9; font.family: "monospace" }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Densité d’affichage"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
                                Text { text: settingsApp.shell.screen ? settingsApp.shell.screen.devicePixelRatio.toFixed(2) + "×" : "—"; color: settingsApp.shell.palette.text; font.pixelSize: 9; font.family: "monospace" }
                            }
                            Text { Layout.fillWidth: true; text: "La résolution matérielle n’est pas modifiée ici. Utilisez KDE Configuration du système pour les réglages d’écran."; color: settingsApp.shell.palette.muted; font.pixelSize: 8; wrapMode: Text.Wrap }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 135
                        radius: 12
                        color: settingsApp.shell.palette.surface
                        border.color: settingsApp.shell.palette.border
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 7
                            Text { text: "À propos"; color: settingsApp.shell.palette.text; font.pixelSize: 11; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Système détecté"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
                                Text { text: Qt.platform.os; color: settingsApp.shell.palette.text; font.pixelSize: 9 }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Application"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
                                Text { text: Qt.application.name || "Nexora OS"; color: settingsApp.shell.palette.text; font.pixelSize: 9 }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "Qt"; color: settingsApp.shell.palette.muted; font.pixelSize: 9 }
                                Text { text: Qt.application.version || "version non définie"; color: settingsApp.shell.palette.text; font.pixelSize: 9 }
                            }
                            Text { Layout.fillWidth: true; text: "Paramètres avancés du matériel, réseau et comptes restent gérés par les outils KDE du système."; color: settingsApp.shell.palette.muted; font.pixelSize: 8; wrapMode: Text.Wrap }
                        }
                    }
                }
            }
        }
    }
}
