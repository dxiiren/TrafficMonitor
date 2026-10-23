# Run elevated (the caller elevates; no self-elevation here). Restores the pre-colour config:
# built-in CPU/MEM/GPU in the taskbar (tbar_display_item=28), plugin item LegionTemp.cpu, hardware_monitor_item=11.
param([string]$ExeDir = (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\zhongyang219.TrafficMonitor.Full_Microsoft.Winget.Source_8wekyb3d8bbwe\TrafficMonitor'))
$created = $false
$mx = New-Object Threading.Mutex($true, 'Global\KollectMonitorRollback', [ref]$created)
if (-not $created) { 'another rollback is already running, exiting'; exit 0 }
Get-Process TrafficMonitor -ea 0 | Stop-Process -Force
Start-Sleep 2
$p = Join-Path $env:APPDATA 'TrafficMonitor\config.ini'
Copy-Item $p "$p.bak-rollback-$(Get-Date -f HHmmss)" -Force
$want = @{ 'hardware_monitor_item' = '11'; 'tbar_display_item' = '28'; 'plugin_display_item' = 'LegionTemp.cpu' }
$lines = [Collections.Generic.List[string]]((([IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)) -replace '^\uFEFF','') -split "`r?`n")
foreach ($k in $want.Keys) {
  $hit = -1
  for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match "^$k\s*=") { $hit = $i; break } }
  if ($hit -ge 0) { $lines[$hit] = "$k = $($want[$k])" } else { "key $k not found" }
}
[IO.File]::WriteAllText($p, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($true)))
Start-ScheduledTask -TaskName TrafficMonitorAutoRun
Start-Sleep 6
Get-Process TrafficMonitor | Format-Table Id, StartTime
