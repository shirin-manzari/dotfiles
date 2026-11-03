# Dotfiles

Personal configs for macOS and Windows.

## Windows setup

Run from this repo in a normal, non-administrator Windows PowerShell window
(Windows 10/11). WinGet must be available through Microsoft's App Installer.
If PowerShell blocks scripts, enable local scripts for your account first:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Preview the setup, then run it:

```powershell
.\windows\setup.ps1 -DryRun
.\windows\setup.ps1
```

The setup installs Scoop if missing, installs CLI tools and fonts, installs
Terminal-Icons for the current user, and installs Google Chrome, VS Code,
and Windows Terminal through WinGet. App installers may request elevation.
It also installs the extensions listed in `config/vscode/extensions.txt`.
Existing WinGet apps are kept without upgrades.

The setup activates the repo's PowerShell profile for Windows PowerShell and
PowerShell 7, adds an include to your existing Git config, and copies the
Neovim, micro, VS Code, and Windows Terminal configs to their Windows locations.
PowerShell 7 itself is optional and is not installed by the setup. Run the
setup in Windows PowerShell so Terminal-Icons is available to both editions.

Changed files get an adjacent `.dotfiles-backup-<timestamp>-<id>` copy before
replacement. PowerShell customization outside the managed block is preserved;
the old Oh My Posh and Terminal-Icons initialization lines are replaced.
Git identity and other existing settings are preserved. Editor and Terminal
settings are replaced with the repo versions after backup. Existing links
to different content are left unchanged with an error.

Restart your terminal after setup. PowerShell and Git load their configs from
this clone, so keep the repo in place. After editing the repo's copied configs,
refresh them without installing packages:

```powershell
.\windows\setup.ps1 -ConfigOnly
```

Repeating setup leaves identical files unchanged and replaces the managed
profile block without adding duplicates. To restore a file, copy its desired
backup over the configured file. Private Git settings can also go in
`~/.gitconfig.local`, which the shared Git config includes.

## Windows package lists

- `windows/Scoopfile.ps1`: curated CLI tools and fonts based on the Brewfile.
- `windows/setup.ps1`: Chrome, VS Code, and Windows Terminal WinGet commands.
- `config/vscode/extensions.txt`: VS Code extension IDs, one per line.

Run `.\windows\Scoopfile.ps1` to install just CLI tools and fonts when Scoop is
already installed. Node.js uses `nodejs-lts`. Fish and tmux are left for WSL;
WSL installation is separate. The Scoopfile is the source of truth for the
current tool selection.

JetBrains Mono Nerd Font comes from the `nerd-fonts` bucket and installs for
the current user. Install Vazirmatn manually from its
[official releases](https://github.com/rastikerdar/vazirmatn/releases) if needed.
Terminal settings use **JetBrainsMono Nerd Font**, your saved color schemes, and keyboard
shortcuts. Machine-specific generated WSL profiles are omitted; Terminal
discovers installed distributions itself.

## macOS / Linux

`macos/Brewfile` lists Homebrew packages. `scripts/install.sh --dry-run`
previews config links; run `scripts/install.sh` to create them. Existing
conflicting configs are left unchanged.
