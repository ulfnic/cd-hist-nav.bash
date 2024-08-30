#!/usr/bin/env bash


cd_hist_nav__help_doc() {
	cat <<-'HelpDoc' >&2
		A sourceable BASH script for navigating cd history at an interactive BASH prompt using
		left and right arrow keys combined with a command key.

		ENVIRONMENT
		  CD_HIST_NAV__COMMAND_KEY   default: ctrl, combo key to use with left/right arrow
		                             accepted values: alt, ctrl, shift
		  HISTCONTROL                Ignore space combined with the existing value so binds can
		                             avoid poluting .bash_history

		NAMESPACE
		  Variables beginning with CD_HIST_NAV__ and functions beginning with cd_hist_nav__ are
		  used in the global context.

		EXAMPLE
		  source cd-hist-nav.bash

	HelpDoc
}



cd_hist_nav__init() {
	# Prepare global variables
	CD_HIST_NAV__HISTORY_ARR=("$PWD")
	CD_HIST_NAV__HISTORY_INDEX=0
	: ${CD_HIST_NAV__COMMAND_KEY:='ctrl'}

	CD_NAV_TOOLS__MUTLILINE_PS1=
	[[ $PS1 == *'\n'* ]] && CD_NAV_TOOLS__MUTLILINE_PS1=1

	[[ $HISTCONTROL == 'ignoredups' ]] && HISTCONTROL='ignoreboth' || HISTCONTROL='ignorespace'


	# Apply user specified keybinds
	local -A combo_to_seq=(
		['alt_left']='\e[1;3D'
		['alt_right']='\e[1;3C'
		['ctrl_left']='\e[1;5D'
		['ctrl_right']='\e[1;5C'
		['shift_left']='\e[1;2D'
		['shift_right']='\e[1;2C'
	)

	[[ ${combo_to_seq[${CD_HIST_NAV__COMMAND_KEY}_left]} ]] || { printf '%s%q\n' 'cd_hist_nav: err, bad combo key: ' "$CD_HIST_NAV__COMMAND_KEY" >&2; return 1; }

	bind '"'${combo_to_seq[${CD_HIST_NAV__COMMAND_KEY}_left]}'":" \C-u cd_hist_nav b\n"'
	bind '"'${combo_to_seq[${CD_HIST_NAV__COMMAND_KEY}_right]}'":" \C-u cd_hist_nav f\n"'
}



cd() {
	# Shim cd so changes to the current directory can be stored in history
	local prev_pwd=$PWD
	builtin cd "$@"

	if [[ $prev_pwd != $PWD ]]; then
		# Trim history if there's a fork
		if (( CD_HIST_NAV__HISTORY_INDEX < ${#CD_HIST_NAV__HISTORY_ARR[@]} - 2 )); then
			CD_HIST_NAV__HISTORY_ARR=("${CD_HIST_NAV__HISTORY_ARR[@]:0:$(( CD_HIST_NAV__HISTORY_INDEX + 1 ))}")
		fi

		# Append new path to history
		CD_HIST_NAV__HISTORY_ARR[$(( ++CD_HIST_NAV__HISTORY_INDEX ))]=$PWD
	fi
}



cd_hist_nav() {
	local cmd=" cd_hist_nav $1"
	cd_nav_tools__home_cursor "${#cmd}"

	if [[ $1 == 'b' ]]; then
		if (( CD_HIST_NAV__HISTORY_INDEX > 0 )); then
			builtin cd -- "${CD_HIST_NAV__HISTORY_ARR[$(( --CD_HIST_NAV__HISTORY_INDEX ))]}"
		fi
	elif [[ $1 == 'f' ]]; then
		if (( CD_HIST_NAV__HISTORY_INDEX < ${#CD_HIST_NAV__HISTORY_ARR[@]} - 1 )); then
			builtin cd -- "${CD_HIST_NAV__HISTORY_ARR[$(( ++CD_HIST_NAV__HISTORY_INDEX ))]}"
		fi
	fi
}



cd_nav_tools__home_cursor() {
	local \
		cmd_len=$1 \
		prompt_orig=$PS1 \
		IFS prompt_plain prompt_try parent_noglob_set prompt_lines_last_index i prompt_len prompt_distance i2


	# Find the plain character length of the interpreted PS1 with okay-ish accuracy
	while [[ $prompt_orig ]]; do
		prompt_plain+=${prompt_orig%%\\[e[]*}
		prompt_try=${prompt_orig#*\\]}
		[[ $prompt_orig == "$prompt_try" ]] && break
		prompt_orig=$prompt_try
	done
	prompt_plain=${prompt_plain@P}


	# Move the cursor up a line till it's at the beginning of the previous prompt mindful of line wrapping


	# If PS1 doesn't contain newlines handle it cheaply
	if [[ ! $CD_NAV_TOOLS__MUTLILINE_PS1 ]]; then
		prompt_distance=$(( ( ${#prompt_plain} + cmd_len - 1 ) / COLUMNS ))
		printf '\e[%dA' "$prompt_distance"

		# Clear from cursor to end of terminal
		printf '\e[0J'
		return
	fi


	# Handle PS1 containing newlines
	prompt_plain=${prompt_plain//$'\r'/}


	shopt -q -o noglob && parent_noglob_set=1
	[[ $parent_noglob_set ]] || set -f
	IFS=$'\n'
	local -a prompt_lines=( $prompt_plain )
	[[ $parent_noglob_set ]] || set +f
	prompt_lines_last_index=$(( ${#prompt_lines[@]} - 1 ))


	for (( i = 0; i <= prompt_lines_last_index; i++ )); do
		prompt_len=${#prompt_lines[i]}

		if [[ $i == "$prompt_lines_last_index" ]]; then
			prompt_len=$(( prompt_len + cmd_len ))
		fi

		prompt_distance=$(( ( prompt_len - 1 ) / COLUMNS ))
		printf '\e[%dA' "$prompt_distance"
	done

	# Clear from cursor to end of terminal
	printf '\e[0J'
}



if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	cd_hist_nav__help_doc
else
	cd_hist_nav__init
fi



