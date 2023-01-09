Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted

$serial = (gwmi win32_bios).SerialNumber

md c:\HWID

Set-Location c:\HWID


Install-Script -Name Get-WindowsAutoPilotInfo

Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID-$serial.csv