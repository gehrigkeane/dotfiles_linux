#
# Gehrig Keane: https://github.com/gehrigkeane
#
# References:
#   https://github.com/zdharma/zplugin
#   https://esham.io/2018/02/zsh-profiling

# Patch ZSH word boundaries per https://stackoverflow.com/a/1438523
autoload -U select-word-style
select-word-style bash

#
# Env
#
# TODO:
#   - determine startup order, and populate .zprofile accordingly
#
# ref:
#   TODO
#
export TERM="xterm-256color"
export LESS=-JMQRiFX

# Patch iterm tab titles
# https://github.com/robbyrussell/oh-my-zsh/issues/5700
DISABLE_AUTO_TITLE="true"
# set-window-title() {
#   # /Users/me/foo/bar -> ~/f/bar
#   window_title="\e]0;${${PWD/#"$HOME"/~}/projects/p}\a"
#   echo -ne "$window_title"
# }
# PR_TITLEBAR=''
# set-window-title
# add-zsh-hook precmd set-window-title
function precmd () {
  window_title="\033]0;${PWD##*/}\007"
  echo -ne "$window_title"
}

# Long running commands should print timing information
# https://github.com/unixorn/zsh-quickstart-kit/blob/master/zsh/.zshrc
REPORTTIME=10
TIMEFMT="%U user %S system %P cpu %*Es total"

#
# Plugins
#

### Added by Zinit's installer
source ~/.zinit/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit installer's chunk

# zinit ice wait atinit"zpcompinit; zpcdreplay"                               # https://github.com/zdharma/fast-syntax-highlighting
zinit light zdharma/fast-syntax-highlighting

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'                                          # https://github.com/zsh-users/zsh-autosuggestions
# zinit ice wait atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zinit light djui/alias-tips                                                   # https://github.com/djui/alias-tips
zinit light gehrigkeane/zsh_plugins

#
# Oh My Zsh Plugins (via zinit)
#

# completions are failing somewhere
# https://github.com/eddiezane/lunchy/issues/57#issuecomment-121173592
autoload bashcompinit
bashcompinit

zinit snippet OMZ::lib/key-bindings.zsh
zinit snippet OMZ::lib/history.zsh
zinit snippet OMZ::lib/git.zsh
zinit snippet OMZ::plugins/brew/brew.plugin.zsh                                 # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/brew
zinit ice as"completion"; zinit snippet OMZ::plugins/docker-compose                      # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/docker
zinit ice as"completion"; zinit snippet OMZ::plugins/docker                            # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/docker
zinit snippet OMZ::plugins/asdf/asdf.plugin.zsh                                 # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/asdf
zinit snippet OMZ::plugins/fasd/fasd.plugin.zsh                                 # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/fasd
zinit snippet OMZ::plugins/git/git.plugin.zsh                                   # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/git
zinit ice as"completion"; zinit snippet OMZ::plugins/golang                              # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/golang
# zinit snippet OMZ::plugins/pyenv/pyenv.plugin.zsh                               # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/pyenv
# zinit snippet OMZ::plugins/pipenv/pipenv.plugin.zsh

#
# Themes
#

# Spaceship Theme
# zplug denysdovhan/spaceship-prompt, use:spaceship.zsh, from:github, as:theme

# Powerlevel 9k
# https://github.com/bhilburn/powerlevel9k#customizing-prompt-segments
# https://github.com/bhilburn/powerlevel9k/wiki/Stylizing-Your-Prompt
# POWERLEVEL9K_MODE='awesome-patched'
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=3
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='black'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='072'
POWERLEVEL9K_EXECUTION_TIME_ICON='Δ'
POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=none
POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_COLOR=002
POWERLEVEL9K_BACKGROUND_JOBS_ICON='⇶'
POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='⇣'
POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='⇡'
POWERLEVEL9K_SHOW_CHANGESET=true

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir dir_writable vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs history time)
# zplug "romkatv/powerlevel10k", use:powerlevel10k.zsh-theme
zinit ice depth=1; zinit light romkatv/powerlevel10k

#
# En fin
#

setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify

# Patch ZSH key bindings per https://stackoverflow.com/a/29403520
bindkey "^U" backward-kill-line
bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

#
# Source `.shell*` configuration
#

source ~/.profile

# In the event of weird up and down behavior try these:
# bindkey '^[[A' up-line-or-search
# bindkey '^[[B' down-line-or-search

# Auto-init pyenv https://github.com/pyenv/pyenv#homebrew-on-mac-os-x
# The following help with python installations: CFLAGS="-I$(xcrun --show-sdk-path)/usr/include" PYTHON_CONFIGURE_OPTS="--enable-unicode=ucs4"
# eval "$(pyenv init -)"  # replaced with pyenv oh-my-zsh plugin
# eval "$(pipenv --completion)"  # replaced with pipenv oh-my-zsh plugin
# eval "$(rbenv init -)"  # replaced with rbenv from oh-my-zsh plugin

# NVM is painfully slow...
function init_nvm(){
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion
}
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
