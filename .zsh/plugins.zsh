# --- Zsh Plugins ---

if command -v zinit >/dev/null 2>&1; then
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting

  typeset -A ZSH_HIGHLIGHT_STYLES

  ZSH_HIGHLIGHT_STYLES=(
    'default'             'fg=#C0C0C0'
    'command'             'fg=#E06C75'
    'argument'            'fg=#F3C267'
    'option'              'fg=#61AFEF'
    'path'                'fg=#58A6FF'
    'number'              'fg=#61AFEF'
    'reserved-word'       'fg=#E06C75'
    'error'               'fg=#E06C75,bold'
    'unknown-command'     'fg=#E06C75'
  )
fi
