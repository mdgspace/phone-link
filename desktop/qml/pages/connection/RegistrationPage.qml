import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    color: "#222222"
    radius: 8

    implicitWidth: content.implicitWidth + 20
    implicitHeight: content.implicitHeight + 20

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: "Register your device"
            color: "white"
            Layout.fillWidth: true
        }

        Button {
            text: "Connect"
            Layout.fillWidth: true
        }

        Text {
            text: "Waiting for device..."
            color: "#aaaaaa"
            Layout.fillWidth: true
        }
    }
}
