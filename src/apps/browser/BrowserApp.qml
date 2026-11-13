import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine
import "BrowserNavigation.js" as Navigation

Item {
    id: browserApp
    objectName: "nexoraBrowser"
    required property var shell

    property string lastError: ""
    property bool pageLoaded: false
    property string pageTitle: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            ToolButton {
                text: "‹"
                enabled: webView.canGoBack
                onClicked: webView.goBack()
                ToolTip.visible: hovered
                ToolTip.text: "Précédent"
            }
            ToolButton {
                text: "›"
                enabled: webView.canGoForward
                onClicked: webView.goForward()
                ToolTip.visible: hovered
                ToolTip.text: "Suivant"
            }
            ToolButton {
                text: webView.loading ? "×" : "↻"
                onClicked: webView.loading ? webView.stop() : webView.reload()
                ToolTip.visible: hovered
                ToolTip.text: webView.loading ? "Arrêter le chargement" : "Recharger"
            }

            TextField {
                id: addressField
                objectName: "browserAddressField"
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                text: "about:blank"
                placeholderText: "Adresse web ou recherche"
                color: browserApp.shell.palette.text
                placeholderTextColor: browserApp.shell.palette.muted
                selectByMouse: true
                leftPadding: 12
                rightPadding: 12
                background: Rectangle {
                    radius: 10
                    color: browserApp.shell.palette.raised
                    border.color: addressField.activeFocus ? browserApp.shell.palette.cyan : browserApp.shell.palette.border
                }
                onAccepted: browserApp.navigate(text)
            }

            Button {
                text: "Aller"
                onClicked: browserApp.navigate(addressField.text)
                background: Rectangle {
                    radius: 10
                    color: browserApp.shell.palette.indigo
                }
                contentItem: Text {
                    text: "Aller"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            radius: 1
            color: browserApp.shell.palette.border
            Rectangle {
                width: webView.loading ? parent.width * webView.loadProgress / 100 : 0
                height: parent.height
                radius: 1
                color: browserApp.shell.palette.cyan
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        WebEngineProfile {
            id: privateProfile
            offTheRecord: true
            onDownloadRequested: function(download) {
                download.cancel()
                statusText.text = "Téléchargement annulé : validation et destination manuelles à implémenter."
            }
        }

        WebEngineView {
            id: webView
            objectName: "browserWebView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            url: "about:blank"
            profile: privateProfile

            settings.javascriptCanOpenWindows: false
            settings.localContentCanAccessFileUrls: false
            settings.localContentCanAccessRemoteUrls: false
            settings.pluginsEnabled: false

            onUrlChanged: {
                var current = url.toString()
                if (current !== "about:blank")
                    addressField.text = current
            }
            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebEngineView.LoadStartedStatus) {
                    browserApp.pageLoaded = false
                    statusText.text = "Chargement…"
                } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    browserApp.pageLoaded = true
                    browserApp.pageTitle = webView.title
                    statusText.text = "Page chargée"
                    browserApp.lastError = ""
                } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                    browserApp.pageLoaded = false
                    statusText.text = "Échec du chargement"
                    browserApp.lastError = "La page n’a pas pu être chargée. Vérifiez le réseau et l’adresse."
                }
            }
            onNavigationRequested: function(request) {
                var target = request.url.toString()
                if (!Navigation.isAllowedScheme(target)) {
                    var scheme = request.url.scheme.toLowerCase()
                    request.action = WebEngineView.IgnoreRequest
                    statusText.text = "Navigation bloquée : schéma non autorisé (" + scheme + ")."
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            radius: 7
            color: "transparent"
            Text {
                id: statusText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: browserApp.lastError.length > 0 ? browserApp.lastError : "Navigation HTTP/HTTPS · profil privé · téléchargements annulés par défaut"
                color: browserApp.lastError.length > 0 ? "#ff9eae" : browserApp.shell.palette.muted
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    function normalizeInput(input) {
        return Navigation.normalizeInput(input)
    }

    function navigate(input) {
        var target = normalizeInput(input)
        if (target.length === 0) {
            lastError = "Adresse vide ou schéma bloqué. Seuls HTTP et HTTPS sont autorisés."
            return false
        }
        lastError = ""
        addressField.text = target
        webView.url = target
        return true
    }
}
