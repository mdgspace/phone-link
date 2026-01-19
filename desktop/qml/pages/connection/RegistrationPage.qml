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

        // TITLE
        Text {
            text: Backend.registering
                  ? "Device Registered"
                  : "Register your device"
            color: "white"
            Layout.fillWidth: true
        }

        // REGISTERED STATE
        ColumnLayout {
            visible: Backend.registering
            spacing: 6

            Text {
                text: "Device Name: " + Backend.deviceName
                color: "#cccccc"
            }

            Text {
                text: "Service: " + "_phonelink._tcp"
                color: "#888888"
            }

            Button {
                text: "Stop Registration"
                onClicked: Backend.stopRegistration()
            }
        }

        // NOT REGISTERED STATE
        ColumnLayout {
            visible: !Backend.registering
            spacing: 6

            Button {
                text: "Connect"
                Layout.fillWidth: true
                onClicked: Backend.registerOnMdns()
            }

            Text {
                text: "Waiting for device..."
                color: "#aaaaaa"
            }
        }
    }
}
