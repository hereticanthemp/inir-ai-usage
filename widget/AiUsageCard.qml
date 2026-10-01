import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property var report: ({ entries: [] })
    property string failure: ""
    property bool refreshing: false
    property int clockTick: 0
    readonly property var entries: (report.entries ?? []).filter(e => e.status === "ready" || (e.metrics ?? []).length > 0)

    implicitHeight: content.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    function colorFor(percent) {
        if (percent >= 90) return Appearance.colors.colError
        if (percent >= 70) return Appearance.colors.colSecondary
        return Appearance.colors.colPrimary
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
    function refresh() {
        if (refreshing) return
        refreshing = true
        reader.running = true
    }
    Component.onCompleted: refresh()
    Timer { interval: 60000; repeat: true; running: true; onTriggered: root.clockTick++ }
    Timer { interval: 300000; repeat: true; running: true; onTriggered: root.refresh() }
    Process {
        id: reader
        command: ["ai-usagebar", "usage", "--json"]
        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                try { root.report = JSON.parse(output.text); root.failure = "" }
                catch (error) { root.failure = "Invalid quota report" }
            }
        }
        onExited: (code, status) => {
            root.refreshing = false
            if (code !== 0) root.failure = "ai-usagebar failed (" + code + ")"
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 9
        RowLayout {
            Layout.fillWidth: true
            MaterialSymbol { text: "smart_toy"; iconSize: 19; color: Appearance.colors.colPrimary }
            StyledText { text: "AI Usage"; font.weight: Font.DemiBold; Layout.fillWidth: true }
            StyledText { visible: root.refreshing; text: "…"; opacity: 0.6 }
            RippleButton {
                implicitWidth: 28; implicitHeight: 28
                onClicked: root.refresh()
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 17 }
            }
        }
        StyledText {
            visible: root.failure.length > 0
            Layout.fillWidth: true
            text: root.failure
            color: Appearance.colors.colError
            wrapMode: Text.Wrap
        }
        StyledText {
            visible: root.entries.length === 0 && !root.failure
            text: root.refreshing ? "Refreshing…" : "No quota data"
            opacity: 0.65
        }
        Repeater {
            model: root.entries
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: modelData.display_name ?? modelData.name; font.weight: Font.Medium; Layout.fillWidth: true }
                    StyledText { text: modelData.plan ?? ""; font.pixelSize: Appearance.font.pixelSize.smaller; opacity: 0.55 }
                }
                Repeater {
                    model: modelData.metrics ?? []
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { text: modelData.label ?? "Quota"; Layout.fillWidth: true; font.pixelSize: Appearance.font.pixelSize.small }
                            StyledText { text: modelData.value ?? (Math.round(modelData.percent ?? 0) + "%"); color: root.colorFor(modelData.percent ?? 0); font.weight: Font.DemiBold }
                            StyledText { visible: !!modelData.reset_at; text: root.countdown(modelData.reset_at); opacity: 0.65; font.pixelSize: Appearance.font.pixelSize.smaller }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 7
                            radius: 4
                            color: Appearance.colors.colLayer1
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, (modelData.percent ?? 0) / 100))
                                height: parent.height
                                radius: parent.radius
                                color: root.colorFor(modelData.percent ?? 0)
                            }
                        }
                        StyledText { Layout.fillWidth: true; text: modelData.detail ?? ""; font.pixelSize: Appearance.font.pixelSize.smaller; opacity: 0.58; wrapMode: Text.Wrap }
                    }
                }
            }
        }
    }
}
