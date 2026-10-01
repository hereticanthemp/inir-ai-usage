# iNiR integration and update compatibility

## Current placement

This project intentionally places its two views in the iNiR **ii** interface:

- `AiUsageBar.qml` appears in the ii bar.
- `AiUsageCard.qml` appears below the CPU/RAM status rings in the left Widgets panel.

This placement is a deliberate project requirement and should be preserved.

## Why this is not a standard custom widget

iNiR 2.31 discovers standard custom widgets from
`~/.config/inir/widgets/<id>/widget.json`. Its public Custom Widget SDK supports
desktop widgets. A manifest may also expose an `iris` component for an iRiS bar
slot.

The SDK does not provide extension slots for either of the ii locations used by
this project:

- the ii bar module map;
- the left Widgets panel status stack.

Putting QML files under `~/.config/inir/widgets/ai-usage/` alone therefore does
not make these views discoverable in their required locations. A `widget.json`
manifest would move the supported presentation to the desktop or iRiS and would
not preserve the current ii layout.

## Patched iNiR files

The installer makes small, targeted edits to these upstream files:

```text
~/.config/quickshell/inir/modules/bar/BarContent.qml
~/.config/quickshell/inir/modules/sidebarLeft/widgets/DraggableWidgetContainer.qml
```

It also adds the `aiUsage` module to `~/.config/inir/config.json`. The widget's
own QML remains under `~/.config/inir/widgets/ai-usage/`, outside the iNiR source
tree.

The exact source changes are recorded in `patches/inir-2.31.patch`.

## Effect of an iNiR update

An iNiR update may replace either patched QML file. When that happens, the bar
entry or detailed card can disappear even though the widget files and provider
credentials are still present.

After updating iNiR, update this repository and run the installer again:

```bash
cd ~/Projects/personal/inir-ai-usage
git pull --ff-only
./scripts/install.sh
```

The installer only supports the iNiR version range it recognizes. It stops when
the expected insertion points are missing instead of modifying an unknown file
layout. Review and update the compatibility patch for a new iNiR release before
expanding the accepted version range.

Backups of the original integration files are stored under:

```text
~/.config/inir/.inir-ai-usage-backup/
```

## Long-term upstream solution

The patch can be removed only after iNiR exposes public custom-widget slots for
the ii bar and the left Widgets panel. Until then, keeping the current placement
and using only the standard Custom Widget SDK are mutually incompatible.

