# --- History Config ---
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend  # append to the history file, don't overwrite it

# --- Autocompletion ---
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# --- Auto-install helper ---
auto_install_all=false

ensure_tool() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd not found."
        if [ "$auto_install_all" = false ]; then
            read -p "Install $cmd? (y)es / (n)o / (a)ll: " choice
            case "$choice" in
                a|A) auto_install_all=true ;;
                y|Y) ;;
                *) echo "Skipping $cmd"; return ;;
            esac
        fi
        echo "Installing $cmd with yay..."
        yay -S "$pkg"
    fi
}

ensure_tool "oh-my-posh" "oh-my-posh"
ensure_tool "aliae" "aliae"
ensure_tool "zoxide" "zoxide"
ensure_tool "lsd" "lsd"

# --- Paths ---
DOTFILES_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
export OMP_CONFIG="$DOTFILES_DIR/themes/terminal/emodipt-custom.omp.yaml"
export ALIAE_CONFIG="$DOTFILES_DIR/.aliae.yml"
# export ALIAE_COMP_CONFIG="$DOTFILES_DIR/.aliae/completions/bash"

# --- Conditional Inits ---
if command -v oh-my-posh >/dev/null 2>&1; then
    eval "$(oh-my-posh init bash --config "$OMP_CONFIG")"
else
    echo "oh-my-posh not installed."
fi

if command -v aliae >/dev/null 2>&1; then
    eval "$(aliae init bash)"
    [ -f "$ALIAE_COMP_CONFIG" ] && source "$ALIAE_COMP_CONFIG"
else
    echo "aliae not installed."
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
else
    echo "zoxide not installed."
fi

# --- TMPDIR setup ---
if ! grep -q 'export TMPDIR=\$HOME/tmp' ~/.bashrc; then
    echo "TMPDIR not set in ~/.bashrc."
    read -p "Add 'export TMPDIR=\$HOME/tmp' to ~/.bashrc? [y/N] " resp
    if [[ "$resp" =~ ^[yY]$ ]]; then
        echo 'export TMPDIR=$HOME/tmp' >> ~/.bashrc
        echo "✓ TMPDIR added."
    else
        echo "✗ TMPDIR not added."
    fi
fi

# --- Exports ---
export GOPROXY=https://proxy.golang.org,direct

# --- Optional: syntax highlighting & autosuggestions ---
# These would require bash plugins or tools like `bash-it` or `bash-preexec`, not native


