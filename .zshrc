export DISABLE_ADVCP_MESSAGE=1
export DISABLE_LSD_MESSAGE=1
export DISABLE_BAT_MESSAGE=1
export DISABLE_WINE_MESSAGE=1
export DISABLE_NVIM_MESSAGE=1
export DISABLE_DYSK_MESSAGE=1

# Lines configured by zsh-newuser-install

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
# The following lines were added by compinstall
zstyle :compinstall filename '/home/nasets/.zshrc'

#autoloads
autoload -Uz compinit
compinit
# End of lines added by compinstall
autoload -Uz tetriscurses

# aliases
alias tetris="tetriscurses"
alias c="clear"
alias x="exit"
alias ff="fastfetch"

# Conditional alias for Neovim (v)
if command -v nvim >/dev/null 2>&1; then
    alias v="nvim"
else
    alias v="nano"
    if [[ -z "$DISABLE_NVIM_MESSAGE" ]]; then
        echo "nvim is not installed. Using 'nano' as fallback."
        echo "To disable this message, set the DISABLE_NVIM_MESSAGE environment variable."
    fi
fi

# Conditional alias for Dysk (df)
if command -v dysk >/dev/null 2>&1; then
    alias df="dysk"
else
    alias df="df -h"
    if [[ -z "$DISABLE_DYSK_MESSAGE" ]]; then
        echo "dysk is not installed. Using 'df -h' as fallback."
        echo "To disable this message, set the DISABLE_DYSK_MESSAGE environment variable."
    fi
fi

if command -v advcp >/dev/null 2>&1 && command -v advmv >/dev/null 2>&1; then
  # Use safe wrappers to avoid replacing system cp/mv
  alias cpg='advcp -g'
  alias mvg='advmv -g'
  # Optionally override cp/mv (use with caution)
  alias cp='advcp -g'
  alias mv='advmv -g'
else
  # Fallbacks
  alias cp='cp -v'
  alias mv='mv -v'
  if [[ -z "$DISABLE_ADVCP_MESSAGE" ]]; then
    echo "advcpmv not found; using default cp/mv. Install from https://github.com/jarun/advcpmv"
    echo "Set DISABLE_ADVCP_MESSAGE=1 to silence."
  fi
fi

# Check if lsd is installed
if command -v lsd >/dev/null 2>&1; then
    alias ls="lsd"
    alias la="lsd -a"
    alias l="lsd -la"
    alias ll="lsd -l"
    alias lt="lsd --tree"
else
    # Alias ls to the default ls if lsd is not installed
    alias ls="ls --color=auto"
fi

# Check if bat is installed
if command -v bat >/dev/null 2>&1; then
    alias cat="bat --color=always"
else
    # Print the installation message if bat is not installed
    if [[ -z "$DISABLE_BAT_MESSAGE" ]]; then
        echo "bat is not installed. To install bat, run:"
        echo "  sudo apt install bat     # Debian/Ubuntu"
        echo "  sudo pacman -S bat       # Arch/Manjaro"
        echo "  or visit https://github.com/sharkdp/bat"
        echo "To disable this message, set the DISABLE_BAT_MESSAGE environment variable."
    fi

    # Alias cat to default cat if bat is not installed
    alias cat="cat"
fi

# Check if wine is installed
if command -v wine >/dev/null 2>&1; then
    alias cmd="wine cmd"
else
    # Print the installation message if wine is not installed
    if [[ -z "$DISABLE_WINE_MESSAGE" ]]; then
        echo "wine is not installed. To install wine, run:"
        echo "  sudo apt install wine     # Debian/Ubuntu"
        echo "  sudo pacman -S wine       # Arch/Manjaro"
        echo "  or visit https://www.winehq.org"
        echo "To disable this message, set the DISABLE_WINE_MESSAGE environment variable."
    fi

    # Alias cmd to a no-op or a safe fallback
    alias cmd="echo 'wine is not installed: cmd unavailable'"
fi

alias zl="zoxide query --list"

eval "$(zoxide init zsh)"

eval "$(oh-my-posh init zsh --config ~/Dev/emodipt-custom/emodipt-custom.omp.json)"
export GOPROXY=https://proxy.golang.org,direct

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fpath=(~/.zsh/zsh-completions /usr/local/share/zsh/site-functions /usr/share/zsh/site-functions /usr/share/zsh/functions/Calendar /usr/share/zsh/functions/Chpwd /usr/share/zsh/functions/Completion /usr/share/zsh/functions/Completion/Base /usr/share/zsh/functions/Completion/Linux /usr/share/zsh/functions/Completion/Unix /usr/share/zsh/functions/Completion/X /usr/share/zsh/functions/Completion/Zsh /usr/share/zsh/functions/Exceptions /usr/share/zsh/functions/MIME /usr/share/zsh/functions/Math /usr/share/zsh/functions/Misc /usr/share/zsh/functions/Newuser /usr/share/zsh/functions/Prompts /usr/share/zsh/functions/TCP /usr/share/zsh/functions/VCS_Info /usr/share/zsh/functions/VCS_Info/Backends /usr/share/zsh/functions/Zftp /usr/share/zsh/functions/Zle)

# Customize syntax highlighting colors to match the terminal theme
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

# Check if TMPDIR is already set in ~/.zshrc
if ! grep -q 'export TMPDIR=\$HOME/tmp' ~/.zshrc; then
  echo "TMPDIR not set in ~/.zshrc."
  read "resp?Do you want to add 'export TMPDIR=\$HOME/tmp' to your ~/.zshrc? [y/N] "
  if [[ "$resp" == [yY] ]]; then
    echo 'export TMPDIR=$HOME/tmp' >> ~/.zshrc
    echo "\uf00c TMPDIR added to ~/.zshrc"
  else
    echo "\uf00d TMPDIR not added."
  fi
fi

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

