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
            text: "TCP Server"
            color: "white"
            Layout.fillWidth: true
        }

        Text {
            text: Backend.serverRunning ? "Running" : "Stopped"
            color: Backend.serverRunning ? "#4CAF50" : "#ff6666"
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        Button {
            text: Backend.serverRunning ? "Stop Server" : "Start Server"
            Layout.fillWidth: true

            onClicked: {
                if (Backend.serverRunning)
                    Backend.stopTcpServer()
                else
                    Backend.startTcpServer()
            }
        }

        Text {
            text: "TCP Listening Service"
            color: "#aaaaaa"
            Layout.fillWidth: true
        }
    }
}
