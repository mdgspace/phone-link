import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.phonelink

Rectangle {
    anchors.fill: parent
    color: "#0B0B0B"

    property string lastType: "message"

    Connections {
        target: backend.messageModel
        function onRowsInserted() { lastType = "message" }
    }

    Connections {
        target: backend.clipboardModel
        function onRowsInserted() { lastType = "clipboard" }
    }

    Connections {
        target: backend.sharedFilesModel
        function onRowsInserted() { lastType = "file" }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 290
            Layout.fillHeight: true
            radius: 12
            color: "#111111"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RegistrationPage {
                    Layout.fillWidth: true
                }

                ConnectedPage {
                    Layout.fillWidth: true
                }

                ServerControlPage {
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 190
                radius: 16
                color: "#171717"

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Text {
                        text: "Recent Activity"
                        color: "white"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Loader {
                        width: parent.width
                        sourceComponent:
                            lastType === "message" ? messageCard :
                            lastType === "clipboard" ? clipboardCard :
                            fileCard
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#141414"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Messages"
                            color: "white"
                            font.bold: true
                        }

                        UnreadMessagesPage {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height - 30
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#141414"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Clipboard"
                            color: "white"
                            font.bold: true
                        }

                        ClipboardItemsPage {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height - 30
                        }
                    }
                }

                Rectangle {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#141414"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Files"
                            color: "white"
                            font.bold: true
                        }

                        SharedFilesPage {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height - 30
                        }
                    }
                }
            }
        }
    }

    Component {
        id: messageCard

        ListView {
            width: parent.width
            height: 95
            interactive: false
            model: backend.messageModel

            delegate: Item {
                width: ListView.view.width
                height: 90
                visible: index === 0

                Column {
                    spacing: 4

                    Rectangle {
                        radius: 6
                        color: "#2563EB"
                        width: 82
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            text: "MESSAGE"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: sender
                        color: "white"
                        font.bold: true
                        font.pixelSize: 18
                    }

                    Text {
                        text: body
                        color: "#CFCFCF"
                        elide: Text.ElideRight
                        width: 500
                    }
                }
            }
        }
    }

    Component {
        id: clipboardCard

        ListView {
            width: parent.width
            height: 95
            interactive: false
            model: backend.clipboardModel

            delegate: Item {
                width: ListView.view.width
                height: 90
                visible: index === 0

                Column {
                    spacing: 4

                    Rectangle {
                        radius: 6
                        color: "#16A34A"
                        width: 96
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            text: "CLIPBOARD"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: "Copied Text"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 18
                    }

                    Text {
                        text: model.text
                        color: "#CFCFCF"
                        elide: Text.ElideRight
                        width: 500
                    }
                }
            }
        }
    }

    Component {
        id: fileCard

        ListView {
            width: parent.width
            height: 95
            interactive: false
            model: backend.sharedFilesModel

            delegate: Item {
                width: ListView.view.width
                height: 90
                visible: index === 0

                Column {
                    spacing: 4

                    Rectangle {
                        radius: 6
                        color: "#EA580C"
                        width: 58
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            text: "FILE"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: fileName
                        color: "white"
                        font.bold: true
                        font.pixelSize: 18
                        elide: Text.ElideRight
                        width: 500
                    }

                    Text {
                        text: fileSize
                        color: "#CFCFCF"
                    }
                }
            }
        }
    }
}