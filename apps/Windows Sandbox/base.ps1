# Sandbox setup script
#
# Bits and pieces taken from the following:
# https://github.com/Strappazzon/wsb/blob/master/bootstrap.ps1
# https://github.com/jdhitsolutions/WindowsSandboxTools/blob/main/wsbScripts/sandbox-config-presentation.ps1
# https://github.com/BanterBoy/Windows-Sandbox/blob/main/WSBshare/sandbox-config.ps1

. $PSScriptRoot\_functions.ps1


# ----------------------
# Registry Tweaks
# https://github.com/Strappazzon/wsb/blob/master/bootstrap.ps1
# ----------------------

#region Registry Tweaks

Write-Host 'Applying registry tweaks...' -ForegroundColor Blue

### Start menu ###

Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'Start_IrisRecommendations'   -Value 0 -Type DWord # Disable tips
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'                 -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord # Disable web search

Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'           -Name 'AllowCortana'                -Value 0 -Type DWord # Disable Cortana (GPO)
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'           -Name 'AllowSearchToUseLocation'    -Value 0 -Type DWord # Prevent search from using location (GPO)
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'           -Name 'DisableWebSearch'            -Value 1 -Type DWord # Disable web search (GPO)


### Taskbar ###

Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'             -Name 'SearchboxTaskbarMode'        -Value 0 -Type DWord # Hide search box
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'ShowTaskViewButton'          -Value 0 -Type DWord # Hide Task View button
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'TaskbarGlomLevel'            -Value 1 -Type DWord # Don't combine taskbar buttons
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'TaskbarSd'                   -Value 0 -Type DWord # Disable "Show Desktop"
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'TaskbarSmallIcons'           -Value 1 -Type DWord # Small taskbar icons

Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'            -Name 'EnableFeeds'                 -Value 0 -Type DWord # Disable news & interests (GPO)


### Windows Explorer ##

Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'HideFileExt'                 -Value 0 -Type DWord # Show file extensions
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'LaunchTo'                    -Value 1 -Type DWord # Launch to 'This PC'
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'NavPaneShowAllFolders'       -Value 1 -Type DWord # Sidebar items automatically expanded
#Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'ShowSuperHidden'             -Value 1 -Type DWord # Show system files
#Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'  -Name 'UseCompactMode'              -Value 1 -Type DWord # Compact mode ???


### Windows theme ###

Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme'           -Value 0 -Type DWord # Apps use dark mode
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme'        -Value 0 -Type DWord # System uses dark mode


### MS Edge ###

# Some privacy settings I use on my host OS.
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'AddressBarMicrosoftSearchInBingProviderEnabled' -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'AlternateErrorPagesEnabled'                     -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'AutofillAddressEnabled'                         -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'AutofillCreditCardEnabled'                      -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'DiagnosticData'                                 -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeShoppingAssistantEnabled'                   -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EnableMediaRouter'                              -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HubsSidebarEnabled'                             -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ImportAutofillFormData'                         -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ImportPaymentInfo'                              -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ImportSavedPasswords'                           -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'LocalProvidersEnabled'                          -Value 1 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'MediaRouterCastAllowAllIPs'                     -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PaymentMethodQueryEnabled'                      -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PersonalizationReportingEnabled'                -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ResolveNavigationErrorsUseWebService'           -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SearchSuggestEnabled'                           -Value 0 -Type DWord
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'StartupBoostEnabled'                            -Value 0 -Type DWord


Write-Host 'Restarting explorer.exe...' -ForegroundColor Blue

# Restart Windows Explorer to apply the registry changes
Restart-Explorer


# ----------------------
# Finalize
# ----------------------

#region Finalize

# Open explorer windows to common locations
explorer.exe "C:\"
explorer.exe "C:\Users\WDAGUtilityAccount"

#endregion Finalize
