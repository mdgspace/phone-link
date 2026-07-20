import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Files"

    ListView {
        anchors.fill: parent
        spacing: 8
        clip: true

        model: backend.sharedFilesModel

        delegate: Frame {
            width: ListView.view.width

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12

                Label {
                    text: model.fileName
                    font.bold: true
                }

                Label {
                    text: model.fileSize
                }
            }
        }
    }
}