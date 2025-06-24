$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir '..\emodipt-custom\emodipt-custom.omp.json'
oh-my-posh init pwsh --config (Resolve-Path $configPath) | Invoke-Expression

function rm {
    param([string]$Path)
    Remove-Item -Path $Path -Recurse -Force
}

function c { Clear-Host }
function x { exit }
function v { nvim @args }
function sudo { gsudo @args }
function ls { lsd -h @args }
function l { lsd -la @args }
function ll { lsd -l @args }
function ls { lsd -a @args }
function la { lsd -la @args }
function lt { lsd --tree @args }
function lf { lsd -la --group-directories-first @args }
function ff { fastfetch }
function nerdfont {
  & ([scriptblock]::Create((iwr 'https://raw.githubusercontent.com/jpawlowski/nerd-fonts-installer-PS/main/Invoke-NerdFontInstaller.ps1')))
}

function rm {
    param([string[]]$Path)
    Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
}

function ms-activate {
    irm https://get.activated.win | iex
}

function winutil {
    iwr -useb https://christitus.com/win | iex
}

Invoke-Expression ((zoxide init powershell) -join "`n")
