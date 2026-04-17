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
compinit

# Check and prompt to install tools (y/n/a)
#
auto_install_all=true

function ensure_tool() {
  local cmd="$1"
  local pkg="$2"

  # Ensure yay (AUR helper) exists
  if ! command -v yay >/dev/null 2>&1; then
    read "choice?Yay is not installed. It’s required for installing AUR packages. Install yay? (y)es | (n)o: "
    case "$choice" in
      y|Y)
        echo "Installing yay..."
        sudo pacman -S --needed --noconfirm base-devel git || return 1
        git clone https://aur.archlinux.org/yay.git /tmp/yay || return 1
        (cd /tmp/yay && makepkg -si --noconfirm) || return 1
        ;;
      *)
        echo "Cannot continue without yay. Skipping."
        return 1
        ;;
    esac
  fi

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd not found."
    if [ "$auto_install_all" = false ]; then
      read "choice?Install $cmd? (y)es | (n)o | (a)ll: "
      case "$choice" in
        a|A) auto_install_all=true ;;
        y|Y) ;;
        *) echo "Skipping $cmd"; return ;;
      esac
    fi
    echo "Installing $cmd with pacman..."
    yay -S --noconfirm "$pkg"
  fi
}

ensure_tool "oh-my-posh" "oh-my-posh"
ensure_tool "aliae" "aliae"
ensure_tool "zoxide" "zoxide"
ensure_tool "lsd" "lsd"
ensure_tool "zinit" "zinit"
ensure_tool "fzf" "fzf"
ensure_tool "glow" "glow"
# ensure_tool "mpv-mpris" "mpv-mpris"

# --- Paths ---
DOTFILES_DIR="$(dirname ${(%):-%N})"  # <- references where this dotfile is
OMP_CONFIG="$DOTFILES_DIR/themes/terminal/emodipt-custom.omp.yaml"
# OMP_CONFIG="~/Dev/terminal-themes/emodipt-custom.omp.yaml"  # <- trial theme config

# --- Exports ---
export GOPROXY=https://proxy.golang.org,direct
export ALIAE_CONFIG="$DOTFILES_DIR/configs/.aliae.yml"

# --- Zsh Modules ---
source $DOTFILES_DIR/.zsh/inits.zsh
source $DOTFILES_DIR/.zsh/plugins.zsh
source $DOTFILES_DIR/.zsh/functions.zsh



