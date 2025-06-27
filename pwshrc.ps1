$global:autoInstallAll = $false

function Ensure-App {
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

# --- Required Tools Check ---
Ensure-App -CommandName 'oh-my-posh' -WingetId 'JanDeDobbeleer.OhMyPosh'
Ensure-App -CommandName 'aliae'      -WingetId 'aliae.aliae'
Ensure-App -CommandName 'zoxide'     -WingetId 'ajeetdsouza.zoxide'

# --- Paths and Init ---

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Initializations
$ompConfigPath = Join-Path $scriptDir '..\emodipt-custom\emodipt-custom.omp.json'	# <- custom shell theme
oh-my-posh init pwsh --config (Resolve-Path $ompConfigPath) | Invoke-Expression

$aliaeConfigPath = Join-Path $scriptDir '.aliae.yml' 		# <- all aliases here
aliae init pwsh --config (Resolve-Path $aliaeConfigPath) | Invoke-Expression

(zoxide init powershell) -join "`n" | Invoke-Expression
