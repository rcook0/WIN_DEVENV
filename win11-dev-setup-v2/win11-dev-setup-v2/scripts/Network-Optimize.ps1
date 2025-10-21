Write-Host "Diagnostic TCP settings:" -ForegroundColor Cyan
netsh interface tcp show global
Write-Host "`nDelivery Optimization mode (current):"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode 2>$null
