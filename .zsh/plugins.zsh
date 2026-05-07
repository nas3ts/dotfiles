# --- Zsh Plugins ---

# Source zinit if available
if [[ -f /usr/share/zinit/zinit.zsh ]]; then
  source /usr/share/zinit/zinit.zsh
fi

# Load plugins only if zinit is available
if (( $+functions[zinit] )); then
  zinit light zsh-users/zsh-autosuggestions
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

  zinit light zsh-users/zsh-syntax-highlighting
  zinit light marzocchi/zsh-notify
fi
