# Lines configured by zsh-newuser-install
#
# History file location and limits
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

# History behavior settings
setopt hist_ignore_dups        # Don't record duplicate consecutive commands
setopt hist_ignore_all_dups    # Remove older duplicates as new ones are added
setopt hist_ignore_space       # Don't record commands that start with a space
setopt hist_reduce_blanks      # Remove superfluous blanks before saving
setopt hist_verify             # Don't execute from history without confirmation
setopt inc_append_history      # Add commands to history immediately, not at shell exit
setopt share_history           # Share command history between terminal sessions

setopt autocd beep extendedglob nomatch
bindkey -e
# End of lines configured by zsh-newuser-install

zstyle :compinstall filename '/home/nasets/.zshrc'

#autoloads
autoload -Uz tetriscurses
autoload -Uz compinit
compinit

# Check and prompt to install tools (y/n/a)
#
auto_install_all=false

function ensure_tool() {
  local cmd="$1"
  local pkg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd not found."
    if [ "$auto_install_all" = false ]; then
      read "choice?Install $cmd? (y)es / (n)o / (a)ll: "
      case "$choice" in
        a|A) auto_install_all=true ;;
        y|Y) ;;
        *) echo "Skipping $cmd"; return ;;
      esac
    fi
    echo "Installing $cmd with pacman..."
    yay -S "$pkg"
  fi
}

ensure_tool "oh-my-posh" "oh-my-posh"
ensure_tool "aliae" "aliae"
ensure_tool "zoxide" "zoxide"
ensure_tool "lsd" "lsd"

# --- Paths and Inits ---
#
DOTFILES_DIR="$(dirname ${(%):-%N})"  # <- references where this dotfile is
OMP_CONFIG="$DOTFILES_DIR/../emodipt-custom/emodipt-custom.omp.yaml"
ALIAE_CONFIG="$DOTFILES_DIR/.aliae.yml"

# Conditional Inits
if command -v oh-my-posh >/dev/null 2>&1; then		# <- custom shell theme
	eval "$(oh-my-posh init zsh --config $OMP_CONFIG)"
else
	echo "oh-my-posh is not installed. Skipping oh-my-posh init."
fi

if command -v aliae >/dev/null 2>&1; then		# <- custom alias config	
	eval "$(aliae init zsh)"
else
	echo "aliae is not installed. Skipping alias init."
fi


if command -v zoxide >/dev/null 2>&1; then		# <- cooler cd command
	eval "$(zoxide init zsh)"
else
	echo "zoxide is not installed. Skipping zoxide init."
fi

if ! grep -q 'export TMPDIR=\$HOME/tmp' ~/.zshrc; then		# <- TMPDIR init
  echo "TMPDIR not set in ~/.zshrc."
  read "resp?Do you want to add 'export TMPDIR=\$HOME/tmp' to your ~/.zshrc? [y/N] "
  if [[ "$resp" == [yY] ]]; then
    echo 'export TMPDIR=$HOME/tmp' >> ~/.zshrc
    echo "\uf00c TMPDIR added to ~/.zshrc"
  else
    echo "\uf00d TMPDIR not added."
  fi
fi



# --- Exports ---
#
export GOPROXY=https://proxy.golang.org,direct
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# --- zsh syntax highlighting and autosuggestion configs ---
#
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fpath=(~/.zsh/zsh-completions /usr/local/share/zsh/site-functions /usr/share/zsh/site-functions /usr/share/zsh/functions/Calendar /usr/share/zsh/functions/Chpwd /usr/share/zsh/functions/Completion /usr/share/zsh/functions/Completion/Base /usr/share/zsh/functions/Completion/Linux /usr/share/zsh/functions/Completion/Unix /usr/share/zsh/functions/Completion/X /usr/share/zsh/functions/Completion/Zsh /usr/share/zsh/functions/Exceptions /usr/share/zsh/functions/MIME /usr/share/zsh/functions/Math /usr/share/zsh/functions/Misc /usr/share/zsh/functions/Newuser /usr/share/zsh/functions/Prompts /usr/share/zsh/functions/TCP /usr/share/zsh/functions/VCS_Info /usr/share/zsh/functions/VCS_Info/Backends /usr/share/zsh/functions/Zftp /usr/share/zsh/functions/Zle)


typeset -A ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES=(
  'default'             'fg=#C0C0C0'           # Default color for most things (commands, arguments, etc.)
  'command'             'fg=#E06C75'           # Pinkish red for recognized commands
  'argument'            'fg=#F3C267'           # Yellow for arguments
  'option'              'fg=#61AFEF'           # Cyan for options (e.g., -a, --help)
  'path'                'fg=#58A6FF'           # Softer blue for file paths
  'number'              'fg=#61AFEF'           # Blue for numbers (same as path)
  'reserved-word'       'fg=#E06C75'           # Red for reserved words like `if`, `for`, etc.
  'error'               'fg=#E06C75,bold'      # Bold red for unrecognized input (errors)
  'unknown-command'     'fg=#E06C75'           # Red for unknown commands
)
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
