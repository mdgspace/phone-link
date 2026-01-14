import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import com.phonelink


Item {
    implicitHeight: 50
    implicitWidth: 640

    Rectangle {
        anchors.fill: parent
        color: Colors.navBg

        Item {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            Text {
                id: appTitleText
                text: "PhoneLink"
                color: "white"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            RoundButton {
                radius: 8
                anchors.right: settingsButton.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
            }

            RoundButton {
                id: settingsButton
                radius: 8
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
