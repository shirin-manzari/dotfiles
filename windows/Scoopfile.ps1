# Curated CLI tools and fonts, like macos/Brewfile. Edit the lists below.
# Requires Scoop. Run from the repo root: .\windows\Scoopfile.ps1
$packages = @(
	# Shell prompt
	'oh-my-posh'

	# Archives
	'7zip'

	# Navigation, search, and file viewing
	'ripgrep'
	'fd'
	'bat'
	'yazi'

	# Editors
	'neovim'
	'micro'

	# System monitoring
	'btop'

	# Development
	'git'
	'gh'
	'gcc'

	# JavaScript
	'nodejs-lts'
	'pnpm'

	# Python
	'uv'

)

foreach ($package in $packages) {
	scoop install $package
	if ($LASTEXITCODE -ne 0) {
		throw "Scoop failed to install $package."
	}
}

# Terminal font. Add the font bucket after Git is installed.
$buckets = @(scoop bucket list)
if ($LASTEXITCODE -ne 0) {
	throw 'Could not list Scoop buckets.'
}
if ($buckets.Name -notcontains 'nerd-fonts') {
	scoop bucket add nerd-fonts
	if ($LASTEXITCODE -ne 0) {
		throw 'Could not add the nerd-fonts bucket.'
	}
}

scoop install nerd-fonts/JetBrainsMono-NF
if ($LASTEXITCODE -ne 0) {
	throw 'Scoop failed to install JetBrains Mono Nerd Font.'
}
