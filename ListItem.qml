import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string iconName: ""
    property color iconColor: Theme.surfaceVariantText
    property string label: ""
    property color labelColor: Theme.surfaceText
    property bool selected: false
    property bool isFirst: false
    property bool isLast: false

    signal clicked

    height: 44
    readonly property real r: 10
    topLeftRadius:     isFirst ? r : 0
    topRightRadius:    isFirst ? r : 0
    bottomLeftRadius:  isLast  ? r : 0
    bottomRightRadius: isLast  ? r : 0

    color: root.selected
        ? Qt.alpha(Theme.primary, 0.18)
        : (mouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 12

        DankIcon {
            name: root.iconName
            size: Theme.fontSizeSmall
            color: root.selected ? Theme.primary : root.iconColor
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            font.pixelSize: Theme.fontSizeSmall
            font.weight: root.selected ? Font.Medium : Font.Normal
            color: root.selected ? Theme.primary : root.labelColor
            elide: Text.ElideRight
        }

        DankIcon {
            name: "check"
            size: Theme.fontSizeSmall
            color: Theme.primary
            visible: root.selected
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
