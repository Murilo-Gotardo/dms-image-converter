import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

// This is the small widget that appears in the DankBar (horizontal mode)
PluginComponent {
    id: root
    pluginId: "imageConverter"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.fill: parent

        RowLayout {
            anchors.centerIn: parent
            spacing: 4

            // Icon - using a material icon name
            StyledText {
                text: "🖼"
                font.pixelSize: Theme.fontSizeMedium
            }

            StyledText {
                text: "IMG"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
            }
        }

        // Click to toggle the popout panel
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.togglePopout()
            }
        }
    }
}
