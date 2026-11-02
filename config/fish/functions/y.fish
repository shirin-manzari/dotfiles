function y --description 'Open Yazi and change to its last directory'
	if not command -q yazi
		printf 'y: yazi is not installed\n' >&2
		return 127
	end

	set -l tmp (mktemp -t yazi-cwd.XXXXXX)
	or return 1
	command yazi $argv --cwd-file="$tmp"
	set -l yazi_status $status

	set -l cwd
	if read -z cwd < "$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
		builtin cd -- "$cwd"
	end

	command rm -f -- "$tmp"
	return $yazi_status
end
