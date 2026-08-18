import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.phonelink

Rectangle {
    color: Colors.windowBg
    property int currentPage: 0

    StackLayout {
        anchors.fill: parent
        currentIndex: parent.currentPage

        OverviewPage {}
        MessagesPage {}
        ClipboardPage {}
        FilesPage {}
        ConnectionPage {}
    }
}

component OverviewPage: Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 22

        PageHeader {
            title: "Overview"
            subtitle: "Manage your phone connection and shared data."
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            StatusCard {
                title: "Connection"
                value: Backend.peerConnected ? "Connected" : "Not connected"
                detail: Backend.peerConnected ? Backend.peerDeviceName : "Waiting for a phone"
                accent: Backend.peerConnected ? Colors.success : Colors.textMuted
                iconText: "↔"
            }
            StatusCard {
                title: "TCP server"
                value: Backend.serverRunning ? "Running" : "Stopped"
                detail: Backend.serverRunning ? "Listening on port 4040" : "Start the server to accept phones"
                accent: Backend.serverRunning ? Colors.success : Colors.warning
                iconText: "S"
            }
            StatusCard {
                title: "Discovery"
                value: Backend.registering ? "Advertised" : "Not advertised"
                detail: Backend.registering ? "_phonelink._tcp" : "Make this computer discoverable"
                accent: Backend.registering ? Colors.accent : Colors.textMuted
                iconText: "D"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Panel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Connection"
                subtitle: "Your PhoneLink desktop endpoint"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Label {
                        text: Backend.peerConnected ? "Connected to " + Backend.peerDeviceName : "No phone connected"
                        color: Colors.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Label {
                        text: Backend.peerConnected
                              ? "The phone can now sync messages, clipboard and files."
                              : "Start the TCP server and advertise this device, then connect from your phone."
                        color: Colors.textSecondary
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 10
                        Button {
                            text: Backend.serverRunning ? "Stop server" : "Start server"
                            onClicked: Backend.serverRunning ? Backend.stopTcpServer() : Backend.startTcpServer()
                            Layout.preferredWidth: 130
                        }
                        Button {
                            text: Backend.registering ? "Stop discovery" : "Advertise device"
                            onClicked: Backend.registering ? Backend.stopRegistration() : Backend.registerOnMdns()
                            Layout.preferredWidth: 140
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Label {
                        visible: Backend.errorMessage.length > 0
                        text: Backend.errorMessage
                        color: Colors.error
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Panel {
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                title: "Device"
                subtitle: "This computer"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Label { text: Backend.deviceName; color: Colors.textPrimary; font.pixelSize: 17; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                    Label { text: "Service"; color: Colors.textMuted; font.pixelSize: 11 }
                    Label { text: "_phonelink._tcp"; color: Colors.textSecondary; font.pixelSize: 13 }
                    Label { text: "Port"; color: Colors.textMuted; font.pixelSize: 11 }
                    Label { text: "4040"; color: Colors.textSecondary; font.pixelSize: 13 }
                    Item { Layout.fillHeight: true }
                    Label {
                        text: "PhoneLink protocol v1"
                        color: Colors.textMuted
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}

component MessagesPage: Item {
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 30; spacing: 22
        PageHeader { title: "Messages"; subtitle: "Messages received from your phone." }
        Panel {
            Layout.fillWidth: true; Layout.fillHeight: true
            title: "Recent messages"; subtitle: Backend.messageModel.count + " messages"
            ListView {
                anchors.fill: parent; anchors.margins: 18; spacing: 8; clip: true
                model: Backend.messageModel
                delegate: MessageRow { }
                ScrollBar.vertical: ScrollBar { }
            }
        }
    }
}

component ClipboardPage: Item {
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 30; spacing: 22
        PageHeader { title: "Clipboard"; subtitle: "Text copied on your phone appears here." }
        Panel {
            Layout.fillWidth: true; Layout.fillHeight: true
            title: "Clipboard history"; subtitle: Backend.clipboardModel.count + " items"
            ListView {
                anchors.fill: parent; anchors.margins: 18; spacing: 8; clip: true
                model: Backend.clipboardModel
                delegate: ClipboardRow { }
                ScrollBar.vertical: ScrollBar { }
            }
        }
    }
}

component FilesPage: Item {
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 30; spacing: 22
        PageHeader { title: "Files"; subtitle: "Files received from your phone." }
        Panel {
            Layout.fillWidth: true; Layout.fillHeight: true
            title: "Shared files"; subtitle: Backend.sharedFilesModel.count + " files"
            ListView {
                anchors.fill: parent; anchors.margins: 18; spacing: 8; clip: true
                model: Backend.sharedFilesModel
                delegate: FileRow { }
                ScrollBar.vertical: ScrollBar { }
            }
        }
    }
}

component ConnectionPage: Item {
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 30; spacing: 22
        PageHeader { title: "Connection"; subtitle: "Control discovery, the TCP server and pairing." }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Panel {
                Layout.fillWidth: true; title: "Discovery"
                ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 12
                    Label { text: Backend.registering ? "Device is discoverable" : "Device is not discoverable"; color: Colors.textPrimary; font.pixelSize: 16; font.bold: true }
                    Label { text: Backend.registering ? "Advertising _phonelink._tcp" : "Advertise this computer so your phone can find it."; color: Colors.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Button { text: Backend.registering ? "Stop advertising" : "Start advertising"; onClicked: Backend.registering ? Backend.stopRegistration() : Backend.registerOnMdns() }
                }
            }
            Panel {
                Layout.fillWidth: true; title: "TCP server"
                ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 12
                    Label { text: Backend.serverRunning ? "Listening" : "Stopped"; color: Backend.serverRunning ? Colors.success : Colors.warning; font.pixelSize: 16; font.bold: true }
                    Label { text: "PhoneLink uses TCP port 4040 for the connection."; color: Colors.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Button { text: Backend.serverRunning ? "Stop server" : "Start server"; onClicked: Backend.serverRunning ? Backend.stopTcpServer() : Backend.startTcpServer() }
                }
            }
        }

        Panel {
            Layout.fillWidth: true; Layout.fillHeight: true; title: "Current connection"
            ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 12
                Label { text: Backend.peerConnected ? "Connected to " + Backend.peerDeviceName : "No active phone connection"; color: Colors.textPrimary; font.pixelSize: 20; font.bold: true }
                Label { text: Backend.peerConnected ? "Pairing is complete and the phone is connected." : "When a new phone connects, the pairing dialog will appear automatically."; color: Colors.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                Label { visible: Backend.errorMessage.length > 0; text: Backend.errorMessage; color: Colors.error; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
        }
    }
}

component PageHeader: RowLayout {
    property string title: ""
    property string subtitle: ""
    Layout.fillWidth: true
    Layout.preferredHeight: 54
    ColumnLayout { spacing: 3; Layout.fillWidth: true
        Label { text: title; color: Colors.textPrimary; font.pixelSize: 28; font.bold: true }
        Label { text: subtitle; color: Colors.textMuted; font.pixelSize: 12 }
    }
}

component StatusCard: Rectangle {
    property string title: ""
    property string value: ""
    property string detail: ""
    property color accent: Colors.accent
    property string iconText: ""
    Layout.fillWidth: true
    implicitHeight: 112
    radius: 12
    color: Colors.panelBg
    border.color: Colors.border
    RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 13
        Rectangle { Layout.preferredWidth: 38; Layout.preferredHeight: 38; radius: 10; color: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
            Text { anchors.centerIn: parent; text: iconText; color: accent; font.bold: true; font.pixelSize: 15 }
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 3
            Label { text: title; color: Colors.textMuted; font.pixelSize: 11 }
            Label { text: value; color: Colors.textPrimary; font.pixelSize: 16; font.bold: true }
            Label { text: detail; color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }
}

component Panel: Rectangle {
    property string title: ""
    property string subtitle: ""
    radius: 12
    color: Colors.panelBg
    border.color: Colors.border
    implicitHeight: 180

    Label { x: 18; y: 15; text: parent.title; color: Colors.textPrimary; font.pixelSize: 13; font.bold: true }
    Label { x: 18; y: 35; text: parent.subtitle; color: Colors.textMuted; font.pixelSize: 10 }
}

component MessageRow: Rectangle {
    width: ListView.view ? ListView.view.width - 2 : 400
    implicitHeight: 72
    radius: 9
    color: Colors.panelBgAlt
    border.color: Colors.border
    RowLayout { anchors.fill: parent; anchors.margins: 13; spacing: 12
        Rectangle { Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 18; color: Colors.accentSoft
            Label { anchors.centerIn: parent; text: "M"; color: Colors.accent; font.bold: true }
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 3
            Label { text: model.address; color: Colors.textPrimary; font.bold: true; font.pixelSize: 12 }
            Label { text: model.body; color: Colors.textSecondary; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }
}

component ClipboardRow: Rectangle {
    width: ListView.view ? ListView.view.width - 2 : 400
    implicitHeight: Math.max(62, body.implicitHeight + 26)
    radius: 9; color: Colors.panelBgAlt; border.color: Colors.border
    Label { id: body; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 13; text: model.text; color: Colors.textSecondary; font.pixelSize: 12; wrapMode: Text.Wrap }
}

component FileRow: Rectangle {
    width: ListView.view ? ListView.view.width - 2 : 400
    implicitHeight: 64
    radius: 9; color: Colors.panelBgAlt; border.color: Colors.border
    RowLayout { anchors.fill: parent; anchors.margins: 13; spacing: 12
        Rectangle { Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 9; color: Colors.accentSoft
            Label { anchors.centerIn: parent; text: "F"; color: Colors.accent; font.bold: true }
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 3
            Label { text: model.fileName; color: Colors.textPrimary; font.bold: true; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            Label { text: model.totalBytes + " bytes"; color: Colors.textMuted; font.pixelSize: 10 }
        }
    }
}
