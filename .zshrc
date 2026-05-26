# Lines configured by zsh-newuser-install
#
# History file location and limits
HISTFILE=~/.zsh.histfile
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase

# History behavior settings
setopt hist_ignore_dups        # Don't record duplicate consecutive commands
setopt hist_ignore_all_dups    # Remove older duplicates as new ones are added
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_space       # Don't record commands that start with a space
setopt hist_reduce_blanks      # Remove superfluous blanks before saving
setopt hist_verify             # Don't execute from history without confirmation
setopt appendhistory           # Add commands to history immediately, not at shell exit
setopt sharehistory            # Share command history between terminal sessions

setopt autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
bindkey '^w' history-search-backward
bindkey '^s' history-search-forward
# End of lines configured by zsh-newuser-install

# Styling
zstyle :compinstall filename "$HOME/.zshrc"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

#autoloads
autoload -Uz tetriscurses
autoload -Uz compinit
compinit -C

alias yazi='SWAYSOCK= yazi'
alias spf='SWAYSOCK= spf'

# Open file manager in current tab with current working directory
function files-widget() {
  zle reset-prompt
yazi
  zle redisplay
}
zle -N files-widget
bindkey '^e' files-widget

function jfsh-widget() {
  zle reset-prompt
  jfsh
  zle redisplay
}
zle -N jfsh-widget
bindkey '^j' jfsh-widget

# ensure_tool "mpv-mpris" "mpv-mpris"

# --- Paths ---
DOTFILES_DIR="$(dirname ${(%):-%N})"  # <- references where this dotfile is
OMP_CONFIG="$DOTFILES_DIR/themes/terminal/emodipt-custom.omp.yaml"
ZSH_MODULES="$DOTFILES_DIR/configs/zsh"
# OMP_CONFIG="~/Dev/terminal-themes/emodipt-custom.omp.yaml"  # <- trial theme config

# --- Exports ---
export GOPROXY=https://proxy.golang.org,direct
export SUDO_PROMPT=$'\a[sudo] password for %p: '
export ALIAE_CONFIG="$DOTFILES_DIR/configs/aliae/aliae.yml"
export TMPDIR=$HOME/.tmp

# --- Zsh Modules ---
source $ZSH_MODULES/inits.zsh
source $ZSH_MODULES/plugins.zsh
source $ZSH_MODULES/functions.zsh

# Clear exit code from startup commands so status segment only shows for actual commands
true



