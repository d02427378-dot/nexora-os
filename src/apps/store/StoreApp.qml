import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Nexora.Store 1.0

Item {
    id: storeApp
    objectName: "nexoraSoftwareCenter"
    required property var shell

    property var filteredPackages: []
    property string pendingPackage: ""
    property string pendingTitle: ""
    property string pendingAction: ""
    property string localMessage: ""
    property alias backendForTests: backend
    property alias confirmationDialogForTests: operationDialog

    SoftwareCenterBackend {
        id: backend
        objectName: "nexoraSoftwareCenterBackend"
        onSimulationReadyChanged: {
            if (simulationReady) {
                storeApp.pendingPackage = simulationPackage
                storeApp.pendingAction = simulationAction
                var entry = storeApp.packageById(simulationPackage)
                storeApp.pendingTitle = entry ? entry.title : simulationPackage
                operationDialog.open()
            }
        }
        onOperationFinished: function(packageId, action, success) {
            if (!success)
                storeApp.pendingPackage = packageId
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: Qt.rgba(245 / 255, 167 / 255, 1, 0.12)
                border.color: Qt.rgba(245 / 255, 167 / 255, 1, 0.28)
                Text { anchors.centerIn: parent; text: "APP"; color: "#f5a7d3"; font.pixelSize: 10; font.bold: true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: "NEXORA STORE"; color: storeApp.shell.palette.text; font.pixelSize: 13; font.bold: true }
                Text { text: "Catalogue APT local · dépôts système configurés"; color: storeApp.shell.palette.muted; font.pixelSize: 9 }
            }
            Button {
                objectName: "storeRefreshButton"
                text: "Actualiser"
                enabled: !backend.busy
                onClicked: backend.refresh()
                background: Rectangle { radius: 8; color: storeApp.shell.palette.raised; border.color: storeApp.shell.palette.border }
                contentItem: Text { text: "Actualiser"; color: storeApp.shell.palette.text; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 8; rightPadding: 8 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: searchField
                objectName: "storeSearchField"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "Rechercher dans le catalogue…"
                color: storeApp.shell.palette.text
                placeholderTextColor: storeApp.shell.palette.muted
                leftPadding: 11
                background: Rectangle { radius: 9; color: storeApp.shell.palette.background; border.color: searchField.activeFocus ? storeApp.shell.palette.cyan : storeApp.shell.palette.border }
                onTextChanged: storeApp.updateFilter()
            }
            Text {
                text: storeApp.filteredPackages.length + " / " + backend.packages.length
                color: storeApp.shell.palette.muted
                font.pixelSize: 9
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: storeApp.shell.palette.background
            border.color: storeApp.shell.palette.border
            clip: true

            ListView {
                id: packageList
                objectName: "storePackageList"
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 7
                model: storeApp.filteredPackages
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    required property var modelData
                    width: packageList.width
                    height: 88
                    radius: 10
                    color: storeApp.shell.palette.surface
                    border.color: storeApp.shell.palette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 10
                        spacing: 9
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 11
                            color: Qt.rgba(119 / 255, 113 / 255, 1, 0.13)
                            Text { anchors.centerIn: parent; text: modelData.title.substring(0, 2).toUpperCase(); color: storeApp.shell.palette.cyan; font.pixelSize: 10; font.bold: true }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: modelData.title; color: storeApp.shell.palette.text; font.pixelSize: 10; font.bold: true; elide: Text.ElideRight }
                                Text { text: modelData.installed ? "INSTALLÉ" : modelData.available ? "DISPONIBLE" : "ABSENT DES SOURCES"; color: modelData.installed ? storeApp.shell.palette.good : modelData.available ? storeApp.shell.palette.cyan : storeApp.shell.palette.muted; font.pixelSize: 7; font.bold: true }
                            }
                            Text { text: modelData.category + " · " + modelData.id + (modelData.installed ? " · " + modelData.installedVersion : modelData.available ? " · " + modelData.version : ""); color: storeApp.shell.palette.muted; font.pixelSize: 8; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: modelData.description; color: storeApp.shell.palette.text; font.pixelSize: 8; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        Button {
                            text: modelData.installed ? "Prévisualiser le retrait" : modelData.available ? "Prévisualiser l’installation" : "Indisponible"
                            enabled: !backend.busy && (modelData.installed || modelData.available)
                            onClicked: storeApp.previewAction(modelData)
                            background: Rectangle { radius: 8; color: enabled ? storeApp.shell.palette.indigo : storeApp.shell.palette.raised }
                            contentItem: Text { text: parent.text; color: enabled ? "#ffffff" : storeApp.shell.palette.muted; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 8; rightPadding: 8 }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 36
                    spacing: 8
                    visible: !backend.busy && storeApp.filteredPackages.length === 0
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: backend.packages.length === 0 ? "Aucun catalogue chargé" : "Aucun résultat"; color: storeApp.shell.palette.text; font.pixelSize: 12; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; text: backend.packages.length === 0 ? "Les index APT locaux doivent être présents pour afficher les applications." : "Modifiez votre recherche ou effacez le filtre."; color: storeApp.shell.palette.muted; font.pixelSize: 9; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: backend.busy
                visible: backend.busy
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Rectangle { width: 7; height: 7; radius: 4; color: backend.busy ? storeApp.shell.palette.cyan : storeApp.shell.palette.good }
            Text { Layout.fillWidth: true; text: storeApp.localMessage.length > 0 ? storeApp.localMessage : backend.statusMessage.length > 0 ? backend.statusMessage : "Catalogue non actualisé"; color: storeApp.shell.palette.muted; font.pixelSize: 8; elide: Text.ElideRight }
        }

        TextArea {
            objectName: "storeOperationOutput"
            Layout.fillWidth: true
            Layout.preferredHeight: backend.operationOutput.length > 0 ? 62 : 0
            visible: backend.operationOutput.length > 0
            readOnly: true
            wrapMode: TextArea.Wrap
            text: backend.operationOutput
            color: storeApp.shell.palette.muted
            font.pixelSize: 8
            background: Rectangle { radius: 8; color: storeApp.shell.palette.background; border.color: storeApp.shell.palette.border }
        }
    }

    Dialog {
        id: operationDialog
        objectName: "storeOperationConfirmation"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(560, storeApp.width - 30)
        title: pendingAction === "install" ? "Confirmer l’installation" : "Confirmer le retrait"
        standardButtons: Dialog.NoButton

        contentItem: ColumnLayout {
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: pendingAction === "install"
                    ? "APT va installer « " + storeApp.pendingTitle + " » (" + storeApp.pendingPackage + ") et les dépendances indiquées ci-dessous. Cette opération modifie le système et peut demander votre authentification administrateur."
                    : "APT va retirer « " + storeApp.pendingTitle + " » (" + storeApp.pendingPackage + "). Les fichiers de configuration ne sont pas purgés. Vérifiez la simulation avant de continuer."
                color: storeApp.shell.palette.text
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }
            TextArea {
                id: simulationDetails
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                readOnly: true
                wrapMode: TextArea.Wrap
                text: backend.simulationOutput
                color: storeApp.shell.palette.muted
                font.pixelSize: 8
                background: Rectangle { radius: 8; color: storeApp.shell.palette.background; border.color: storeApp.shell.palette.border }
            }
            Text {
                Layout.fillWidth: true
                text: "Aucune action n’a été faite par la simulation. La confirmation suivante lance pkexec/apt-get; Annuler ne modifie rien."
                color: "#ffd479"
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }
        }

        footer: RowLayout {
            spacing: 8
            Item { Layout.fillWidth: true }
            Button { text: "Annuler"; onClicked: operationDialog.close() }
            Button {
                objectName: "storeConfirmOperationButton"
                text: pendingAction === "install" ? "Confirmer l’installation" : "Confirmer le retrait"
                onClicked: {
                    var accepted = pendingAction === "install"
                            ? backend.confirmInstall(storeApp.pendingPackage)
                            : backend.confirmRemove(storeApp.pendingPackage)
                    if (!accepted)
                        storeApp.localMessage = "La simulation est périmée ou le paquet n’est plus admissible; actualisez le catalogue."
                    operationDialog.close()
                }
                background: Rectangle { radius: 8; color: storeApp.shell.palette.indigo }
                contentItem: Text { text: parent.text; color: "#ffffff"; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 8; rightPadding: 8 }
            }
        }
    }

    Component.onCompleted: {
        updateFilter()
        backend.refresh()
    }

    function updateFilter() {
        var query = searchField.text.trim().toLowerCase()
        if (query.length === 0) {
            filteredPackages = backend.packages
            return
        }
        var matches = []
        for (var i = 0; i < backend.packages.length; ++i) {
            var item = backend.packages[i]
            var haystack = (item.title + " " + item.id + " " + item.category + " " + item.description).toLowerCase()
            if (haystack.indexOf(query) !== -1)
                matches.push(item)
        }
        filteredPackages = matches
    }

    function packageById(packageId) {
        for (var i = 0; i < backend.packages.length; ++i) {
            if (backend.packages[i].id === packageId)
                return backend.packages[i]
        }
        return null
    }

    function previewAction(item) {
        localMessage = ""
        pendingPackage = item.id
        pendingTitle = item.title
        pendingAction = item.installed ? "remove" : "install"
        var accepted = pendingAction === "install"
                ? backend.previewInstall(item.id)
                : backend.previewRemove(item.id)
        if (!accepted)
            localMessage = "Impossible de préparer la simulation; actualisez le catalogue."
    }
}
