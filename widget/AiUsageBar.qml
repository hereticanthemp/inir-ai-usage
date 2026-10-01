import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: root

    property var report: ({ entries: [] })
    property string failure: ""
    property bool refreshing: false
    property int clockTick: 0

    readonly property var entries: (report.entries ?? []).filter(e => e.status === "ready" || (e.metrics ?? []).length > 0)
    readonly property var headlineEntry: {
        let best = null
        for (const entry of entries) {
            for (const metric of (entry.metrics ?? [])) {
                if (metric.percent === undefined || metric.percent === null) continue
                if (!best || Number(metric.percent) > Number(best.metric.percent)) best = ({ entry, metric })
            }
        }
        return best
    }

    function countdown(resetAt) {
        clockTick
        if (!resetAt) return ""
        const seconds = Math.max(0, Math.floor((Date.parse(resetAt) - Date.now()) / 1000))
        const days = Math.floor(seconds / 86400)
        const hours = Math.floor((seconds % 86400) / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        if (days > 0) return days + "d " + hours + "h"
        if (hours > 0) return hours + "h " + minutes + "m"
        return minutes + "m"
    }

    function colorFor(percent) {
        if (percent >= 90) return Appearance.colors.colError
        if (percent >= 70) return Appearance.colors.colSecondary
        return Appearance.colors.colOnLayer1
    }

    function refresh() {
        if (refreshing) return
        refreshing = true
        reader.running = true
    }

    implicitWidth: capsule.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) refresh()
        else {
            GlobalStates.openSidebarLeft(root.QsWindow.window?.screen?.name ?? "")
        }
    }
    Component.onCompleted: refresh()

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.clockTick++
    }
    Timer {
        interval: 300000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: reader
        command: ["ai-usagebar", "usage", "--json"]
        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                try {
                    root.report = JSON.parse(output.text)
                    root.failure = ""
                } catch (error) {
                    root.failure = "Invalid ai-usagebar report"
                }
            }
        }
        onExited: (code, status) => {
            root.refreshing = false
            if (code !== 0) root.failure = "ai-usagebar failed (" + code + ")"
        }
    }

    Rectangle {
        id: capsule
        anchors.centerIn: parent
        implicitWidth: compact.implicitWidth + 18
        implicitHeight: Math.min(root.height - 6, 30)
        radius: height / 2
        color: root.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"

        RowLayout {
            id: compact
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                text: root.refreshing ? "progress_activity" : "smart_toy"
                iconSize: Appearance.font.pixelSize.normal
                color: root.failure ? Appearance.colors.colError : root.colorFor(root.headlineEntry?.metric?.percent ?? 0)
            }
            StyledText {
                text: root.headlineEntry
                    ? root.headlineEntry.entry.display_name + " " + Math.round(root.headlineEntry.metric.percent) + "%"
                    : (root.failure ? "AI !" : "AI …")
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.failure ? Appearance.colors.colError : root.colorFor(root.headlineEntry?.metric?.percent ?? 0)
            }
            StyledText {
                visible: root.headlineEntry?.metric?.reset_at !== undefined
                text: root.countdown(root.headlineEntry?.metric?.reset_at)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
                opacity: 0.65
            }
        }
    }

}
