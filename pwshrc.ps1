# Check and prompt to install tools (y/n/a)

$global:autoInstallAll = $false

function Ensure-Tool {
    param(
        [string]$CommandName,
        [string]$WingetId
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Write-Warning "`"$CommandName`" not found."

        if (-not $global:autoInstallAll) {
            $choice = Read-Host "Install $CommandName? (y)es / (n)o / (a)ll"
            switch ($choice.ToLower()) {
                'y' { }  # continue to install
                'a' {
                    $global:autoInstallAll = $true
                }
                default {
                    Write-Host "skipping $CommandName"
                    return
                }
            }
        }

        Write-Host "installing $CommandName via winget..."
        winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements
    }
}

Ensure-Tool -CommandName 'oh-my-posh' -WingetId 'JanDeDobbeleer.OhMyPosh'
Ensure-Tool -CommandName 'aliae'      -WingetId 'aliae.aliae'
Ensure-Tool -CommandName 'zoxide'     -WingetId 'ajeetdsouza.zoxide'
Ensure-Tool -CommandName 'lsd'	      -WingetId 'lsd-rs.lsd'

# --- Paths and Inits ---

$dotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Conditional Inits

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompConfigPath = Join-Path $dotfilesDir '..\emodipt-custom\emodipt-custom.omp.json'		# <- custom shell theme
    oh-my-posh init pwsh --config (Resolve-Path $ompConfigPath) | Invoke-Expression
} else {
    Write-Warning "oh-my-posh not installed, skipping initialization."
}

if (Get-Command aliae -ErrorAction SilentlyContinue) {
    $aliaeConfigPath = Join-Path $dotfilesDir '.aliae.yml'		# <- custom alias config
    aliae init pwsh --config (Resolve-Path $aliaeConfigPath) | Invoke-Expression
} else {
    Write-Warning "aliae not installed, skipping initialization."
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (zoxide init powershell) -join "`n" | Invoke-Expression		# <- cooler cd command
} else {
    Write-Warning "zoxide not installed, skipping initialization."
}
