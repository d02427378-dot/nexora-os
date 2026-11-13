.pragma library

function normalizeInput(input) {
    var value = String(input).trim()
    if (value.length === 0)
        return ""

    var lower = value.toLowerCase()
    if (lower.indexOf("http://") === 0 || lower.indexOf("https://") === 0)
        return value
    if (lower.indexOf("file:") === 0 || lower.indexOf("javascript:") === 0 || lower.indexOf("data:") === 0)
        return ""
    if (value.indexOf(" ") === -1 && value.indexOf(".") > 0)
        return "https://" + value

    return "https://duckduckgo.com/?q=" + encodeURIComponent(value)
}

function isAllowedScheme(urlString) {
    var value = String(urlString).trim().toLowerCase()
    return value.indexOf("http://") === 0 || value.indexOf("https://") === 0 || value === "about:blank"
}
