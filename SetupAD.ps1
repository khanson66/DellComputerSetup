﻿
#-----------------------------------------this obtains admin privialages----------------------------------------------------
#Must be the first part of program
[CmdletBinding()]
param(
    [switch]
    $Elevated,
    [string]
    $taskname = "RunOnLogin",
    [string]
    $computerName,
    [string] 
    $pass,
    [string] 
    $uname
)
Import-Module .\Configuration.psm1
#runs if the current session is not running as admin
if ((Confirm-Admin) -eq $false)  {
    if ($elevated){
        Write-Error "Failed to elevate session" 
    }else {
        $arguments = @{
            noprofile = $true
            noexit = $true
            file = "{0}"
            elevated = $true
            f = $myinvocation.MyCommand.Definition
        }
        Start-Process powershell.exe -Verb RunAs -ArgumentList @arguments
    }
    exit
}

#using taskname
$taskexist = Get-ScheduledTask -TaskName $taskname -ErrorAction Ignore

if($taskexist){
  Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
}


$credential = $null

if ($uname -notlike $null -and $pass -notlike $null){
    $upass = ConvertTo-SecureString $pass
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $uname,$upass 
}else{
    $credential = Get-Credential
}
do{
    $attempt = $true
    try{
        $addCompItems = @{
            DomainName = "pace.edu"
            NewName = $computerName
            Credential = $credential
            restart = $true
            ErrorAction = stop            
        }
        Add-Computer @addCompItems
    }
    catch{
        write-error -Message $_
        $attempt = $false
        Write-host "Please insert Credentials again or end the program"
        $credential = Get-Credential -UserName $uname
    }
     
}while ($attempt)

Write-host "CONGRATULATIONS YOU HAVE COMPLETED THE SET UP!!!!!!!!" -ForegroundColor Green





 