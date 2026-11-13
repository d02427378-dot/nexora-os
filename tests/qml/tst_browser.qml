import QtQuick 2.15
import QtTest 1.3
import "../../src/apps/browser/BrowserNavigation.js" as Navigation

TestCase {
    name: "NexoraBrowserNavigation"

    function test_url_and_search_normalization() {
        compare(Navigation.normalizeInput("https://example.org/path"), "https://example.org/path")
        compare(Navigation.normalizeInput("http://example.org"), "http://example.org")
        compare(Navigation.normalizeInput("example.org"), "https://example.org")
        compare(Navigation.normalizeInput("nexora desktop"), "https://duckduckgo.com/?q=nexora%20desktop")
        compare(Navigation.normalizeInput("   "), "")
    }

    function test_unsafe_schemes_rejected() {
        compare(Navigation.normalizeInput("file:///etc/passwd"), "")
        compare(Navigation.normalizeInput("javascript:alert(1)"), "")
        compare(Navigation.normalizeInput("data:text/html,test"), "")
        verify(!Navigation.isAllowedScheme("file:///etc/passwd"))
        verify(!Navigation.isAllowedScheme("javascript:alert(1)"))
        verify(Navigation.isAllowedScheme("https://example.org"))
        verify(Navigation.isAllowedScheme("about:blank"))
    }
}
