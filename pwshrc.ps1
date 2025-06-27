# --- Paths and Init ---

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Initializations
$ompConfigPath = Join-Path $scriptDir '..\emodipt-custom\emodipt-custom.omp.json'	# <- custom shell theme
oh-my-posh init pwsh --config (Resolve-Path $ompConfigPath) | Invoke-Expression

$aliaeConfigPath = Join-Path $scriptDir '.aliae.yml' 		# <- all aliases here
aliae init pwsh --config (Resolve-Path $aliaeConfigPath) | Invoke-Expression

(zoxide init powershell) -join "`n" | Invoke-Expression
