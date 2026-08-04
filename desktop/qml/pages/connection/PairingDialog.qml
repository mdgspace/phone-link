import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Dialog {
    id: pairingDialog

    title: "Pairing Request"
    modal: true
    closePolicy: Popup.NoAutoClose

    anchors.centerIn: parent

    visible: Backend.pairingPending

    ColumnLayout {
        spacing: 10

        Text {
            text: "\"" + Backend.pairingDeviceName + "\" wants to pair with this computer."
            color: "white"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Text {
            text: "PIN: " + Backend.pairingPin
            color: "white"
            font.pointSize: 20
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        Text {
            text: "Confirm this PIN matches what's shown on your phone."
            color: "#aaaaaa"
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
