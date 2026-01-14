pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    readonly property color connBg: "#0C0C0C" // connections background
    readonly property color mainBg: "#111111" // main content body background
    readonly property color navBg: "#1D1D1D" // navbar background
    readonly property color selected: "#2A2A2A" // settings / nav item selected
    readonly property color connWidgetBg: "#222222" // connectionPage widgets bg

    // Texts
    readonly property color textPrimary: "#DEE0E2"
    readonly property color textSecondary: "#CCCCCC" // light grayish?
    // one more text color?

    // Status
    // readonly property color success: ""
    // readonly property color warning: ""
    // readonly property color error: ""
}
