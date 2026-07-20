import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Messages"

    ListView {
        anchors.fill: parent
        spacing: 8
        clip: true

        model: backend.messageModel

        delegate: Frame {
            width: ListView.view.width

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12

                Label {
                    text: model.sender
                    font.bold: true
                }

                Label {
                    text: model.body
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}