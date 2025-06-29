# --- Auto-install config ---
$global:autoInstallAll = $false

# --- Ensure a tool is installed via winget ---
function Ensure-Tool {
    param (
        [string]$CommandName,
        [string]$WingetId
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Write-Warning "`"$CommandName`" not found."

        if (-not $global:autoInstallAll) {
            $choice = Read-Host "Install $CommandName? (y)es / (n)o / (a)ll"
            switch ($choice.ToLower()) {
                'y' { }  # continue
                'a' { $global:autoInstallAll = $true }
                default {
                    Write-Host "Skipping $CommandName"
                    return
                }
            }
        }

        Write-Host "Installing $CommandName via winget..."
        winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements
    }
}

# --- Install required tools ---
Ensure-Tool -CommandName 'oh-my-posh' -WingetId 'JanDeDobbeleer.OhMyPosh'
Ensure-Tool -CommandName 'aliae'      -WingetId 'JanDeDobbeleer.aliae'
Ensure-Tool -CommandName 'zoxide'     -WingetId 'ajeetdsouza.zoxide'
Ensure-Tool -CommandName 'lsd'        -WingetId 'lsd-rs.lsd'
Ensure-Tool -CommandName 'gsudo'      -WingetId 'gerardog.gsudo'

# --- Paths ---
$dotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ompConfigPath = Join-Path $dotfilesDir '..\emodipt-custom\emodipt-custom.omp.json'
$aliaeConfigPath = Join-Path $dotfilesDir '.aliae.yml'

# --- Initialize tools safely ---
function Initialize-Tool {
    param (
        [string]$Command,
        [string]$Shell = 'pwsh',
        [string]$ConfigPath = $null
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        try {
            $initCmd = if ($ConfigPath) {
                & $Command init $Shell --config (Resolve-Path $ConfigPath)
            } else {
                & $Command init $Shell
            }

            if (-not [string]::IsNullOrWhiteSpace($initCmd)) {
                Invoke-Expression $initCmd
            } else {
                Write-Warning "$Command init output is empty. Skipping execution."
            }
        } catch {
            Write-Warning "Error initializing $Command: $_"
        }
    } else {
        Write-Warning "$Command not installed, skipping initialization."
    }
}

# --- Initialize tools ---
Initialize-Tool -Command 'oh-my-posh' -ConfigPath $ompConfigPath
Initialize-Tool -Command 'aliae' -ConfigPath $aliaeConfigPath

# zoxide is special — doesn't support config param
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    try {
        $zoxideInit = (zoxide init powershell) -join "`n"
        if (-not [string]::IsNullOrWhiteSpace($zoxideInit)) {
            Invoke-Expression $zoxideInit
        } else {
            Write-Warning "zoxide init output is empty. Skipping execution."
        }
    } catch {
        Write-Warning "Error initializing zoxide: $_"
    }
} else {
    Write-Warning "zoxide not installed, skipping initialization."
}
