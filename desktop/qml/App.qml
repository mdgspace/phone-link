import QtQuick
import QtQuick.Layouts
import com.phonelink

Window {
    width: 640
    height: 480
    visible: true
    title: "PhoneLink"

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        NavigationBar {}

        MainContent {}
    }
}
