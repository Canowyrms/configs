# ----------------------
# Functions
# ----------------------

#region Functions

Function New-Shortcut ([String]$Target, [String]$Destination) {
	<#
	.SYNOPSIS
	Create a shortcut
	.PARAMETER Target
	Path to file
	.PARAMETER Destination
	Path to shortcut including the .lnk extension
	.EXAMPLE
	New-Shortcut -Target "C:\bin\Program.exe" -Destination "C:\Users\WDAGUtilityAccount\Desktop\Program.lnk"
	#>

	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($Destination)
	$Shortcut.TargetPath = $Target
	$Shortcut.Save()
}

Function Restart-Explorer {
	<#
	.SYNOPSIS
	Restart Windows Explorer
	#>
  
	Stop-Process -Name 'Explorer' -Force
	# Give Windows Explorer time to start
	Start-Sleep -Seconds 3
  
	# Verify that Windows Explorer has restarted
	Try {
		$p = Get-Process -Name 'Explorer' -ErrorAction Stop
	} Catch {
		Try {
			Invoke-Item 'explorer.exe'
			# Start-Process 'explorer.exe'
		} Catch {
			# This should never be called
			Throw $_
		}
	}
}

Function Set-RegistryValue ([String]$Path, [String]$Name, $Value, [String]$Type) {
	<#
	.SYNOPSIS
	Edit or create a registry value
	.PARAMETER Path
	Path to the registry key
	.PARAMETER Name
	Name of the registry entry
	.PARAMETER Value
	Value of the registry entry
	.PARAMETER Type
	Type of the registry entry
	.EXAMPLE
	Set-RegistryValue -Path "HKLM:\SOFTWARE\Strappazzon\wsb" -Name "Example" -Value 1 -Type DWord
	Set-RegistryValue -Path "HKLM:\SOFTWARE\Strappazzon\wsb" -Name "Example" -Value "Yes" -Type String
	#>
  
	If (!(Test-Path $Path)) {
		New-Item -Path $Path -Force | Out-Null
	}
	If (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
		Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
	} Else {
		New-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
	}
}

#endregion Functions
