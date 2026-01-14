import QtQuick
import QtQuick.Layouts
import com.phonelink

Rectangle {
    color: "black"
    anchors.fill: parent

    Rectangle {
        id: connectionPage

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: sharedPage.left
        anchors.margins: 10
        width: 350

        color: "#080808"

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RegistrationPage {
                Layout.fillWidth: true
                Layout.minimumHeight: implicitHeight
            }

            ConnectedPage {
                Layout.fillWidth: true
                Layout.minimumHeight: implicitHeight
            }

            DiscoveryPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: implicitHeight
            }

            // RegistrationPage {
            //     id: registrationPage

            //     anchors.top: parent.top
            //     anchors.left: parent.left
            //     anchors.right: parent.right

            //     anchors.bottomMargin: 10

            //     height: 200
            // }

            // ConnectedPage {
            //     id: connectedPage

            //     anchors.top: registrationPage.bottom
            //     anchors.left: parent.left
            //     anchors.right: parent.right

            //     anchors.topMargin: 10
            //     height: 200
            // }

            // DiscoveryPage {
            //     id: discoveryPage

            //     anchors.top: connectedPage.bottom
            //     anchors.left: parent.left
            //     anchors.right: parent.right

            //     anchors.topMargin: 10
            //     anchors.bottom: parent.bottom
            // }
        }
    }

    // }

    // SharedPage
    Rectangle {
        id: sharedPage

        anchors.left: connectionPage.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        color: "#111111"

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            columns: 5
            rows: 2

            columnSpacing: 16
            rowSpacing: 16

            // LEFT — spans full height
            UnreadMessagesPage {
                Layout.column: 0
                Layout.row: 0
                Layout.rowSpan: 2
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // TOP RIGHT
            ClipboardItemsPage {
                Layout.column: 2
                Layout.row: 0
                Layout.columnSpan: 3
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // BOTTOM RIGHT
            SharedFilesPage {
                Layout.column: 2
                Layout.row: 1
                Layout.columnSpan: 3
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
