REM setup.cmd
REM This code runs in the context of the Windows Sandbox

REM Set execution policy and run setup script.

REM powershell.exe -command "&{Set-ExecutionPolicy RemoteSigned -Force; Enable-PSRemoting -Force -SkipNetworkProfileCheck; Install-PackageProvider -Name NuGet -Force -ForceBootstrap -Scope AllUsers; C:\Sandbox\scoop-setup.ps1}"
powershell -ExecutionPolicy Unrestricted -Command "start powershell {-NoExit -File C:\Users\WDAGUtilityAccount\Desktop\Sandbox\scoop.ps1}"