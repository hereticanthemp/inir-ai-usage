#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
inir_root=${INIR_ROOT:-"$config_home/quickshell/inir"}
inir_config=${INIR_CONFIG:-"$config_home/inir/config.json"}
widget_dir="$config_home/inir/widgets/ai-usage"
backup_dir="$config_home/inir/.inir-ai-usage-backup"
restart=true

if [[ ${1:-} == "--no-restart" ]]; then restart=false; fi

for command_name in ai-usagebar python3 rg; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    }
done

[[ -f "$inir_root/VERSION" ]] || { printf 'iNiR not found at %s\n' "$inir_root" >&2; exit 1; }
inir_version=$(<"$inir_root/VERSION")
[[ $inir_version == 2.31.* ]] || {
    printf 'This patch targets iNiR 2.31.x; found %s. Review the patch before continuing.\n' "$inir_version" >&2
    exit 1
}

mkdir -p "$widget_dir" "$backup_dir/modules/bar" "$backup_dir/modules/sidebarLeft/widgets"
for relative_path in modules/bar/BarContent.qml modules/sidebarLeft/widgets/DraggableWidgetContainer.qml; do
    if [[ ! -e "$backup_dir/$relative_path" ]]; then
        cp -- "$inir_root/$relative_path" "$backup_dir/$relative_path"
    fi
done

cp -- "$repo_root/widget/AiUsageBar.qml" "$repo_root/widget/AiUsageCard.qml" "$widget_dir/"

if ! rg -q '"aiUsage": aiUsageComponent' "$inir_root/modules/bar/BarContent.qml"; then
    python3 - "$inir_root" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
bar = root / 'modules/bar/BarContent.qml'
widgets = root / 'modules/sidebarLeft/widgets/DraggableWidgetContainer.qml'

bar_text = bar.read_text()
old = '''        "timer": timerComponent,
        "shellUpdate": shellUpdateComponent,'''
new = '''        "timer": timerComponent,
        "aiUsage": aiUsageComponent,
        "shellUpdate": shellUpdateComponent,'''
if old not in bar_text:
    raise SystemExit('Could not find the iNiR bar component-map insertion point')
bar_text = bar_text.replace(old, new, 1)

old = '''    Component { id: timerComponent; TimerIndicator { Layout.alignment: Qt.AlignVCenter } }
    Component { id: shellUpdateComponent; ShellUpdateIndicator { Layout.alignment: Qt.AlignVCenter } }'''
new = '''    Component { id: timerComponent; TimerIndicator { Layout.alignment: Qt.AlignVCenter } }
    Component {
        id: aiUsageComponent
        Loader {
            source: Directories.configPath + "/inir/widgets/ai-usage/AiUsageBar.qml"
            Layout.alignment: Qt.AlignVCenter
        }
    }
    Component { id: shellUpdateComponent; ShellUpdateIndicator { Layout.alignment: Qt.AlignVCenter } }'''
if old not in bar_text:
    raise SystemExit('Could not find the iNiR bar component insertion point')
bar.write_text(bar_text.replace(old, new, 1))

widget_text = widgets.read_text()
old = '''    Component {
        id: statusWidget
        StatusRings {}
    }'''
new = '''    Component {
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
if old not in widget_text:
    raise SystemExit('Could not find the Widgets status insertion point')
widgets.write_text(widget_text.replace(old, new, 1))
PY
fi

python3 - "$inir_config" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
json.loads(text)

if '"aiUsage"' not in text:
    old = '                "timer",\n                "shellUpdate",'
    new = '                "timer",\n                "aiUsage",\n                "shellUpdate",'
    if old not in text:
        raise SystemExit('Could not find the iNiR bar layout insertion point')
    text = text.replace(old, new, 1)

if '"aiUsage": true' not in text:
    old = '        "modules": {\n            "activeWindow": true,'
    new = '        "modules": {\n            "activeWindow": true,\n            "aiUsage": true,'
    if old not in text:
        raise SystemExit('Could not find the iNiR module settings insertion point')
    text = text.replace(old, new, 1)

path.write_text(text)
PY

if $restart && systemctl --user is-active --quiet inir.service; then
    systemctl --user restart inir.service
fi

printf 'Installed iNiR AI Usage for iNiR %s.\n' "$inir_version"
