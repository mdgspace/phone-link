import QtQuick
import QtQuick.Layouts
import com.phonelink

Window {
    width: 640
    height: 480
    visible: true
    title: "PhoneLink"

    Rectangle {
        anchors.fill: parent

        Item {
            anchors.fill: parent

            NavigationBar {
                id: navigationBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: mainContent.top
            }

            MainContent {
                id: mainContent
                anchors.top: navigationBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }
    }
}
