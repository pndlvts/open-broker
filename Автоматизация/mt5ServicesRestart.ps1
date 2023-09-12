$cpu0min = (Get-WmiObject -ComputerName bd-vm-soap-n win32_processor).LoadPercentage
start-sleep 300
$cpu5min = (Get-WmiObject -ComputerName bd-vm-soap-n win32_processor).LoadPercentage
if ($cpu0min -gt 90 -and $cpu5min -gt 90) {
    taskkill /S "bd-vm-soap-n" /F /T /fi "services eq Metatrader.ManagerApi.UserAddCommand.Service"
    taskkill /S "bd-vm-soap-n" /F /T /fi "services eq Metatrader.ManagerApi.Service"
    Get-Service -ComputerName bd-vm-soap-n -Name Metatrader.ManagerApi.UserAddCommand.Service | Start-Service
    Get-Service -ComputerName bd-vm-soap-n -Name Metatrader.ManagerApi.Service | Start-Service
    Get-Service -ComputerName bd-vm-soap-n -Name Metatrader.ManagerApi.UserAddCommand.Service | select Displayname, status
    Get-Service -ComputerName bd-vm-soap-n -Name Metatrader.ManagerApi.Service | select Displayname, status
}