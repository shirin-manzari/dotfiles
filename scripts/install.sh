#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--dry-run]\n' "$0"
}

dry_run=false
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
conflicts=0

link_config() {
  local source="$repo_root/$1"
  local target="$2"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
    printf 'Already linked: %s\n' "$target"
  elif [[ -e "$target" || -L "$target" ]]; then
    printf 'Conflict (left unchanged): %s\n' "$target" >&2
    conflicts=$((conflicts + 1))
  elif [[ "$dry_run" == true ]]; then
    printf 'Would link: %s -> %s\n' "$target" "$source"
  else
    mkdir -p -- "$(dirname -- "$target")"
    ln -s -- "$source" "$target"
    printf 'Linked: %s -> %s\n' "$target" "$source"
  fi
}

link_config config/git/gitconfig "$HOME/.gitconfig"
link_config config/fish/config.fish "$config_home/fish/config.fish"
link_config config/fish/conf.d/preferences.fish "$config_home/fish/conf.d/preferences.fish"
link_config config/fish/conf.d/rustup.fish "$config_home/fish/conf.d/rustup.fish"
link_config config/fish/conf.d/fish_frozen_theme.fish "$config_home/fish/conf.d/fish_frozen_theme.fish"
link_config config/fish/functions/fish_prompt.fish "$config_home/fish/functions/fish_prompt.fish"
link_config config/fish/functions/y.fish "$config_home/fish/functions/y.fish"
link_config config/kitty/kitty.conf "$config_home/kitty/kitty.conf"
link_config config/kitty/theme.conf "$config_home/kitty/theme.conf"
link_config config/micro/settings.json "$config_home/micro/settings.json"
link_config config/micro/colorschemes/pastel-comments.micro "$config_home/micro/colorschemes/pastel-comments.micro"
link_config config/nvim/init.lua "$config_home/nvim/init.lua"

case "$(uname -s)" in
	Darwin) vscode_user_dir="$HOME/Library/Application Support/Code/User" ;;
	Linux) vscode_user_dir="$config_home/Code/User" ;;
	*) vscode_user_dir=''; printf 'Skipping VS Code settings on this platform.\n' ;;
esac
if [[ -n "$vscode_user_dir" ]]; then
	link_config config/vscode/settings.json "$vscode_user_dir/settings.json"
fi

if [[ "$conflicts" -gt 0 ]]; then
  printf '%s conflict(s); move or back up these files before retrying.\n' "$conflicts" >&2
  exit 1
fi
