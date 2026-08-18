import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.phonelink

ApplicationWindow {
    id: root
    width: 1180
    height: 760
    minimumWidth: 980
    minimumHeight: 620
    visible: true
    title: "PhoneLink Desktop"
    color: Colors.windowBg

    property int currentPage: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        NavigationBar {
            Layout.fillHeight: true
            Layout.preferredWidth: 235
            currentPage: root.currentPage
            onPageSelected: function(page) { root.currentPage = page }
        }

        MainContent {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentPage: root.currentPage
        }
    }

    PairingDialog {
        parent: Overlay.overlay
    }
}
