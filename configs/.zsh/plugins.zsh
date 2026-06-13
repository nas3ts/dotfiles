# --- Zsh Plugins ---
# zinit is sourced by each machine's ~/.zshrc at its platform-specific path.
# This file only loads plugins if zinit is available.

if (( $+functions[zinit] )); then
  zinit light zsh-users/zsh-autosuggestions
  fpath=(~/.zsh/zsh-completions $fpath)

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

  zinit ice wait'!0' lucid
  zinit light zsh-users/zsh-syntax-highlighting
fi
