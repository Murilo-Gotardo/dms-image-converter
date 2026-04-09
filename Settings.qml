import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "imageConverter"

    StyledText {
        width: parent.width
        text: "Image Converter Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure default conversion settings"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "outputDir"
        label: "Output directory"
        description: "Where converted files are saved. Leave empty to use ~/Pictures/converted"
        placeholder: "~/Pictures/converted"
        defaultValue: ""
    }

    SelectionSetting {
        settingKey: "defaultFormat"
        label: "Default output format"
        description: "Format selected when the widget opens"
        options: ["jpg", "png", "webp", "bmp", "tiff"]
        defaultValue: "jpg"
    }

    SliderSetting {
        settingKey: "defaultQuality"
        label: "Default quality"
        description: "JPEG/WebP compression quality (10-100)"
        from: 10
        to: 100
        stepSize: 1
        defaultValue: 92
    }
}
