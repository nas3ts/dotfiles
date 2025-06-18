oh-my-posh init pwsh --config F:\Dev\emodipt-custom\emodipt-custom.omp.json | Invoke-Expression

function rm {
    param([string]$Path)
    Remove-Item -Path $Path -Recurse -Force
}

function c { Clear-Host }
function x { exit }
function v { nvim @args }
function sudo { gsudo @args }
function ff { fastfetch }
function nerdfont {
  & ([scriptblock]::Create((iwr 'https://raw.githubusercontent.com/jpawlowski/nerd-fonts-installer-PS/main/Invoke-NerdFontInstaller.ps1')))
}

function rm {
    param([string[]]$Path)
    Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
}


Invoke-Expression ((zoxide init powershell) -join "`n")
