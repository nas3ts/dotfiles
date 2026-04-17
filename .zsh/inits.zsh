# Conditional Inits
if command -v oh-my-posh >/dev/null 2>&1; then		# <- custom shell theme
	eval "$(oh-my-posh init zsh --config $OMP_CONFIG)"
else
	echo "oh-my-posh is not installed. Skipping oh-my-posh init."
fi

if command -v aliae >/dev/null 2>&1; then		# <- custom alias config	
	eval "$(aliae init zsh)"
#	source $ALIAE_COMP_CONFIG

else
	echo "aliae is not installed. Skipping alias init."
fi

if command -v zoxide >/dev/null 2>&1; then		# <- cooler cd command
	eval "$(zoxide init zsh)"
else
	echo "zoxide is not installed. Skipping zoxide init."
fi

if command -v fzf >/dev/null 2>&1; then			# <- fuzzy finder
	eval "$(fzf --zsh)"
else
	echo "fzf is not installed. Skipping fzf init."
fi
