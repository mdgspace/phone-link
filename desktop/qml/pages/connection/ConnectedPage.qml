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
            text: "Connection Status"
            color: "white"
            Layout.fillWidth: true
        }

        Text {
            text: "Not connected"
            color: "white"
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Button {
        //     text: "Permissions"
        //     Layout.fillWidth: true
        // }

        Text {
            text: "Encrypted TLS Connection"
            color: "#aaaaaa"
            Layout.fillWidth: true
        }
    }
}
