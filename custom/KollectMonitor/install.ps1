# Run elevated. Installs the LegionTemp plugin + KollectMonitor skin into a portable TrafficMonitor and applies the config.
# TrafficMonitor rewrites config.ini on graceful exit, so it is killed first.
param(
  [string]$ExeDir = (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\zhongyang219.TrafficMonitor.Full_Microsoft.Winget.Source_8wekyb3d8bbwe\TrafficMonitor'),
  [string]$Dll = (Join-Path $PSScriptRoot '..\..\PluginLegionTemp\LegionTemp.dll'),
  [string]$Log,
  [switch]$TestShowDesktop
)
if ($Log) { Start-Transcript $Log -Force | Out-Null }
$exe = Join-Path $ExeDir 'TrafficMonitor.exe'
Get-Process TrafficMonitor -ea 0 | Stop-Process -Force
Start-Sleep 2
New-Item -ItemType Directory -Force (Join-Path $ExeDir 'plugins') | Out-Null
Copy-Item $Dll (Join-Path $ExeDir 'plugins\LegionTemp.dll') -Force
New-Item -ItemType Directory -Force (Join-Path $ExeDir 'skins\KollectMonitor') | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'skin.xml'), (Join-Path $PSScriptRoot 'background.png'), (Join-Path $PSScriptRoot 'background_l.png') (Join-Path $ExeDir 'skins\KollectMonitor') -Force
"plugin installed: " + (Get-Item (Join-Path $ExeDir 'plugins\LegionTemp.dll')).Length + " bytes"
"skin plugin_map: " + (Select-String -Path (Join-Path $ExeDir 'skins\KollectMonitor\skin.xml') -Pattern 'LegionTemp.cpu' | Select -First 1).Line.Trim()
$p = Join-Path $env:APPDATA 'TrafficMonitor\config.ini'
Copy-Item $p "$p.bak-$(Get-Date -f HHmmss)" -Force
# sample file: [section] + key = value. Keys are set inside their section; missing keys/sections are appended.
$want = [ordered]@{}; $sec = ''
foreach ($l in Get-Content (Join-Path $PSScriptRoot 'config.sample.ini') -Encoding UTF8) {
  if ($l -match '^\[(.+)\]') { $sec = $Matches[1]; $want[$sec] = [ordered]@{}; continue }
  if ($l -match '^(\w+)\s*=\s*(.*)$' -and $sec) { $want[$sec][$Matches[1]] = $Matches[2] }
}
$lines = [Collections.Generic.List[string]]((([IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)) -replace '^﻿','') -split "`r?`n")
foreach ($s in $want.Keys) {
  $start = $lines.FindIndex({ param($x) $x -eq "[$s]" })
  if ($start -lt 0) { $lines.Add("[$s]"); $start = $lines.Count - 1 }
  foreach ($k in $want[$s].Keys) {
    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\[') { $end = $i; break } }
    $hit = -1
    for ($i = $start + 1; $i -lt $end; $i++) { if ($lines[$i] -match "^$k\s*=") { $hit = $i; break } }
    if ($hit -ge 0) { $lines[$hit] = "$k = $($want[$s][$k])" } else { $lines.Insert($end, "$k = $($want[$s][$k])") }
  }
}
[IO.File]::WriteAllText($p, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($true)))
Get-Content $p | Select-String 'hardware_monitor_item|tbar_display_item|plugin_display_item|skin_selected|show_task_bar_wnd|hide_main_window|always_on_top|lock_window_pos'
# autostart elevated at logon, without a UAC prompt
$user = "$env:USERDOMAIN\$env:USERNAME"
Unregister-ScheduledTask -TaskName TrafficMonitorAutoRun -Confirm:$false -ea 0
$a  = New-ScheduledTaskAction -Execute $exe -WorkingDirectory $ExeDir
$t  = New-ScheduledTaskTrigger -AtLogOn -User $user
$pr = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
$s  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName TrafficMonitorAutoRun -Action $a -Trigger $t -Principal $pr -Settings $s -Force | Out-Null
Start-ScheduledTask -TaskName TrafficMonitorAutoRun
Start-Sleep 8
Get-Process TrafficMonitor | Format-Table Id, StartTime
if ($TestShowDesktop) {
  # show desktop twice via COM (no keystrokes); TrafficMonitor windows should stay visible
  Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr h);'
  $h = (Get-Process TrafficMonitor | Select-Object -First 1).MainWindowHandle
  $sh = New-Object -ComObject Shell.Application
  "before ToggleDesktop: visible=" + [W.U]::IsWindowVisible($h)
  $sh.ToggleDesktop(); Start-Sleep 2
  "after ToggleDesktop: visible=" + [W.U]::IsWindowVisible($h)
  $sh.ToggleDesktop(); Start-Sleep 1
}
if ($Log) { Stop-Transcript | Out-Null }
