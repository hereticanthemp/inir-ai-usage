# iNiR AI Usage

An AI subscription quota widget for iNiR 2.31.x on Linux. It adds a compact
reading to the iNiR bar and a detailed card below the CPU/RAM status rings in
the left Widgets panel.

The frontend is QML. Quota collection stays in
[`ai-usagebar`](https://github.com/akitaonrails/ai-usagebar), which already
supports Codex, Claude, OpenCode Go, SuperGrok, Antigravity, Z.AI, Kimi,
DeepSeek, MiniMax and other providers.

## What it shows

- Provider and current quota percentage in the bar
- Quota-window labels and progress bars
- Reset countdowns, updated locally between backend polls
- Every provider that returns a ready `ai-usagebar usage --json` entry

Left-clicking the bar reading opens iNiR's left Widgets panel. Right-clicking
refreshes immediately. The normal polling interval is five minutes.

## Requirements

- iNiR 2.31.x
- Quickshell
- `ai-usagebar` on `PATH`
- `python3` and `rg`

Install `ai-usagebar` using one of its documented methods. Fedora Asahi and
other aarch64 Linux systems can use its official `linux-aarch64` release.

Provider credentials remain with their official clients. For example:

- Codex uses the existing `codex login` session.
- SuperGrok uses the official Grok Build `grok login` session.
- Antigravity uses the official `agy` session or its running local service.

No key, token, cookie, or credential file is stored in this repository or QML.

## Install

```bash
git clone <your-repository-url> inir-ai-usage
cd inir-ai-usage
./scripts/install.sh
```

The installer checks the iNiR version, backs up the patched files, installs the
QML under `~/.config/inir/widgets/ai-usage`, adds both integration points,
updates the bar layout without reformatting its JSON, and restarts an active
`inir.service`.

This is an ii integration rather than a manifest-discovered desktop widget.
See [iNiR integration and update compatibility](docs/INIR-INTEGRATION.md) for
the reason, the files affected by updates, and the recovery procedure.

Use `--no-restart` to apply the files without restarting the shell:

```bash
./scripts/install.sh --no-restart
```

Custom locations are supported through `INIR_ROOT`, `INIR_CONFIG`, and
`XDG_CONFIG_HOME`.

## Enable providers

```bash
ai-usagebar settings enable supergrok
ai-usagebar settings enable antigravity
ai-usagebar usage --json
```

Only providers with usable quota readings appear. A provider merely being
configured in OpenCode is insufficient because OpenCode's local server exposes
session token/cost statistics, not subscription quota windows or reset times.

## Update

```bash
git pull --ff-only
./scripts/install.sh
```

Widget files are replaced. The iNiR patch is applied only when absent.

## Remove

```bash
./scripts/uninstall.sh
```

The uninstaller reverses this repository's patch and removes its two QML files.
Safety backups remain under `~/.config/inir/.inir-ai-usage-backup/`.

## Repository layout

```text
inir-ai-usage/
├── widget/
│   ├── AiUsageBar.qml
│   └── AiUsageCard.qml
├── patches/
│   └── inir-2.31.patch
├── docs/
│   └── INIR-INTEGRATION.md
├── scripts/
│   ├── install.sh
│   └── uninstall.sh
├── .gitignore
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Update compatibility

iNiR 2.31 does not expose a general custom-module hook for this ii bar and
Widgets status stack, so two small upstream files are patched. An iNiR update
may change those insertion points. The installer stops on unsupported versions
instead of guessing.

The long-term upstream improvement would be a user-module loader for the ii bar
and Widgets panel, removing the need for this compatibility patch.

## Credits

- Backend: [`akitaonrails/ai-usagebar`](https://github.com/akitaonrails/ai-usagebar)
- UI and polling behavior informed by Noctalia's community AI Usage integration
- Shell integration targets iNiR 2.31.x

This repository contains only the iNiR integration. It does not vendor or
redistribute the `ai-usagebar` binary.
