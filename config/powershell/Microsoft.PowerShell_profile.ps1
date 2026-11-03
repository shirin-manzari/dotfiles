if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config (Join-Path $PSScriptRoot 'dracula.omp.json') | Invoke-Expression
}
if (Get-Module -ListAvailable -Name Terminal-Icons) {
	Import-Module -Name Terminal-Icons
}
