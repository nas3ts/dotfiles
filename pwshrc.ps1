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
Ensure-Tool -CommandName 'aliae'      -WingetId 'JanDeDobbeleer.aliae'
Ensure-Tool -CommandName 'zoxide'     -WingetId 'ajeetdsouza.zoxide'
Ensure-Tool -CommandName 'lsd'	      -WingetId 'lsd-rs.lsd'
Ensure-Tool -CommandName 'gsudo'      -WingetId 'gerardog.gsudo'

# --- Paths and Inits ---

$dotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Conditional Inits
function Initialize-Tool {
    param (
        [string]$Command,
        [string]$ConfigPath = $null,
        [string]$Shell = 'pwsh'
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        if ($ConfigPath) {
            $resolvedPath = Resolve-Path $ConfigPath
            Invoke-Expression "$Command init $Shell --config $resolvedPath"
        } else {
            Invoke-Expression "$Command init $Shell"
        }
    } else {
        Write-Warning "$Command not installed, skipping initialization."
    }
}

# Define config paths
$ompConfigPath = Join-Path $dotfilesDir '..\emodipt-custom\emodipt-custom.omp.json'
$aliaeConfigPath = Join-Path $dotfilesDir '.aliae.yml'

# Initialize tools
Initialize-Tool -Command 'oh-my-posh' -ConfigPath $ompConfigPath
Initialize-Tool -Command 'aliae' -ConfigPath $aliaeConfigPath

# zoxide is special — it returns a script block instead of taking a config
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (zoxide init powershell) -join "`n" | Invoke-Expression
} else {
    Write-Warning "zoxide not installed, skipping initialization."
}
