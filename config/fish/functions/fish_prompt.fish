function fish_prompt
	set -l last_status $status
	set -l arrow_color green
	if test $last_status -ne 0
		set arrow_color red
	end

	set -l arrow '➜'
	if fish_is_root_user
		set arrow '#'
	end

	set_color -o $arrow_color
	printf '%s  ' "$arrow"
	set_color -o cyan
	printf '%s🌸' (prompt_pwd | path basename)
	fish_git_prompt ' git:(%s)'
	set_color normal
	printf ' '
end
