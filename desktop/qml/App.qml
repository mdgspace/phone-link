import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 1120
    height: 720
    minimumWidth: 900
    minimumHeight: 580
    visible: true
    color: "#0b0e12"
    title: "PhoneLink"

    property int currentPage: 0

    function statusText() {
        if (Backend.peerConnected)
            return "Connected to " + Backend.peerDeviceName
        if (Backend.serverRunning)
            return "Waiting for phone"
        return "Offline"
    }

    function statusColor() {
        if (Backend.peerConnected) return "#43d17a"
        if (Backend.serverRunning) return "#f2b84b"
        return "#8b95a1"
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
    }

    function selectPage(index) {
        root.currentPage = index
    }

    Rectangle {
        anchors.fill: parent
        color: "#0b0e12"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 225
                color: "#11151a"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 7

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
                            spacing: 1
                            Text {
                                text: "PhoneLink"
                                color: "#f2f4f7"
                                font.pixelSize: 17
                                font.bold: true
                            }
                            Text {
                                text: Backend.peerConnected ? "Connected" : "Desktop"
                                color: "#7f8995"
                                font.pixelSize: 11
                            }
                        }
                    }

                    Repeater {
                        model: [
                            {label: "Overview", icon: "⌂"},
                            {label: "Messages", icon: "✉"},
                            {label: "Notifications", icon: "●"},
                            {label: "Clipboard", icon: "▣"},
                            {label: "Files", icon: "□"},
                            {label: "Connection", icon: "◉"}
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 9
                            color: root.currentPage === index
                                   ? "#202b3b"
                                   : navMouse.containsMouse ? "#191f26" : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 13
                                anchors.rightMargin: 10
                                spacing: 11

                                Text {
                                    text: modelData.icon
                                    color: root.currentPage === index ? "#66a0ff" : "#8a95a1"
                                    font.pixelSize: 17
                                    Layout.preferredWidth: 22
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: root.currentPage === index ? "white" : "#aeb6c0"
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectPage(index)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        radius: 10
                        color: "#181d23"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 5

                            Text {
                                text: Backend.deviceName
                                color: "#e5e9ed"
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
                                    width: 155
                                }
                            }
                        }
                    }
                }
            }

            // Main area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#0b0e12"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 20

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 3

                            Text {
                                text: ["Overview", "Messages", "Notifications",
                                       "Clipboard", "Files", "Connection"][root.currentPage]
                                color: "#f1f3f5"
                                font.pixelSize: 25
                                font.bold: true
                            }

                            Text {
                                text: [
                                    "Your PhoneLink desktop at a glance.",
                                    "SMS messages received from your phone.",
                                    "Android notifications received from your phone.",
                                    "Clipboard items shared with your phone.",
                                    "Files received from your phone.",
                                    "Manage discovery, pairing and the TCP server."
                                ][root.currentPage]
                                color: "#7f8995"
                                font.pixelSize: 12
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 34
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

                        // 0 Overview
                        Flickable {
                            contentWidth: width
                            contentHeight: overview.implicitHeight
                            clip: true

                            ColumnLayout {
                                id: overview
                                width: parent.width
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Repeater {
                                        model: [
                                            {title: "Connection", value: Backend.peerConnected ? "Connected" : "Offline"},
                                            {title: "Messages", value: Backend.messageModel ? Backend.messageModel.count : 0},
                                            {title: "Notifications", value: Backend.notificationModel ? Backend.notificationModel.count : 0},
                                            {title: "Clipboard", value: Backend.clipboardModel ? Backend.clipboardModel.count : 0},
                                            {title: "Files", value: Backend.sharedFilesModel ? Backend.sharedFilesModel.count : 0}
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 92
                                            radius: 11
                                            color: "#12171d"
                                            border.color: "#202731"

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 14
                                                spacing: 8

                                                Text {
                                                    text: modelData.title
                                                    color: "#7f8995"
                                                    font.pixelSize: 11
                                                }

                                                Text {
                                                    text: modelData.value
                                                    color: "#edf0f3"
                                                    font.pixelSize: 20
                                                    font.bold: true
                                                }
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
                                            text: "Phone connection"
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
                                                  ? "Data can now be exchanged with " + Backend.peerDeviceName + "."
                                                  : "Start the TCP server and advertise this desktop to accept a phone connection."
                                            color: "#89939f"
                                            font.pixelSize: 12
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        RowLayout {
                                            spacing: 10

                                            Button {
                                                text: Backend.serverRunning ? "Stop TCP server" : "Start TCP server"
                                                onClicked: Backend.serverRunning
                                                           ? Backend.stopTcpServer()
                                                           : Backend.startTcpServer()
                                            }

                                            Button {
                                                text: Backend.registering ? "Stop advertising" : "Advertise device"
                                                onClicked: Backend.registering
                                                           ? Backend.stopRegistration()
                                                           : Backend.registerOnMdns()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 130
                                    radius: 12
                                    color: "#12171d"
                                    border.color: "#202731"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 7

                                        Text {
                                            text: "Device"
                                            color: "#e8ebef"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        Text {
                                            text: Backend.deviceName
                                            color: "#c5cbd2"
                                            font.pixelSize: 13
                                        }
                                        Text {
                                            text: "_phonelink._tcp  •  TCP 4040"
                                            color: "#7f8995"
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            visible: Backend.errorMessage.length > 0
                                            text: Backend.errorMessage
                                            color: "#ff7373"
                                            font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }

                        // 1 Messages
                        Item {
                            ListView {
                                anchors.fill: parent
                                clip: true
                                spacing: 8
                                model: Backend.messageModel

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: messageCol.implicitHeight + 28
                                    radius: 10
                                    color: "#12171d"
                                    border.color: "#202731"

                                    ColumnLayout {
                                        id: messageCol
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
                                                text: model.isIncoming ? "Received" : "Sent"
                                                color: model.isIncoming ? "#43d17a" : "#66a0ff"
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

                                        RowLayout {
                                            Layout.fillWidth: true
                                            TextField {
                                                id: replyField
                                                Layout.fillWidth: true
                                                placeholderText: "Reply by SMS..."
                                            }
                                            Button {
                                                text: "Send"
                                                enabled: Backend.peerConnected && replyField.text.length > 0
                                                onClicked: {
                                                    Backend.replyToSms(model.address, replyField.text)
                                                    replyField.clear()
                                                }
                                            }
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    visible: Backend.messageModel.count === 0
                                    text: "No messages received yet"
                                    color: "#65707d"
                                }
                            }
                        }

                        // 2 Notifications
                        Item {
                            ListView {
                                anchors.fill: parent
                                clip: true
                                spacing: 8
                                model: Backend.notificationModel

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: notificationCol.implicitHeight + 28
                                    radius: 10
                                    color: "#12171d"
                                    border.color: "#202731"

                                    ColumnLayout {
                                        id: notificationCol
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 5

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: model.appName || model.appPackage
                                                color: "#e6e9ed"
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            Item { Layout.fillWidth: true }

                                            Text {
                                                text: "Notification"
                                                color: "#66a0ff"
                                                font.pixelSize: 10
                                            }
                                        }

                                        Text {
                                            text: model.title
                                            visible: text.length > 0
                                            color: "#f0f2f4"
                                            font.pixelSize: 13
                                            font.bold: true
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: model.text
                                            color: "#aeb6c0"
                                            font.pixelSize: 12
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Button {
                                            text: "Dismiss on phone"
                                            Layout.alignment: Qt.AlignRight
                                            enabled: Backend.peerConnected
                                            onClicked: Backend.dismissPhoneNotification(model.notificationId)
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    visible: Backend.notificationModel.count === 0
                                    text: "No notifications received yet"
                                    color: "#65707d"
                                }
                            }
                        }

                        // 3 Clipboard
                        Item {
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true

                                    TextField {
                                        id: phoneClipboardField
                                        Layout.fillWidth: true
                                        placeholderText: "Text to put on phone clipboard..."
                                    }

                                    Button {
                                        text: "Send to phone"
                                        enabled: Backend.peerConnected && phoneClipboardField.text.length > 0
                                        onClicked: {
                                            Backend.setPhoneClipboard(phoneClipboardField.text)
                                            phoneClipboardField.clear()
                                        }
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
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
                                        anchors.fill: parent
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
                                    text: "No clipboard items received yet"
                                    color: "#65707d"
                                }
                            }
                            }
                        }

                        // 4 Files
                        Item {
                            ListView {
                                anchors.fill: parent
                                clip: true
                                spacing: 8
                                model: Backend.sharedFilesModel

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 70
                                    radius: 10
                                    color: mouse.containsMouse ? "#1a222c" : "#12171d"
                                    border.color: mouse.containsMouse ? "#3a4655" : "#202731"

                                    MouseArea {
                                        id: mouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Backend.sharedFilesModel.openFile(index)
                                    }

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
                                            Text {
                                                text: model.fileName
                                                color: "#e5e8ec"
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: root.formatBytes(model.totalBytes) + "  •  Click to open"
                                                color: "#7f8995"
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    visible: Backend.sharedFilesModel.count === 0
                                    text: "No shared files received yet"
                                    color: "#65707d"
                                }
                            }
                        }

                        // 5 Connection
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
                                    Layout.preferredHeight: 155
                                    radius: 12
                                    color: "#12171d"
                                    border.color: "#202731"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 10

                                        Text {
                                            text: "Connection"
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
                                    Layout.preferredHeight: 190
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

                                        Button {
                                            text: Backend.serverRunning ? "Stop server" : "Start server"
                                            onClicked: Backend.serverRunning
                                                       ? Backend.stopTcpServer()
                                                       : Backend.startTcpServer()
                                        }

                                        Text {
                                            text: Backend.serverRunning
                                                  ? "Listening for PhoneLink connections on TCP 4040."
                                                  : "Server is stopped."
                                            color: "#89939f"
                                            font.pixelSize: 12
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
                                            text: "mDNS advertising"
                                            color: "#e8ebef"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Button {
                                            text: Backend.registering ? "Stop advertising" : "Advertise device"
                                            onClicked: Backend.registering
                                                       ? Backend.stopRegistration()
                                                       : Backend.registerOnMdns()
                                        }

                                        Text {
                                            text: Backend.registering
                                                  ? "Advertising _phonelink._tcp."
                                                  : "Not advertising."
                                            color: Backend.registering ? "#43d17a" : "#89939f"
                                            font.pixelSize: 12
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
    }

    // Pairing dialog remains part of the existing backend contract.
    Popup {
        id: pairingPopup
        anchors.centerIn: Overlay.overlay
        width: 430
        padding: 24
        modal: true
        closePolicy: Popup.NoAutoClose
        visible: Backend.pairingPending

        background: Rectangle {
            color: "#171c22"
            radius: 14
            border.color: "#2b3440"
        }

        ColumnLayout {
            width: parent.width
            spacing: 12

            Text {
                text: "Pairing request"
                color: "#f1f3f5"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: Backend.pairingDeviceName + " wants to pair with this computer."
                color: "#aeb6c0"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: "PIN: " + Backend.pairingPin
                color: "#66a0ff"
                font.pixelSize: 30
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: "Confirm that this PIN matches the one shown on your phone."
                color: "#7f8995"
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
