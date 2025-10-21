Write-Host "Diagnostic TCP settings:" -ForegroundColor Cyan
netsh interface tcp show global

Write-Host "`nDelivery Optimization mode (current):"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode 2>$null

Write-Host @"
No aggressive changes applied by default.
If you want LAN peer+Microsoft CDN for faster downloads on gigabit, you can set:
  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config /v DODownloadMode /t REG_DWORD /d 3 /f
(3 = LAN/Internet peers allowed). Reboot recommended.
"@
