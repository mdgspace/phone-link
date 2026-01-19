import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    radius: 8
    color: "#222222"

    implicitWidth: content.implicitWidth + 20
    implicitHeight: content.implicitHeight + 20

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // TITLE
        Text {
            text: "Discover Devices"
            color: "white"
            font.pixelSize: 16
            Layout.fillWidth: true
        }

        // START DISCOVERY BUTTON
        Button {
            text: Backend.discovering ? "Discovering..." : "Start Discovery"
            enabled: !Backend.discovering
            Layout.fillWidth: true
            onClicked: Backend.startDiscovery()
        }

        Text {
            visible: Backend.discovering && Backend.discoveryList.count === 0
            text: "Looking for nearby devices..."
            color: "#aaaaaa"
        }

        // DEVICE LIST
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: Backend.discoveryList

            spacing: 6

            delegate: Rectangle {
                width: ListView.view.width
                height: 50
                radius: 6
                color: "#333333"

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        text: name
                        color: "white"
                        font.pixelSize: 14
                    }

                    Text {
                        text: address + " : " + port
                        color: "#aaaaaa"
                        font.pixelSize: 11
                    }
                }
            }

            // EMPTY STATE
            Text {
                anchors.centerIn: parent
                visible: Backend.discoveryList.count === 0
                text: "No devices found yet"
                color: "#777777"
            }
        }
    }
}
