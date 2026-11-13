import QtQuick 2.15
import QtTest 1.3
import Qt.labs.folderlistmodel 2.15

TestCase {
    name: "NexoraFileManager"
    when: windowShown

    property var fileApp: null

    QtObject {
        id: testShell
        property var palette: ({
            background: "#090c16",
            surface: "#101629",
            raised: "#171f35",
            hover: "#202b46",
            border: "#293550",
            text: "#edf0ff",
            muted: "#93a0bf",
            violet: "#a56bff",
            indigo: "#7771ff",
            cyan: "#41e7ff",
            focus: "#70eaff",
            good: "#6ce6b3"
        })
    }

    function init() {
        var component = Qt.createComponent(Qt.resolvedUrl("../../src/apps/files/FileManagerApp.qml"))
        compare(component.status, Component.Ready, component.errorString())
        var fixture = Qt.resolvedUrl("../../tests/fixtures/files").toString()
        fileApp = component.createObject(null, {
            shell: testShell,
            initialFolder: fixture,
            width: 900,
            height: 620
        })
        verify(fileApp !== null, "L’explorateur doit être instanciable")
        tryCompare(fileApp, "modelStatus", FolderListModel.Ready, 3000)
    }

    function cleanup() {
        if (fileApp !== null) {
            fileApp.destroy()
            fileApp = null
        }
    }

    function test_lists_real_fixture_and_hides_dotfiles_by_default() {
        verify(fileApp.containsName("alpha.txt"))
        verify(fileApp.containsName("readme.md"))
        verify(fileApp.containsName("nested"))
        verify(!fileApp.containsName(".nexora-hidden"))
    }

    function test_local_navigation_and_parent() {
        var nested = Qt.resolvedUrl("../../tests/fixtures/files/nested").toString()
        verify(fileApp.navigateTo(nested))
        tryVerify(function() { return fileApp.containsName("child.txt") }, 3000)
        fileApp.goParent()
        tryVerify(function() { return fileApp.containsName("alpha.txt") }, 3000)
    }

    function test_remote_locations_rejected() {
        var before = fileApp.currentFolderUrl.toString()
        verify(!fileApp.navigateTo("https://example.org"))
        compare(fileApp.currentFolderUrl.toString(), before)
        verify(fileApp.statusMessage.indexOf("chemins locaux") >= 0)
        verify(!fileApp.navigateTo("file://server/share"))
        compare(fileApp.currentFolderUrl.toString(), before)
    }

    function test_show_hidden_and_name_filter() {
        fileApp.showHiddenFiles = true
        tryVerify(function() { return fileApp.containsName(".nexora-hidden") }, 3000)
        var filter = findChild(fileApp, "fileFilterField")
        verify(filter !== null)
        filter.text = "alpha"
        tryVerify(function() { return !fileApp.containsName("readme.md") }, 3000)
        verify(fileApp.containsName("alpha.txt"))
    }

    function test_executable_file_is_never_opened() {
        fileApp.selectedUrl = Qt.resolvedUrl("../../tests/fixtures/files/danger.sh").toString()
        fileApp.selectedName = "danger.sh"
        fileApp.selectedIsDir = false
        verify(!fileApp.openSelected())
        verify(fileApp.statusMessage.indexOf("Ouverture bloquée") >= 0)
    }
}
