function Set-DotfilesContent {
	param([string]$Path, [string]$Content, [switch]$DryRun)
	$existing = if (Test-Path -LiteralPath $Path) { [IO.File]::ReadAllText($Path) } else { $null }
	if ($existing -ceq $Content) {
		Write-Host "Already configured: $Path"
		return
	}
	if ($DryRun) {
		Write-Host "Would back up existing file and configure: $Path"
		return
	}
	New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
	if (Test-Path -LiteralPath $Path) {
		if ((Get-Item -LiteralPath $Path -Force).LinkType) {
			throw "Existing link left unchanged: $Path. Resolve it before retrying."
		}
		$backup = "$Path.dotfiles-backup-$(Get-Date -Format 'yyyyMMddHHmmssfff')-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
		Copy-Item -LiteralPath $Path -Destination $backup -ErrorAction Stop
		Write-Host "Backed up: $backup"
	}
	[IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
	Write-Host "Configured: $Path"
}

function Get-DotfilesProfileContent {
	param([string]$Existing, [string]$RepoProfile)
	# Replace our managed block on reruns, and retire the original prompt lines.
	$text = [regex]::Replace($Existing, '(?ms)^# BEGIN dotfiles\r?\n.*?^# END dotfiles\r?\n?', '')
	$text = [regex]::Replace($text, '(?m)^oh-my-posh init [^\r\n]*\r?\n?', '')
	$text = [regex]::Replace($text, '(?m)^Import-Module -Name Terminal-Icons\s*\r?\n?', '')
	$loader = ". '" + $RepoProfile.Replace("'", "''") + "'"
	# Also migrate the previously documented single-line loader.
	$text = [regex]::Replace($text, '(?m)^' + [regex]::Escape($loader) + '\r?\n?', '')
	$prefix = if ($text.TrimEnd()) { $text.TrimEnd() + "`n`n" } else { '' }
	return $prefix + "# BEGIN dotfiles`n$loader`n# END dotfiles`n"
}
