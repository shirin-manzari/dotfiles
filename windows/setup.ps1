[CmdletBinding()]
param(
	[switch]$DryRun,
	[switch]$ConfigOnly
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/config.ps1')

if (!$ConfigOnly) {
	if ($DryRun) {
		Write-Host 'Would install Scoop if missing, CLI tools, fonts, and Terminal-Icons.'
	} else {
		if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
			throw 'WinGet is required. Install or update App Installer from the Microsoft Store, then retry.'
		}
		if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
			[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
			$installer = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-scoop-" + [guid]::NewGuid() + '.ps1')
			Invoke-WebRequest -UseBasicParsing -Uri 'https://get.scoop.sh' -OutFile $installer
			& $installer
			if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
				throw 'Scoop installation did not complete.'
			}
		}
		& (Join-Path $PSScriptRoot 'Scoopfile.ps1')
		if (!(Get-Module -ListAvailable -Name Terminal-Icons)) {
			if ($PSVersionTable.PSVersion.Major -le 5) {
				[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
				if (!(Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
					Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
				}
			}
			Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
		}
	}
	foreach ($app in @('Google.Chrome', 'Microsoft.VisualStudioCode', 'Microsoft.WindowsTerminal')) {
		if ($DryRun) {
			Write-Host "Would install WinGet app: $app"
			continue
		}
		& winget install --id $app --exact --source winget --no-upgrade --accept-source-agreements --accept-package-agreements --disable-interactivity
		# WinGet reports an already installed package / unavailable upgrade as HRESULTs.
		if ($LASTEXITCODE -notin @(0, -1978335189, -1978335135)) {
			throw "WinGet failed to install $app (exit $LASTEXITCODE)."
		}
	}
}

if (!$ConfigOnly) {
	if ($DryRun) {
		Write-Host 'Would install VS Code extensions from config/vscode/extensions.txt.'
	} else {
		$code = Get-Command code -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
		if (!$code) {
			$code = @(
				(Join-Path $env:LOCALAPPDATA 'Programs/Microsoft VS Code/bin/code.cmd'),
				(Join-Path $env:ProgramFiles 'Microsoft VS Code/bin/code.cmd')
			) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
		}
		if (!$code) { throw 'VS Code CLI was not found after installation. Restart PowerShell and retry.' }
		foreach ($extension in Get-Content (Join-Path $repoRoot 'config/vscode/extensions.txt')) {
			$extension = $extension.Trim()
			if (!$extension -or $extension.StartsWith('#')) { continue }
			& $code --install-extension $extension
			if ($LASTEXITCODE -ne 0) { throw "Could not install VS Code extension: $extension" }
		}
	}
}

$documents = [Environment]::GetFolderPath('MyDocuments')
$repoProfile = Join-Path $repoRoot 'config/powershell/Microsoft.PowerShell_profile.ps1'
foreach ($shell in @('WindowsPowerShell', 'PowerShell')) {
	$target = Join-Path $documents "$shell/Microsoft.PowerShell_profile.ps1"
	$existing = if (Test-Path -LiteralPath $target) { [IO.File]::ReadAllText($target) } else { '' }
	$content = Get-DotfilesProfileContent -Existing $existing -RepoProfile $repoProfile
	Set-DotfilesContent -Path $target -Content $content -DryRun:$DryRun
}

# Include the shared Git config without replacing identity or other local settings.
$gitTarget = Join-Path $env:USERPROFILE '.gitconfig'
$existing = if (Test-Path -LiteralPath $gitTarget) { [IO.File]::ReadAllText($gitTarget) } else { '' }
$gitSource = (Join-Path $repoRoot 'config/git/gitconfig').Replace('\', '/').Replace('"', '\"')
$include = "`n[include]`n`tpath = `"$gitSource`"`n"
if (!$existing.Contains($include.Trim())) {
	Set-DotfilesContent -Path $gitTarget -Content ($existing.TrimEnd() + "`n" + $include) -DryRun:$DryRun
}

$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE '.config' }
$nvimHome = if ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'nvim' } else { Join-Path $env:LOCALAPPDATA 'nvim' }
$microHome = if ($env:MICRO_CONFIG_HOME) { $env:MICRO_CONFIG_HOME } else { Join-Path $configHome 'micro' }
$copies = @(
	@('config/nvim/init.lua', (Join-Path $nvimHome 'init.lua')),
	@('config/micro/settings.json', (Join-Path $microHome 'settings.json')),
	@('config/micro/colorschemes/pastel-comments.micro', (Join-Path $microHome 'colorschemes/pastel-comments.micro')),
	@('config/vscode/settings.json', (Join-Path $env:APPDATA 'Code/User/settings.json'))
)
$terminalStore = Join-Path $env:LOCALAPPDATA 'Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe'
$terminalHome = if (Test-Path -LiteralPath $terminalStore) { Join-Path $terminalStore 'LocalState' } else { Join-Path $env:LOCALAPPDATA 'Microsoft/Windows Terminal' }
$copies += ,@('config/windows-terminal/settings.json', (Join-Path $terminalHome 'settings.json'))
foreach ($copy in $copies) {
	Set-DotfilesContent -Path $copy[1] -Content ([IO.File]::ReadAllText((Join-Path $repoRoot $copy[0]))) -DryRun:$DryRun
}

if ($DryRun) {
	Write-Host 'Preview complete. No packages or settings were changed.'
} else {
	Write-Host 'Setup complete. Restart your terminal. Rerun with -ConfigOnly to refresh copied settings.'
}
