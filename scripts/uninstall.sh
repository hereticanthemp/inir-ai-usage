#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
inir_root=${INIR_ROOT:-"$config_home/quickshell/inir"}
inir_config=${INIR_CONFIG:-"$config_home/inir/config.json"}
widget_dir="$config_home/inir/widgets/ai-usage"
restart=true

if [[ ${1:-} == "--no-restart" ]]; then restart=false; fi

if rg -q '"aiUsage": aiUsageComponent' "$inir_root/modules/bar/BarContent.qml"; then
    python3 - "$inir_root" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
bar = root / 'modules/bar/BarContent.qml'
widgets = root / 'modules/sidebarLeft/widgets/DraggableWidgetContainer.qml'

bar_text = bar.read_text()
bar_text = bar_text.replace('        "aiUsage": aiUsageComponent,\n', '', 1)
block = '''    Component {
        id: aiUsageComponent
        Loader {
            source: Directories.configPath + "/inir/widgets/ai-usage/AiUsageBar.qml"
            Layout.alignment: Qt.AlignVCenter
        }
    }
'''
bar.write_text(bar_text.replace(block, '', 1))

widget_text = widgets.read_text()
installed = '''    Component {
        id: statusWidget
        ColumnLayout {
            spacing: root.widgetSpacing
            StatusRings { Layout.fillWidth: true }
            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: item?.implicitHeight ?? 0
                source: Directories.configPath + "/inir/widgets/ai-usage/AiUsageCard.qml"
            }
        }
    }'''
original = '''    Component {
        id: statusWidget
        StatusRings {}
    }'''
widgets.write_text(widget_text.replace(installed, original, 1))
PY
fi

python3 - "$inir_config" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
json.loads(text)
text = text.replace('                "aiUsage",\n', '', 1)
text = text.replace('            "aiUsage": true,\n', '', 1)
path.write_text(text)
PY

if [[ -d "$widget_dir" ]]; then
    rm -f -- "$widget_dir/AiUsageBar.qml" "$widget_dir/AiUsageCard.qml"
    rmdir -- "$widget_dir" 2>/dev/null || true
fi

if $restart && systemctl --user is-active --quiet inir.service; then
    systemctl --user restart inir.service
fi

printf 'Removed iNiR AI Usage. Backups remain under %s.\n' "$config_home/inir/.inir-ai-usage-backup"
