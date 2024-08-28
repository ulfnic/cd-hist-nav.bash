```bash
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
```
