# Neuter CompatTelRunner

CompatTelRunner.exe seems to be unnecessary, nay, useless, for day-to-day computer use, unless you enjoy feeding telemetry to MS. It's also rather demanding on resources, which has an disproportionate impact on older system/systems with few resources.

See: https://superuser.com/questions/1613932/how-to-disable-compattelrunner-exe-microsoft-compatibility-telemetry

⚠ Requires SysInternals' `psexec`.

In an admin shell:

```ps
psexec -S cmd
```

in the TRUSTEDINSTALLER shell:

```ps
reg add HKLM\Software\Policies\Microsoft\Windows\DataCollection /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync /v "DisableSettingSync" /t REG_DWORD /d 2 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync /v "DisableSettingSyncUserOverride" /t REG_DWORD /d 1 /f
schtasks /change /disable /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
schtasks /change /disable /tn "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
schtasks /change /disable /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
schtasks /change /disable /tn "\Microsoft\Windows\Application Experience\StartupAppTask"
schtasks /change /disable /tn "\Microsoft\Windows\SettingSync\BackgroundUploadTask"
schtasks /change /disable /tn "\Microsoft\Windows\SettingSync\NetworkStateChangeTask"
```