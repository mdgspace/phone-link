import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root

    width: 1100
    height: 700
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "PhoneLink"

    color: "#0b0d10"

    property int currentPage: 0

    function formatBytes(bytes) {
        if (bytes < 1024)
            return bytes + " B"
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
    }

    function statusText() {
        if (Backend.peerConnected)
            return "Connected to " + Backend.peerDeviceName
        if (Backend.serverRunning)
            return "Waiting for phone"
        return "Offline"
    }

    function statusColor() {
        if (Backend.peerConnected)
            return "#43d17a"
        if (Backend.serverRunning)
            return "#f2b84b"
        return "#88919d"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // -----------------------------------------------------------------
        // SIDEBAR
        // -----------------------------------------------------------------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: "#12161b"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 18
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 10
                        color: "#3478f6"

                        Text {
                            anchors.centerIn: parent
                            text: "P"
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        spacing: 0

                        Text {
                            text: "PhoneLink"
                            color: "#f3f5f7"
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Text {
                            text: Backend.peerConnected ? "Connected" : "Desktop"
                            color: "#8c96a3"
                            font.pixelSize: 11
                        }
                    }
                }

                Repeater {
                    model: [
                        { "label": "Overview", "icon": "⌂" },
                        { "label": "Messages", "icon": "✉" },
                        { "label": "Clipboard", "icon": "▣" },
                        { "label": "Files", "icon": "□" },
                        { "label": "Connection", "icon": "◉" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 9
                        color: root.currentPage === index
                               ? "#202a38"
                               : (navMouse.containsMouse ? "#191f27" : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 12

                            Text {
                                text: modelData.icon
                                color: root.currentPage === index
                                       ? "#66a0ff"
                                       : "#8b96a3"
                                font.pixelSize: 18
                                Layout.preferredWidth: 22
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                text: modelData.label
                                color: root.currentPage === index
                                       ? "#ffffff"
                                       : "#aeb6c0"
                                font.pixelSize: 13
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = index
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    radius: 10
                    color: "#181d23"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5

                        Text {
                            text: Backend.deviceName
                            color: "#e6e9ed"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Row {
                            spacing: 7

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: root.statusColor()
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.statusText()
                                color: "#929ca8"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: 145
                            }
                        }
                    }
                }
            }
        }

        // -----------------------------------------------------------------
        // MAIN AREA
        // -----------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0b0d10"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 22

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 3

                        Text {
                            text: [
                                "Overview",
                                "Messages",
                                "Clipboard",
                                "Files",
                                "Connection"
                            ][root.currentPage]
                            color: "#f1f3f5"
                            font.pixelSize: 25
                            font.bold: true
                        }

                        Text {
                            text: [
                                "Your PhoneLink desktop at a glance.",
                                "Messages received from your phone.",
                                "Clipboard items shared with your phone.",
                                "Files received from your phone.",
                                "Manage discovery, pairing and the TCP server."
                            ][root.currentPage]
                            color: "#7f8995"
                            font.pixelSize: 12
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 150
                        radius: 17
                        color: "#171c22"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: root.statusColor()
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.statusText()
                                color: "#c7cdd4"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                StackLayout {
                    id: pages
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentPage

                    // =====================================================
                    // OVERVIEW
                    // =====================================================
                    Flickable {
                        contentWidth: width
                        contentHeight: overviewColumn.implicitHeight
                        clip: true

                        ColumnLayout {
                            id: overviewColumn
                            width: parent.width
                            spacing: 16

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                Repeater {
                                    model: [
                                        { "title": "Connection", "value": Backend.peerConnected ? "Connected" : "Offline", "color": Backend.peerConnected ? "#43d17a" : "#88919d" },
                                        { "title": "Messages", "value": Backend.messageModel ? Backend.messageModel.count : "—", "color": "#66a0ff" },
                                        { "title": "Clipboard", "value": Backend.clipboardModel ? Backend.clipboardModel.count : "—", "color": "#b58cff" },
                                        { "title": "Files", "value": Backend.sharedFilesModel ? Backend.sharedFilesModel.count : "—", "color": "#f2b84b" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 110
                                        radius: 12
                                        color: "#12171d"
                                        border.color: "#202731"

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 9

                                            Text {
                                                text: modelData.title
                                                color: "#7f8995"
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                text: modelData.value
                                                color: modelData.color
                                                font.pixelSize: 22
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 190
                                radius: 12
                                color: "#12171d"
                                border.color: "#202731"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 12

                                    Text {
                                        text: "Phone connection"
                                        color: "#e8ebef"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: Backend.peerConnected
                                              ? "Your phone is connected and ready to exchange data."
                                              : Backend.serverRunning
                                                ? "TCP server is running. Waiting for your phone."
                                                : "Start the TCP server and mDNS registration to connect."
                                        color: "#89939f"
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: 10

                                        Button {
                                            text: Backend.serverRunning ? "Stop TCP server" : "Start TCP server"
                                            onClicked: {
                                                if (Backend.serverRunning)
                                                    Backend.stopTcpServer()
                                                else
                                                    Backend.startTcpServer()
                                            }
                                        }

                                        Button {
                                            text: Backend.registering ? "Stop discovery" : "Advertise device"
                                            onClicked: {
                                                if (Backend.registering)
                                                    Backend.stopRegistration()
                                                else
                                                    Backend.registerOnMdns()
                                            }
                                        }
                                    }

                                    Text {
                                        visible: Backend.errorMessage.length > 0
                                        text: Backend.errorMessage
                                        color: "#ff7373"
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150
                                radius: 12
                                color: "#12171d"
                                border.color: "#202731"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 9

                                    Text {
                                        text: "Device"
                                        color: "#e8ebef"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: "Name: " + Backend.deviceName
                                        color: "#9da6b0"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: "Service: _phonelink._tcp"
                                        color: "#9da6b0"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: Backend.registering
                                              ? "mDNS advertising is active."
                                              : "mDNS advertising is stopped."
                                        color: Backend.registering ? "#43d17a" : "#88919d"
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }

                    // =====================================================
                    // MESSAGES
                    // =====================================================
                    Rectangle {
                        color: "transparent"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            Text {
                                text: "SMS / messages"
                                color: "#89939f"
                                font.pixelSize: 12
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 8
                                model: Backend.messageModel

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: messageColumn.implicitHeight + 28
                                    radius: 10
                                    color: "#12171d"
                                    border.color: "#202731"

                                    ColumnLayout {
                                        id: messageColumn
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 5

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: model.address
                                                color: "#e6e9ed"
                                                font.pixelSize: 13
                                                font.bold: true
                                            }

                                            Item { Layout.fillWidth: true }

                                            Text {
                                                text: model.incoming ? "Received" : "Sent"
                                                color: model.incoming ? "#43d17a" : "#66a0ff"
                                                font.pixelSize: 10
                                            }
                                        }

                                        Text {
                                            text: model.body
                                            color: "#aeb6c0"
                                            font.pixelSize: 12
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    visible: Backend.messageModel.count === 0
                                    text: "No messages yet"
                                    color: "#65707d"
                                }
                            }
                        }
                    }

                    // =====================================================
                    // CLIPBOARD
                    // =====================================================
                    Rectangle {
                        color: "transparent"

                        ListView {
                            anchors.fill: parent
                            clip: true
                            spacing: 8
                            model: Backend.clipboardModel

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: clipboardText.implicitHeight + 28
                                radius: 10
                                color: "#12171d"
                                border.color: "#202731"

                                Text {
                                    id: clipboardText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 14
                                    text: model.text
                                    color: "#c5cbd2"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: Backend.clipboardModel.count === 0
                                text: "No clipboard items yet"
                                color: "#65707d"
                            }
                        }
                    }

                    // =====================================================
                    // FILES
                    // =====================================================
                    Rectangle {
                        color: "transparent"

                        ListView {
                            anchors.fill: parent
                            clip: true
                            spacing: 8
                            model: Backend.sharedFilesModel

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 70
                                radius: 10
                                color: "#12171d"
                                border.color: "#202731"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: 9
                                        color: "#242a32"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "↗"
                                            color: "#f2b84b"
                                            font.pixelSize: 20
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            text: model.fileName
                                            color: "#e5e8ec"
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: root.formatBytes(model.totalBytes)
                                            color: "#7f8995"
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: Backend.sharedFilesModel.count === 0
                                text: "No shared files yet"
                                color: "#65707d"
                            }
                        }
                    }

                    // =====================================================
                    // CONNECTION
                    // =====================================================
                    Flickable {
                        contentWidth: width
                        contentHeight: connectionColumn.implicitHeight
                        clip: true

                        ColumnLayout {
                            id: connectionColumn
                            width: parent.width
                            spacing: 14

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 145
                                radius: 12
                                color: "#12171d"
                                border.color: "#202731"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 10

                                    Text {
                                        text: "Connection status"
                                        color: "#e8ebef"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: root.statusText()
                                        color: root.statusColor()
                                        font.pixelSize: 20
                                        font.bold: true
                                    }

                                    Text {
                                        text: Backend.peerConnected
                                              ? "Peer: " + Backend.peerDeviceName
                                              : "No phone is currently connected."
                                        color: "#89939f"
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 180
                                radius: 12
                                color: "#12171d"
                                border.color: "#202731"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 12

                                    Text {
                                        text: "mDNS discovery"
                                        color: "#e8ebef"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: Backend.registering
                                              ? "Your desktop is advertising _phonelink._tcp."
                                              : "Your desktop is not currently advertising."
                                        color: "#89939f"
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Button {
                                        text: Backend.registering
                                              ? "Stop advertising"
                                              : "Start advertising"
                                        onClicked: {
                                            if (Backend.registering)
                                                Backend.stopRegistration()
                                            else
                                                Backend.registerOnMdns()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 180
                                radius: 12
                                color: "#12171d"
                                border.color: "#202731"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 12

                                    Text {
                                        text: "TCP server"
                                        color: "#e8ebef"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: Backend.serverRunning
                                              ? "Server is listening for PhoneLink connections."
                                              : "Server is stopped."
                                        color: Backend.serverRunning ? "#43d17a" : "#88919d"
                                        font.pixelSize: 12
                                    }

                                    Button {
                                        text: Backend.serverRunning
                                              ? "Stop server"
                                              : "Start server"
                                        onClicked: {
                                            if (Backend.serverRunning)
                                                Backend.stopTcpServer()
                                            else
                                                Backend.startTcpServer()
                                        }
                                    }

                                    Text {
                                        visible: Backend.errorMessage.length > 0
                                        text: Backend.errorMessage
                                        color: "#ff7373"
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Pairing dialog. Kept inline so the UI has no dependency on another
    // QML component being resolved by the build system.
    // ---------------------------------------------------------------------
    Dialog {
        id: pairingDialog

        modal: true
        title: "Pairing Request"
        width: 420
        anchors.centerIn: Overlay.overlay
        closePolicy: Popup.NoAutoClose
        visible: Backend.pairingPending

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: "\"" + Backend.pairingDeviceName +
                      "\" wants to pair with this computer."
                color: "#dfe4e9"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: Backend.pairingPin
                color: "#66a0ff"
                font.pixelSize: 30
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: "Confirm that this PIN matches the one shown on your phone."
                color: "#89939f"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Reject"
                    Layout.fillWidth: true
                    onClicked: Backend.rejectPairing()
                }

                Button {
                    text: "Accept"
                    Layout.fillWidth: true
                    onClicked: Backend.confirmPairing()
                }
            }
        }
    }
}
