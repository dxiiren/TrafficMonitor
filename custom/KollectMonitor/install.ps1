# Run elevated. Installs the LegionTemp plugin + KollectMonitor skin into a portable TrafficMonitor and applies the config.
# TrafficMonitor rewrites config.ini on graceful exit, so it is killed first.
param(
  [string]$ExeDir = (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\zhongyang219.TrafficMonitor.Full_Microsoft.Winget.Source_8wekyb3d8bbwe\TrafficMonitor'),
  [string]$Dll = (Join-Path $PSScriptRoot '..\..\PluginLegionTemp\LegionTemp.dll'),
  [string]$Log
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
$set = @{}
foreach ($l in Get-Content (Join-Path $PSScriptRoot 'config.sample.ini')) { $m=[regex]::Match($l,'^(\w+)\s*=\s*(.*)$'); if ($m.Success) { $set[$m.Groups[1].Value] = $m.Groups[2].Value } }
$raw = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
$out = foreach ($l in ($raw -split "`r?`n")) { $m=[regex]::Match($l,'^(\w+)\s*=\s*(.*)$'); if ($m.Success -and $set.ContainsKey($m.Groups[1].Value)) { "$($m.Groups[1].Value) = $($set[$m.Groups[1].Value])" } else { $l } }
[IO.File]::WriteAllText($p, ($out -join "`r`n"), (New-Object Text.UTF8Encoding($true)))
Get-Content $p | Select-String 'hardware_monitor_item|tbar_display_item|plugin_display_item|skin_selected|show_task_bar_wnd|hide_main_window'
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
if ($Log) { Stop-Transcript | Out-Null }
