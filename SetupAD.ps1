#-----------------------------------------this obtains admin privialages----------------------------------------------------
#Must be the first part of program
param([switch]$Elevated,
[string]$taskname = "programsdrivers",
[string] $compName,
[string] $pass,
[string] $uname
)
#checks to see if user is admin
function CheckAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
#runs if the current session is not running as admin
if ((CheckAdmin) -eq $false)  {
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
#-----------------------------------------removes previously created task---------------------------------------------------

#using taskname
$taskexist = Get-ScheduledTask -TaskName $taskname -ErrorAction Ignore
Write-Host $taskexist
if($taskexist){
  Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
}

#---------------------------------------------------------------------------------------------------------------------------


    $credential = $null
    if ($uname -notlike $null -and $pass -notlike $null){
        $upass = ConvertTo-SecureString $pass
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $uname,$upass 
    }else{
        $credential = Get-Credential
    }
    Add-Computer -DomainName "pace.edu" -NewName $compName -Credential $credential -restart 

    #this might contain errors.
    #TODO:find a error correction portion
    Write-host "An error has occured" -ForegroundColor Red
    $compName = read-host -prompt "Please get the computername for the new computer. CHECK AD!" 
    add-Computer -DomainName "pace.edu" -NewName $compname -restart





 