import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root
    pluginId: "imageConverter"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.fill: parent

        StyledText {
            anchors.centerIn: parent
            text: "🖼"
            font.pixelSize: Theme.fontSizeMedium
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.togglePopout()
            }
        }
    }
}
