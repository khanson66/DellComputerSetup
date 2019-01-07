#-----------------------------------------this obtains admin privialages----------------------------------------------------
#Must be the first part of program
param([switch]$Elevated,[string]$taskname = "programsdrivers")
#checks to see if user is admin
function Check-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
#runs if the current session is not running as admin
if ((Check-Admin) -eq $false)  {
    #if when the program is rerun it is not as admin it fails
    if ($elevated){
        write-host "could not elevate, please quit"
    }else {
    #reruns as admin
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    
    exit
}
#---------------------------------------------------------------------------------------------------------------------------
$compname = read-host -prompt "Please get the computername for the new computer. CHECK AD!" 

$task = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-command $PSScriptRoot\ProgramsDrivers.ps1 -taskname $taskname"
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $task -Trigger $trigger -TaskName $taskname -Description "runs to install programs and drivers" -RunLevel Highest
Add-Computer -DomainName "pace.edu" -NewName $compname  -restart -whatif

 