import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {

    title: "Shared Content"

    TabBar {
        id: tabBar
        width: parent.width

        TabButton {
            text: "Clipboard"
        }

        TabButton {
            text: "Messages"
        }

        TabButton {
            text: "Files"
        }
    }

    StackLayout {
        anchors {
            top: tabBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        currentIndex: tabBar.currentIndex

        ClipboardItemsPage {}

        UnreadMessagesPage {}

        SharedFilesPage {}
    }
}