# Sandbox setup script
#
# Installs NuGet, PowerShell 7, Scoop, 7zip, Git, Windows Terminal.
# Applies registry tweaks to make sandbox environment feel similar to my host environment.
# Creates desktop shortcuts for PowerShell 7, Windows Terminal.

Write-Host 'Calling base script...' -ForegroundColor Blue

. $PSScriptRoot\_functions.ps1
& "$PSScriptRoot\base.ps1"


# ----------------------
# Common
# ----------------------

#region Common

Write-Host 'Installing common dependencies...' -ForegroundColor Blue

#Enable-PSRemoting -Force -SkipNetworkProfileCheck
Install-PackageProvider -Name NuGet -Force -ForceBootstrap -Scope AllUsers
Install-Module PackageManagement, PowerShellGet -Force

#endregion Common


# ----------------------
# Scoop
# ----------------------

#region Scoop Tasks

Write-Host 'Installing Scoop...' -ForegroundColor Blue

Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

Write-Host 'Installing Scoop apps...' -ForegroundColor Blue

scoop install git
scoop bucket add extras
scoop install windows-terminal
reg import "C:\Users\WDAGUtilityAccount\scoop\apps\windows-terminal\current\install-context.reg"

#endregion Scoop Tasks


# ----------------------
# Packages & Modules
# ----------------------

#region PS Jobs

Write-Host 'Starting PowerShell background jobs...' -ForegroundColor Blue

# Run updates and installs in the background

Start-Job {
	log "JOB: PowerShell job starting."
	Install-Module PSReleaseTools -Force
	Install-PowerShell -Mode Quiet -EnableRemoting -EnableRunContext
	&'C:\Program Files\PowerShell\7\pwsh.exe' -command { Update-Help -Force }
	log "JOB: PowerShell job complete."
}

#Start-Job { 
#	log "JOB: Windows Terminal job starting."
#	Install-Module WTToolbox -Force
#	#Install-WTRelease
#	Install-WindowsTerminal
#	log "JOB: Windows Terminal job complete."
#}

#Start-Job {
#	log "JOB: BurntToast job starting."
#	Install-Module BurntToast -Force
#	log "JOB: BurntToast job starting."
#}

#endregion PS Jobs


# ----------------------
# Shortcuts
# ----------------------

#region Shortcuts

Write-Host 'Creating desktop shortcuts...' -ForegroundColor Blue

New-Shortcut -Target "${Env:ProgramFiles}\PowerShell\7\pwsh.exe" -Destination "${Env:UserProfile}\Desktop\PowerShell.lnk"
New-Shortcut -Target "${Env:UserProfile}\scoop\apps\windows-terminal\current\wt.exe" -Destination "${Env:UserProfile}\Desktop\Windows Terminal.lnk"

#endregion Shortcuts


# ----------------------
# Finalize
# ----------------------

#region Finalize

Write-Host 'Finalizing...' -ForegroundColor Blue

# Wait for everything to finish
Get-Job | Wait-Job

#endregion Finalize
