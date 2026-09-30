import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root
    pluginId: "imageConverter"

    property var _popoutRef: null
    property string _dismissedPath: ""
    property string inputPath: ""
    property string outputFormat: "jpg"
    property string statusText: ""
    property int quality: 92
    property int density: 72
    property int heifQuality: -1
    property bool converting: false
    property bool checkingClipboard: false
    property bool success: false
    property bool hasError: false

    readonly property var formats: ["jpg", "png", "webp", "bmp", "tiff", "pdf", "heic", "heif"]
    readonly property var formatIcons: ({ "webp": "language" })
    readonly property var imageExts: [".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".tif", ".gif", ".pdf", ".heic", ".heif"]
    readonly property var imageMimes: ["image/png", "image/jpeg", "image/webp", "image/bmp", "image/gif", "image/tiff", "image/pdf", "image/heic", "image/heif"]
    readonly property string fileName: inputPath ? inputPath.split("/").pop() : ""
    readonly property string inputExt: root.getExtension(inputPath)

    function getExtension(path) {
        var index = path.lastIndexOf(".")

        if (index === -1) {
            return null
        }

        var output = path.substring(index + 1)

        return output
    }

    function formatSubset(start, end) {
        return formats.slice(start, end)
    }

    function resetStatus() {
        statusText = ""
        success = false
        hasError = false
    }

    function resolveDir(raw) {
        var dir = (raw || "").trim()
        if (dir.startsWith("file://")) dir = dir.substring(7)
        if (dir.startsWith("~")) dir = dir.replace(/~/, "$HOME")
        return dir
    }

    popoutWidth: 320

    Timer {
        interval: 1000
        repeat: true
        running: root._popoutRef !== null && root._popoutRef.shouldBeVisible
        onTriggered: root.silentClipboardCheck()
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            for (var i = 0; i < children.length; i++) {
                var c = children[i]
                if (c && c.hasOwnProperty("shouldBeVisible") && c.hasOwnProperty("backgroundInteractive")) {
                    root._popoutRef = c
                    c.opened.connect(function() {
                        if (root.inputPath === "")
                            Qt.callLater(function() { root.checkClipboard(false) })
                    })
                    break
                }
            }
        })
    }

    horizontalBarPill: RowLayout {
        spacing: 4
        DankIcon { name: "vr180_create2d"; size: Theme.fontSizeLarge; color: Theme.surfaceText }
    }

    verticalBarPill: DankIcon {
        name: "vr180_create2d"; size: Theme.fontSizeLarge; color: Theme.surfaceText
    }

    popoutContent: Component {
        ColumnLayout {
            width: parent.width
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 12
                implicitHeight: 40
                radius: 10
                color: (root.converting || !root.inputPath) ? Qt.alpha(Theme.primary, 0.4) : Theme.primary
                Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    DankIcon {
                        name: root.converting ? "autorenew" : "swap_horiz"
                        size: Theme.fontSizeMedium
                        color: Theme.primaryText
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 1000
                            loops: Animation.Infinite
                            running: root.converting
                        }
                    }

                    StyledText {
                        text: root.converting ? "Converting..." : "Convert"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.primaryText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: (root.converting || !root.inputPath) ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !root.converting && root.inputPath !== ""
                    onClicked: root.convertImage()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: root.statusText ? 8 : 0
                spacing: 8
                visible: root.statusText !== ""

                DankIcon {
                    name: root.success ? "check_circle" : (root.hasError ? "error" : "info")
                    size: Theme.fontSizeSmall
                    color: root.success ? Theme.success : (root.hasError ? Theme.error : Theme.surfaceVariantText)
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.statusText
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.success ? Theme.success : (root.hasError ? Theme.error : Theme.surfaceVariantText)
                    wrapMode: Text.WordWrap
                }
            }

            SectionLabel { text: "Input" }

            Column {
                Layout.fillWidth: true
                spacing: 1

                ListItem {
                    width: parent.width
                    iconName: root.inputPath ? "check_circle" : "upload_file"
                    iconColor: root.inputPath ? Theme.success : Theme.surfaceVariantText
                    label: root.inputPath ? root.fileName : "Drop image here"
                    labelColor: root.inputPath ? Theme.surfaceText : Theme.surfaceVariantText
                    isFirst: true
                    isLast: false

                    DropArea {
                        anchors.fill: parent
                        onDropped: drop => {
                            if (!drop.hasUrls || drop.urls.length === 0) return
                            let path = drop.urls[0].toString()
                            if (path.startsWith("file://")) path = path.substring(7)
                            root.inputPath = path
                            root.resetStatus()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    color: Theme.surfaceContainerHigh
                    bottomLeftRadius: root.inputPath !== "" ? 0 : 10
                    bottomRightRadius: root.inputPath !== "" ? 0 : 10

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 8

                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "paste path..."
                            placeholderTextColor: Theme.primary
                            background: null
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            text: root.inputPath
                            onTextChanged: {
                                root.inputPath = text
                                root.resetStatus()
                            }
                        }

                        Rectangle {
                            implicitWidth: 28; implicitHeight: 28; radius: 6
                            color: root.checkingClipboard ? Qt.alpha(Theme.primary, 0.15) : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                            DankIcon {
                                anchors.centerIn: parent
                                name: root.checkingClipboard ? "hourglass_empty" : "content_paste"
                                size: Theme.fontSizeSmall
                                color: root.checkingClipboard ? Theme.primary : Theme.surfaceVariantText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.checkingClipboard
                                onClicked: root.checkClipboard(true)
                            }
                        }
                    }
                }

                ListItem {
                    width: parent.width
                    iconName: "close"
                    iconColor: Theme.surfaceVariantText
                    label: "Clear"
                    labelColor: Theme.surfaceVariantText
                    isLast: true
                    visible: root.inputPath !== ""
                    onClicked: {
                        root._dismissedPath = root.inputPath
                        root.inputPath = ""
                        root.resetStatus()
                    }
                }
            }

            SectionLabel { text: "Output Format" }

            RowLayout {
                ColumnLayout{
                    Repeater {
                        model: formatSubset(0,(root.formats.length / 2))
                        ListItem {
                            required property string modelData
                            required property int index
                            iconName: root.formatIcons[modelData] || "image"
                            width: parent.width / 2
                            Layout.fillWidth: true
                            label: modelData.toUpperCase()
                            selected: root.outputFormat === modelData
                            isFirst: index === 0
                            isLast: index === (root.formats.length / 2) - 1
                            onClicked: {
                                root.outputFormat = modelData
                                root.resetStatus()
                            }
                        }
                    }
                }
                ColumnLayout{
                    Repeater {
                        model: formatSubset((root.formats.length / 2), root.formats.length)
                        ListItem {
                            required property string modelData
                            required property int index
                            iconName: root.formatIcons[modelData] || "image"
                            width: parent.width / 2
                            Layout.fillWidth: true
                            label: modelData.toUpperCase()
                            selected: root.outputFormat === modelData
                            // isFirst: index === (root.formats.length / 2)
                            // isLast: index === root.formats.length - 1
                            isFirst: index === 0
                            isLast: index === (root.formats.length / 2) - 1
                            onClicked: {
                                root.outputFormat = modelData
                                root.resetStatus()
                            }
                        }
                    }
                }
            }

            SectionLabel { text: "Options"}

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: qualityLayout.implicitHeight + 24
                color: Theme.surfaceContainerHigh
                radius: 10
                visible: root.outputFormat === "jpg" || root.outputFormat === "webp" || root.inputExt === "pdf"

                ColumnLayout {
                    id: qualityLayout
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.outputFormat === "jpg" || root.outputFormat === "webp"
                        DankIcon { name: "tune"; size: Theme.fontSizeSmall; color: Theme.surfaceVariantText }

                        StyledText {
                            Layout.fillWidth: true
                            text: "Quality"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            leftPadding: 8
                        }

                        TextField {
                            id: optionDisplay
                            text: Math.round(optionSlider.value).toString()
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            focus: true
                            background: null
                            horizontalAlignment: TextInput.AlignRight
                            validator: IntValidator {bottom: 10; top: 100}
                            onEditingFinished: {
                                var validInput = acceptableInput
                                if (validInput) {
                                    optionSlider.value = parseFloat(optionDisplay.text)
                                }
                                else {
                                    optionSlider.value = 92
                                }
                            }
                        }
                    }

                    Slider {
                        id: optionSlider
                        visible: root.outputFormat === "jpg" || root.outputFormat === "webp"
                        Layout.fillWidth: true
                        from: 10; to: 100; stepSize: 1
                        value: root.quality
                        onValueChanged: {
                            optionDisplay.text = Math.round(optionSlider.value).toString()
                            root.quality = optionSlider.value
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.inputExt == "pdf"
                        DankIcon { name: "tune"; size: Theme.fontSizeSmall; color: Theme.surfaceVariantText }

                        StyledText {
                            Layout.fillWidth: true
                            text: "Density (DPI)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            leftPadding: 8
                        }

                        TextField {
                            id: optionDisplay2
                            text: Math.round(optionSlider2.value).toString()
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            background: null
                            horizontalAlignment: TextInput.AlignRight
                            focus: true
                            validator: IntValidator {bottom: 50; top: 600}
                            onEditingFinished: {
                                var validInput = acceptableInput
                                if (validInput) {
                                    optionSlider2.value = parseFloat(optionDisplay2.text)
                                }
                                else {
                                    optionSlider2.value = 72
                                }
                            }
                        }
                    }

                    Slider {
                        id: optionSlider2
                        visible: root.inputExt == "pdf"
                        Layout.fillWidth: true
                        from: 50; to: 600; stepSize: 5
                        value: root.density
                        onValueChanged: {
                            optionDisplay2.text = Math.round(optionSlider2.value).toString()
                            root.density = optionSlider2.value
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                implicitHeight: 44
                color: Theme.surfaceContainerHigh
                radius: 10

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8

                    DankIcon { name: "folder"; size: Theme.fontSizeSmall; color: Theme.surfaceVariantText }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "Output Directory: "
                        background: null
                        placeholderTextColor: Theme.primary
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        text: root.resolveDir(root.pluginData.outputDir)
                        onEditingFinished: {
                            root.pluginService.savePluginData(root.pluginId, "outputDir", text)
                        }
                    }
                }
            }

            Item { implicitHeight: 12 }
        }
    }

    function silentClipboardCheck() {
        if (checkingClipboard || converting) return

        Proc.runCommand("imgconv_poll", ["wl-paste", "--list-types"], function(output, exitCode) {
            if (exitCode !== 0) return

            const types = output.trim().split("\n").map(t => t.trim())
            const foundMime = root.imageMimes.find(t => types.includes(t))

            if (foundMime) {
                const ext = foundMime.split("/")[1].replace("jpeg", "jpg")
                const tmpPath = "/tmp/dms_imgconv_clipboard." + ext
                if (tmpPath === root._dismissedPath || tmpPath === root.inputPath) return
                Proc.runCommand("imgconv_poll_save", ["sh", "-c", "wl-paste --type " + foundMime + " > " + tmpPath], function(_, code) {
                    if (code !== 0) return
                    root._dismissedPath = ""
                    root.inputPath = tmpPath
                    root.resetStatus()
                    root.statusText = "Image from clipboard"
                })
                return
            }

            if (types.includes("text/uri-list")) {
                Proc.runCommand("imgconv_poll_uri", ["wl-paste", "--type", "text/uri-list", "--no-newline"], function(text, code) {
                    if (code !== 0) return
                    let uri = text.trim().split("\n")[0].trim()
                    if (uri.startsWith("file://")) uri = uri.substring(7)
                    if (uri === root._dismissedPath || uri === root.inputPath) return
                    if (root.imageExts.some(ext => uri.toLowerCase().endsWith(ext))) {
                        root._dismissedPath = ""
                        root.inputPath = uri
                        root.resetStatus()
                        root.statusText = "File from clipboard"
                    }
                })
                return
            }

            if (types.some(t => t === "text/plain" || t === "UTF8_STRING")) {
                Proc.runCommand("imgconv_poll_text", ["wl-paste", "--no-newline"], function(text, code) {
                    if (code !== 0) return
                    const path = text.trim()
                    if (path === root._dismissedPath || path === root.inputPath) return
                    if (root.imageExts.some(ext => path.toLowerCase().endsWith(ext))) {
                        root._dismissedPath = ""
                        root.inputPath = path
                        root.resetStatus()
                        root.statusText = "Path from clipboard"
                    }
                })
            }
        })
    }

    function checkClipboard(showEmptyError) {
        checkingClipboard = true
        resetStatus()

        Proc.runCommand("imgconv_list_types", ["wl-paste", "--list-types"], function(output, exitCode) {
            if (exitCode !== 0) {
                root.checkingClipboard = false
                root.statusText = "Could not read clipboard"
                root.hasError = true
                return
            }

            const types = output.trim().split("\n").map(t => t.trim())
            const foundMime = root.imageMimes.find(t => types.includes(t))

            if (foundMime) {
                const ext = foundMime.split("/")[1].replace("jpeg", "jpg")
                const tmpPath = "/tmp/dms_imgconv_clipboard." + ext
                Proc.runCommand("imgconv_save_img", ["sh", "-c", "wl-paste --type " + foundMime + " > " + tmpPath], function(_, code) {
                    root.checkingClipboard = false
                    if (code === 0) {
                        root.inputPath = tmpPath
                        root.statusText = "Image from clipboard"
                    } else {
                        root.statusText = "Failed to read clipboard image"
                        root.hasError = true
                    }
                })
                return
            }

            if (types.includes("text/uri-list")) {
                Proc.runCommand("imgconv_get_uri", ["wl-paste", "--type", "text/uri-list", "--no-newline"], function(text, code) {
                    root.checkingClipboard = false
                    if (code !== 0) {
                        root.statusText = "Could not read clipboard"
                        root.hasError = true
                        return
                    }
                    let uri = text.trim().split("\n")[0].trim()
                    if (uri.startsWith("file://")) uri = uri.substring(7)
                    if (root.imageExts.some(ext => uri.toLowerCase().endsWith(ext))) {
                        root.inputPath = uri
                        root.statusText = "File from clipboard"
                    } else {
                        root.statusText = "Copied file is not an image"
                        root.hasError = true
                    }
                })
                return
            }

            if (types.some(t => t === "text/plain" || t === "UTF8_STRING" || t === "TEXT" || t === "STRING")) {
                Proc.runCommand("imgconv_get_text", ["wl-paste", "--no-newline"], function(text, code) {
                    root.checkingClipboard = false
                    if (code !== 0) {
                        root.statusText = "Could not read clipboard text"
                        root.hasError = true
                        return
                    }
                    const path = text.trim()
                    if (root.imageExts.some(ext => path.toLowerCase().endsWith(ext))) {
                        root.inputPath = path
                        root.statusText = "Path from clipboard"
                    } else {
                        root.statusText = "Clipboard has no image or image path"
                        root.hasError = true
                    }
                })
                return
            }

            root.checkingClipboard = false
            if (showEmptyError) {
                root.statusText = "No image in clipboard"
                root.hasError = true
            }
        })
    }

    function convertImage() {
        if (inputPath === "") return

        converting = true
        resetStatus()

        var savedDir = resolveDir(pluginData.outputDir)
        var hasQuality = outputFormat === "jpg" || outputFormat === "webp"
        var hasDensity = inputExt === "pdf"
        var baseName = inputPath.split("/").pop().replace(/\.[^/.]+$/, "")
                       + (hasQuality ? "_q" + quality : "") + (hasDensity ? "_d" + density : "")
        var qualityArgs = hasQuality ? " -quality " + quality + " " : ""
        var densityArgs = hasDensity ? " -density " + density + " " : ""
        var heifArgs = (inputExt === "heic" || inputExt === "heif") ? " -quality " + heifQuality + " " : ""
        var outDirExpr = savedDir ? JSON.stringify(savedDir) : '"$HOME/Pictures/converted"'

        var cmd = "mkdir -p " + outDirExpr
            + " && dir=" + outDirExpr
            + " && base=" + JSON.stringify(baseName)
            + " && ext=" + JSON.stringify(outputFormat)
            + ' && out="$dir/$base.$ext"'
            + " && n=1"
            + ' && while [ -f "$out" ]; do out="$dir/$base($n).$ext"; n=$((n+1)); done'
            + " && ( magick -limit memory 1GiB -limit map 1GiB -limit area 1GiB "
            + densityArgs + heifArgs + qualityArgs + JSON.stringify(inputPath) + ' "$out" 2>&1 ; test -f "$out" )'
            + " && printf 'SAVED:%s' \"$out\""

        Proc.runCommand("imgconv_convert", ["sh", "-c", cmd], function(output, exitCode) {
            root.converting = false
            if (exitCode === 0 || exitCode === 1) {
                const idx = (output || "").indexOf("SAVED:")
                const savedName = idx >= 0
                    ? output.substring(idx + 6).trim().split("/").pop()
                    : baseName + "." + root.outputFormat
                root.success = true
                root.statusText = "Saved as " + savedName
            } else {
                root.hasError = true
                root.statusText = (output || "").replace(/SAVED:[^\n]*/g, "").trim() || ("Failed (exit code " + exitCode + ")")
            }
        })
    }
}