# Set up Homebrew once, before config.fish initializes optional tools.
if test -x /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv fish)
else if command -q brew
	eval (brew shellenv fish)
end

if status is-interactive
	set -g fish_greeting

	# Built-in Git prompt: branch and tracked-file changes.
	set -g __fish_git_prompt_showdirtystate 1
	set -g __fish_git_prompt_color blue
	set -g __fish_git_prompt_color_branch red
	set -g __fish_git_prompt_color_dirtystate yellow
	set -g __fish_git_prompt_color_stagedstate yellow
	set -g __fish_git_prompt_char_dirtystate '✗'
	set -g __fish_git_prompt_char_stagedstate '+'
end
