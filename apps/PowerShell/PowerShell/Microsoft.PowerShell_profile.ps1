# ----------------------
# Chocolatey
# ----------------------
# See https://ch0.co/tab-completion for details.

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}


# ----------------------
# Scoop
# ----------------------

#Import-Module 'C:\Users\BK\scoop\apps\scoop\current\supporting\completion\Scoop-Completion.psd1' -ErrorAction SilentlyContinue

$ScoopCompletion = "$Env:UserProfile\scoop\modules\scoop-completion"
if (Test-Path($ScoopCompletion)) { Import-Module "$ScoopCompletion" }


# ----------------------
# User scripts
# ----------------------

$MyScripts = "$env:USERPROFILE\Documents\PowerShell\Scripts"

$caddy = "$MyScripts\caddy_completion.ps1"
if (Test-Path($caddy)) { . $caddy }

$ddev = "$MyScripts\ddev_completion.ps1"
if (Test-Path($ddev)) { . $ddev }

#$volta = "$MyScripts\volta_completion.ps1"
#if (Test-Path($volta)) { . $volta }

$ripgrep = "$MyScripts\ripgrep_completion.ps1"
if (Test-Path($ripgrep)) { . $ripgrep }

$roadrunner = "$MyScripts\roadrunner_completion.ps1"
if (Test-Path($roadrunner)) { . $roadrunner }


# ----------------------
# Zoxide
# https://github.com/ajeetdsouza/zoxide
# ----------------------

Invoke-Expression (& { (zoxide init powershell | Out-String) })


# ----------------------
# Starship prompt
# ----------------------

#Invoke-Expression (&starship init powershell)
