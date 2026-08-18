import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.phonelink

Rectangle {
    id: sidebar
    color: Colors.sidebarBg
    border.color: Colors.border
    border.width: 1

    property int currentPage: 0
    signal pageSelected(int page)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 10
                color: Colors.accent

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
                Layout.fillWidth: true

                Label {
                    text: "PhoneLink"
                    color: Colors.textPrimary
                    font.pixelSize: 17
                    font.bold: true
                }
                Label {
                    text: "Desktop"
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }
        }

        Label {
            text: "WORKSPACE"
            color: Colors.textMuted
            font.pixelSize: 10
            font.bold: true
            Layout.leftMargin: 10
            Layout.bottomMargin: 3
        }

        NavButton { text: "Overview"; iconText: "⌂"; selected: sidebar.currentPage === 0; onClicked: sidebar.pageSelected(0) }
        NavButton { text: "Messages"; iconText: "M"; selected: sidebar.currentPage === 1; onClicked: sidebar.pageSelected(1) }
        NavButton { text: "Clipboard"; iconText: "C"; selected: sidebar.currentPage === 2; onClicked: sidebar.pageSelected(2) }
        NavButton { text: "Files"; iconText: "F"; selected: sidebar.currentPage === 3; onClicked: sidebar.pageSelected(3) }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.border
        }

        NavButton { text: "Connection"; iconText: "↔"; selected: sidebar.currentPage === 4; onClicked: sidebar.pageSelected(4) }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 10
            color: Colors.panelBg
            border.color: Colors.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 9
                    Layout.preferredHeight: 9
                    radius: 5
                    color: Backend.peerConnected ? Colors.success : Colors.textMuted
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Label {
                        text: Backend.peerConnected ? "Connected" : "Offline"
                        color: Colors.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Label {
                        text: Backend.peerConnected ? Backend.peerDeviceName : "No phone connected"
                        color: Colors.textMuted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    component NavButton: Button {
        id: button
        property string iconText: ""
        property bool selected: false

        Layout.fillWidth: true
        implicitHeight: 42
        leftPadding: 12
        rightPadding: 12

        background: Rectangle {
            radius: 9
            color: button.selected ? Colors.selected : (button.hovered ? Colors.hover : "transparent")
            border.color: button.selected ? Colors.borderLight : "transparent"
        }

        contentItem: RowLayout {
            spacing: 11
            Text {
                text: button.iconText
                color: button.selected ? Colors.accent : Colors.textSecondary
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 18
            }
            Text {
                text: button.text
                color: button.selected ? Colors.textPrimary : Colors.textSecondary
                font.pixelSize: 13
                font.bold: button.selected
                Layout.fillWidth: true
            }
        }
    }
}
