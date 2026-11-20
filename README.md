<!-- LOGO -->
<p align="center">
  <img src="https://github.com/user-attachments/assets/fe853809-ba8b-400b-83ab-a9a0da25be8a" alt="Ghostty logo" width="128">
</p>

# Ghostty with Quick Terminal Tabs

[![Build and Release Ghostty](https://github.com/bessx/ghostty/actions/workflows/build-macos.yml/badge.svg)](https://github.com/bessx/ghostty/actions/workflows/build-macos.yml)
[![Latest release](https://img.shields.io/github/v/release/bessx/ghostty)](https://github.com/bessx/ghostty/releases/latest)

An unofficial macOS distribution of [Ghostty](https://ghostty.org/) with **tab support in Quick Terminal**, bringing an iTerm2-style tabbed dropdown terminal experience to Ghostty without requiring users to compile it themselves.

This fork tracks [juftin/ghostty](https://github.com/juftin/ghostty), which incorporates [adrum's Quick Terminal tab support (PR #9857)](https://github.com/ghostty-org/ghostty/pull/9857). This repository provides automated universal macOS builds, releases, and a simple installation and update script.

[Latest release](https://github.com/bessx/ghostty/releases/latest) · [Installation](#installation) · [Quick Terminal setup](#quick-terminal-setup) · [Troubleshooting](#troubleshooting) · [Official Ghostty documentation](https://ghostty.org/docs)

## Features

- Multiple tabs within Quick Terminal.
- Keyboard shortcuts for creating, closing, and switching tabs.
- Tab renaming, coloring, dragging, and rearranging.
- Quick Terminal session restoration.
- Universal macOS builds for both Intel and Apple Silicon.
- Automatic upstream synchronization every six hours and new builds when changes are merged.
- GitHub Releases with SHA-256 checksums and build provenance attestations.
- A command-line updater with automatic installation and previous-version backups.

## System requirements

- macOS 13 Ventura or later, on supported Mac hardware.
- Intel (x86_64) or Apple Silicon (arm64).
- An administrator account for installation in `/Applications`.

No Xcode, Zig, Homebrew, or local compilation is required. The universal binary includes both processor architectures. The custom build has been tested on macOS Ventura on an Intel Mac; compatibility with every newer macOS release is not independently verified. Linux and Windows builds are not provided by this fork.

## Installation

> [!IMPORTANT]
> These are unofficial, non-notarized builds. The installer removes the downloaded app's quarantine attribute and applies an ad-hoc signature. Review the [installer source](https://github.com/bessx/ghostty/blob/main/ghostty-update.sh) before running it, and only install builds you trust. The installer replaces `/Applications/Ghostty.app`, so save your work and run it from Terminal.app or iTerm2, not Ghostty itself.

### Install using the updater (recommended)

Download the updater into your personal executable directory:

```sh
mkdir -p ~/.local/bin
curl -fsSL \
  https://raw.githubusercontent.com/bessx/ghostty/main/ghostty-update.sh \
  -o ~/.local/bin/ghostty-update
chmod +x ~/.local/bin/ghostty-update
```

Review the script if desired, then install the latest build:

```sh
~/.local/bin/ghostty-update
```

The script downloads the latest release, verifies its SHA-256 checksum, extracts the application, signs it locally, verifies the signature, backs up the previous installation, and installs and launches Ghostty in `/Applications`. It will request your administrator password for installation.

To run the updater from any directory using just `ghostty-update`, add the following line to your `~/.zshrc` if `~/.local/bin` is not already on your PATH:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell configuration:

```sh
source ~/.zshrc
```

### Manual installation

Download `Ghostty-Universal.zip` and `Ghostty-Universal.zip.sha256` from the [latest release](https://github.com/bessx/ghostty/releases/latest). In Terminal.app, verify the archive and extract it to a temporary folder:

```sh
cd ~/Downloads
shasum -a 256 -c Ghostty-Universal.zip.sha256
```

Proceed only if the checksum reports `OK`. Quit all running Ghostty instances, then run:

```sh
WORKDIR=$(mktemp -d)
ditto -x -k ~/Downloads/Ghostty-Universal.zip "$WORKDIR"
xattr -dr com.apple.quarantine "$WORKDIR/Ghostty.app"
codesign --force --deep --sign - "$WORKDIR/Ghostty.app"
codesign --verify --deep --strict "$WORKDIR/Ghostty.app"
```

Verify that signing succeeds before proceeding. Back up any existing installation, then move the new application into `/Applications`:

```sh
mkdir -p ~/Backups/Ghostty
if [ -d /Applications/Ghostty.app ]; then
  sudo mv /Applications/Ghostty.app \
    "$HOME/Backups/Ghostty/Ghostty-$(date +%Y%m%d-%H%M%S).app"
fi
sudo ditto "$WORKDIR/Ghostty.app" /Applications/Ghostty.app
open -n /Applications/Ghostty.app
```

The updater is recommended because it handles these steps automatically and attempts to restore the previous version if copying the new application fails.

## Updating Ghostty

From Terminal.app or another terminal emulator, run:

```sh
ghostty-update
```

If you did not add the updater directory to your PATH, use `~/.local/bin/ghostty-update` instead.

The updater skips installation if its recorded checksum matches the latest release. To force a reinstall, including when switching from an official Ghostty build:

```sh
ghostty-update --force
```

### Disable official automatic updates

Add the following to your existing Ghostty configuration so that this custom build is not replaced by an official release:

```ini
auto-update = off
```

Use `ghostty-update` to manage updates from this fork instead. See the [Ghostty configuration documentation](https://ghostty.org/docs/config) for configuration file locations and options.

## Quick Terminal setup

Quick Terminal is Ghostty's dropdown terminal. It has no default toggle keybinding in this fork. Add a global binding to your Ghostty configuration, for example:

```ini
keybind = global:ctrl+grave_accent=toggle_quick_terminal
```

Choose a shortcut that does not conflict with another application. Completely restart Ghostty, grant Accessibility permissions if prompted, and use the shortcut to open Quick Terminal. Use your usual new-tab shortcut (typically `Cmd+T`) to create tabs inside it, and `Cmd+W` to close a tab.

## Troubleshooting

### Quick Terminal asks for Accessibility permissions repeatedly

The updater uses generic ad-hoc code signing so that an Apple Developer account or a custom certificate is not required. macOS may invalidate previously granted Accessibility permissions when an application is replaced or its signature changes.

If Ghostty asks for Accessibility access even though it already appears enabled:

1. Quit Ghostty completely.
2. Open Terminal.app and reset Ghostty's Accessibility authorization:

   ```sh
   tccutil reset Accessibility com.mitchellh.ghostty
   ```

3. Relaunch the correct application:

   ```sh
   open -n /Applications/Ghostty.app
   ```

4. Open **System Settings > Privacy & Security > Accessibility** and enable Ghostty again. If necessary, remove the stale entry and add `/Applications/Ghostty.app` manually.
5. Quit and reopen Ghostty if prompted, then test your Quick Terminal shortcut.

This command resets Accessibility access for Ghostty only. It does not clear your Ghostty configuration. Do not add the reset command to the updater, since it would revoke access on every update.

### Quick Terminal tabs are missing after an update

Make sure macOS is launching this fork rather than a separate official Ghostty installation. Both applications use the same bundle identifier, so duplicate copies may cause confusion.

```sh
ls -ld /Applications/Ghostty.app ~/Applications/Ghostty.app 2>/dev/null
/Applications/Ghostty.app/Contents/MacOS/ghostty +version
open -n /Applications/Ghostty.app
```

Custom builds include a source commit hash in their version output. If you maintain another Ghostty installation, move it out of your Applications directories after quitting it, and remove any stale Dock shortcuts. Pin the intended application again.

You can also check whether the Quick Terminal tab implementation is present in the installed binary:

```sh
strings /Applications/Ghostty.app/Contents/MacOS/ghostty | \
  grep -iE 'QuickTerminalTab|QuickTerminalTabBar' | head -10
```

### Roll back to the previous installation

The updater keeps one backup at `~/Backups/Ghostty/Ghostty.app`. If it exists, quit Ghostty, then restore it from Terminal.app:

```sh
test -d "$HOME/Backups/Ghostty/Ghostty.app" && \
  sudo mv /Applications/Ghostty.app \
    "$HOME/Backups/Ghostty/Ghostty-replaced-$(date +%Y%m%d-%H%M%S).app" && \
  sudo ditto "$HOME/Backups/Ghostty/Ghostty.app" /Applications/Ghostty.app && \
  rm -f "$HOME/.config/ghostty-update/checksum" && \
  open -n /Applications/Ghostty.app
```

### Download fails with a 404 error

Check the [Releases page](https://github.com/bessx/ghostty/releases) and [Actions dashboard](https://github.com/bessx/ghostty/actions). The updater requires a successfully published release with the universal ZIP and its checksum; a running or failed build will not produce a new release.

## Automated builds and releases

Two GitHub Actions workflows maintain this distribution:

| Workflow | Purpose |
| --- | --- |
| [Sync Upstream](.github/workflows/sync-upstream.yml) | Checks juftin's fork every six hours, merges new changes, and triggers a build when needed. |
| [Build and Release Ghostty](.github/workflows/build-macos.yml) | Compiles a universal macOS application, verifies architectures, creates the archive and checksum, generates build provenance, and publishes a GitHub Release. |

Release assets include `Ghostty-Universal.zip`, `Ghostty-Universal.zip.sha256`, and, from the first build including the updater, `ghostty-update.sh`. Documentation-only and updater-only pushes do not normally trigger recompilation. Build failures or upstream merge conflicts may require manual intervention.

The release checksum detects download corruption or mismatches. It is not a substitute for trusting the source. Published build provenance can also be verified using GitHub CLI:

```sh
gh attestation verify Ghostty-Universal.zip --repo bessx/ghostty
```

## Credits and upstream documentation

This is an unofficial distribution, not an official Ghostty release. All credit for Ghostty belongs to the [Ghostty project and its contributors](https://github.com/ghostty-org/ghostty). Special thanks to [adrum](https://github.com/adrum) and the contributors to [PR #9857](https://github.com/ghostty-org/ghostty/pull/9857) for Quick Terminal tabs, and to [juftin](https://github.com/juftin) for maintaining the upstream fork and local macOS build tooling.

For general Ghostty features, documentation, contribution guidelines, roadmap, and crash reporting, see the [upstream README](https://github.com/juftin/ghostty/blob/main/README.md) and [official documentation](https://ghostty.org/docs). For problems specific to these builds or the installer, use this repository's issue tracker.

Distributed under the repository's [LICENSE](LICENSE).
