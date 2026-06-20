pragma Singleton

import QtQuick
import Quickshell

// Static palette with sane defaults (Catppuccin Mocha-ish). Every widget reads
// colors from here so a future matugen template can rewrite this one file
// without touching any widget. See matugen/Theme.qml.tmpl (Phase 2 hook).
Singleton {
    // surfaces
    readonly property color background: "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color surfaceAlt: "#45475a"
    readonly property color scrim: "#cc11111b"

    // text
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"

    // accents
    readonly property color primary: "#89b4fa"
    readonly property color accent: "#f5c2e7"
    readonly property color success: "#a6e3a1"
    readonly property color warning: "#f9e2af"
    readonly property color danger: "#f38ba8"
    readonly property color outline: "#585b70"

    // metrics
    readonly property int radius: 14
    readonly property int pad: 12
    readonly property int gap: 8
    readonly property string fontFamily: "sans-serif"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
