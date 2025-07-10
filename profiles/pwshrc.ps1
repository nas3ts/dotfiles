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
$dotfilesDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ompConfigPath = Join-Path $dotfilesDir 'themes\terminal\emodipt-custom.omp.yaml'
$aliaeConfigPath = Join-Path $dotfilesDir 'configs\.aliae.yml'
$aliaeCompletionPath = Join-Path $dotfilesDir '.aliae\completions\pwsh.ps1'

# --- Initialize tools ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        $resolvedPath = Resolve-Path $ompConfigPath
    & oh-my-posh init pwsh --config $resolvedPath | Invoke-Expression
} else {
    Write-Warning "oh-my-posh not installed, skipping initialization."
}

if (Get-Command aliae -ErrorAction SilentlyContinue) {
    $resolvedConfPath = Resolve-Path $aliaeConfigPath
    $resolvedCompPath = Resolve-Path $aliaeCompletionPath

    & aliae init pwsh --config $resolvedConfPath | Invoke-Expression
    . $resolvedCompPath
} else {
    Write-Warning "aliae not installed, skipping initialization."
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (zoxide init powershell) -join "`n" | Invoke-Expression  # <- cooler cd command
} else {
    Write-Warning "zoxide not installed, skipping initialization."
}
