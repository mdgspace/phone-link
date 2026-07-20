import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Clipboard"

    ListView {
        anchors.fill: parent
        spacing: 8
        clip: true

        model: backend.clipboardModel

        delegate: Frame {
            width: ListView.view.width

            Label {
                anchors.fill: parent
                anchors.margins: 12
                text: model.text
                wrapMode: Text.Wrap
            }
        }
    }
}