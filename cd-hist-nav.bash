#!/usr/bin/env bash


if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	cat <<-'HelpDoc' >&2
		A sourceable BASH script for navigating cd history at an interactive BASH prompt using
		left and right arrow keys combined with a command key.

		ENVIRONMENT
		  CD_HIST_NAV__PS1_LINES     default: 1, number of lines used by PS1 prompt
		  CD_HIST_NAV__COMMAND_KEY   default: ctrl, combo key to use with left/right arrow
		                             accepted values: alt, ctrl, shift
		  HISTCONTROL                Ignore space combined with the existing value so binds can
		                             avoid poluting .bash_history

		NAMESPACE
		  Variables beginning with CD_HIST_NAV__ and functions beginning with cd_hist_nav__ are
		  used in the global context.

		EXAMPLE
		  source cd-hist-nav.bash
		  cd_hist_nav__init

	HelpDoc
fi



cd_hist_nav__init() {
	# Prepare global variables
	CD_HIST_NAV__HISTORY_ARR=("$PWD")
	CD_HIST_NAV__HISTORY_INDEX=0
	: ${CD_HIST_NAV__PS1_LINES:=1}
	: ${CD_HIST_NAV__COMMAND_KEY:='ctrl'}
	CD_HIST_NAV__CLEAR_FROM_PREV_PS1_SEQ=
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

	bind '"'${combo_to_seq[${CD_HIST_NAV__COMMAND_KEY}_left]}'":" \C-u cd_hist_nav back\n"'
	bind '"'${combo_to_seq[${CD_HIST_NAV__COMMAND_KEY}_right]}'":" \C-u cd_hist_nav forward\n"'


	# Build escape sequences for moving the cursor to the line the previous prompt began
	for (( i = 0; i < CD_HIST_NAV__PS1_LINES; i++ )); do
		CD_HIST_NAV__CLEAR_FROM_PREV_PS1_SEQ+='\033[A'
	done


	# Append moving cursor to start of line and clear to end of screen
	CD_HIST_NAV__CLEAR_FROM_PREV_PS1_SEQ+='\033[G\e[0J'
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
	printf "${CD_HIST_NAV__CLEAR_FROM_PREV_PS1_SEQ}"

	if [[ $1 == 'back' ]]; then
		if (( CD_HIST_NAV__HISTORY_INDEX > 0 )); then
			builtin cd -- "${CD_HIST_NAV__HISTORY_ARR[$(( --CD_HIST_NAV__HISTORY_INDEX ))]}"
		fi
	elif [[ $1 == 'forward' ]]; then
		if (( CD_HIST_NAV__HISTORY_INDEX < ${#CD_HIST_NAV__HISTORY_ARR[@]} - 1 )); then
			builtin cd -- "${CD_HIST_NAV__HISTORY_ARR[$(( ++CD_HIST_NAV__HISTORY_INDEX ))]}"
		fi
	fi
}



