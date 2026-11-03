$ErrorActionPreference = 'Stop'
$windowsRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $windowsRoot 'lib/config.ps1')

function Assert-True {
	param([bool]$Condition, [string]$Message)
	if (!$Condition) { throw $Message }
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-config-test-" + [guid]::NewGuid())
$target = Join-Path $testRoot 'nested/settings.json'
Set-DotfilesContent -Path $target -Content 'new' -DryRun
Assert-True (!(Test-Path -LiteralPath $testRoot)) 'Dry run created files.'

Set-DotfilesContent -Path $target -Content 'original'
Set-DotfilesContent -Path $target -Content 'updated'
$backups = @(Get-ChildItem -LiteralPath (Split-Path $target) -Filter '*.dotfiles-backup-*')
Assert-True ($backups.Count -eq 1) 'Replacing a file must create one backup.'
Assert-True ([IO.File]::ReadAllText($backups[0].FullName) -ceq 'original') 'Backup did not preserve original content.'
Set-DotfilesContent -Path $target -Content 'updated'
Assert-True (@(Get-ChildItem -LiteralPath (Split-Path $target) -Filter '*.dotfiles-backup-*').Count -eq 1) 'Rerun created an unnecessary backup.'

$repoProfile = Join-Path $testRoot "repo with spaces and 'quotes'/profile.ps1"
$original = "function custom-tool { 'keep me' }`r`noh-my-posh init pwsh --config 'old.json' | Invoke-Expression`r`nImport-Module -Name Terminal-Icons`r`n"
$first = Get-DotfilesProfileContent -Existing $original -RepoProfile $repoProfile
$second = Get-DotfilesProfileContent -Existing $first -RepoProfile $repoProfile
Assert-True ($first -ceq $second) 'Profile installation is not repeatable.'
Assert-True ($first.Contains("function custom-tool { 'keep me' }")) 'Custom profile function was lost.'
Assert-True (!$first.Contains('old.json')) 'Old prompt initialization was retained.'
$tokens = $null
$parseErrors = $null
[Management.Automation.Language.Parser]::ParseInput($first, [ref]$tokens, [ref]$parseErrors) | Out-Null
Assert-True ($parseErrors.Count -eq 0) 'Generated profile does not parse with quoted paths.'
$loader = ". '" + $repoProfile.Replace("'", "''") + "'`n"
$migrated = Get-DotfilesProfileContent -Existing $loader -RepoProfile $repoProfile
Assert-True ($migrated -ceq (Get-DotfilesProfileContent -Existing '' -RepoProfile $repoProfile)) 'Old loader was duplicated.'

# Exercise the actual entry point without installing or writing live settings.
$preview = & (Join-Path $windowsRoot 'setup.ps1') -DryRun 6>&1 | Out-String
Assert-True ($preview.Contains('Google.Chrome')) 'Chrome is missing from setup.'
Assert-True ($preview.Contains('Microsoft.VisualStudioCode')) 'VS Code is missing from setup.'
Assert-True ($preview.Contains('Preview complete.')) 'Setup preview did not finish.'

Write-Host "All config checks passed. Temporary fixtures: $testRoot"
