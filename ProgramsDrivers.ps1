#Requires -RunAsAdministrator

[CmdletBinding()]
param()

#functions stored here
Import-Module .\Functions.psm1
#loads in configuration file
$Config = Get-Content "$PSscriptRoot\config.json"| ConvertFrom-Json


Write-Verbose -Message "Script Currently running in: $PSScriptRoot"

#Check to see if computer is to be add to active directory/renamed
$yesList = @("yes","y")
$noList = @("no","n")
do{
    $addADresponse = Read-Host -Prompt "Do you want to add the computer to Active Directory (Yes/No)"
}while(($addADresponse -notin $yesList) -and ($addADresponse -notin $noList))

write-host "[*] Info: Testing network connection"

$error_count = 0
while(!(Test-Connection -ComputerName 8.8.8.8 -Quiet)){
    if($error_count -eq 4){
        exit(1)
    }
    Write-Host "[!] Error: Can't connect to the internet" -ForegroundColor Red
    Start-Sleep -Seconds 30
    $error_count ++
}

#creates scheduled task to add computer to AD at logon
if($addADresponse -in $yesList){
    $computerName = Read-Host -Prompt "Please enter the name of the computer"
    $credentials = Get-Credential -Message "Please enter your admin credentials in" 
    
    Write-Host -Object "What OU would you like to add the machine:"
    
    $i = 1
    foreach($ou in $Config.location.name){
        Write-Host -Object "$i) $ou"
        $i++
    }
    Write-Host -Object "$i) Default OU/Other"
    $OUResponse = Read-Host -Prompt ">"
    if($OUResponse -ge $i -or $OUResponse -le 0){
        $ou = "default"
    }else{
        $ou = $Config.location[$OUResponse-1]
    }
    
    $filePath = "$PSScriptRoot\SetupAD.ps1"
    $program = "powershell.exe"

    $uname = $credentials.UserName
    $pass = ConvertFrom-SecureString $credentials.Password
        
    $taskArguments  = "$FilePath -UserName $uname -SecuredPass $pass -Path $PSScriptRoot -OU $ou"
    
    $programArguments = "-noexit -ExecutionPolicy Bypass -Command ""$taskArguments"""
    
    Add-LogonTask -Program $program -Arguments $programArguments -TaskName $Config.general.taskname
}

#downloads ninite
$program = Invoke-Download -url $Config.url.ninite -name "Ninite.exe"

#runs executable that when it sees the ninite app will automat the install of it
Start-Process -FilePath "$PSScriptRoot\niniteauto.exe" -WarningAction "SilentlyContinue"

Write-Host "[*] Info: Ninite started installing"

#runs ninite executable
Start-Process -FilePath .\$program -wait -WarningAction "SilentlyContinue"


Write-Host "[*] Info: Ninite successfully installed"
Write-Host "[*] Info: Checking if Dell Command is installed"



#Installs Dell Command if Not Installed
if(!(Confirm-Installed -programName 'Dell Command | Update')){
    Write-Host "[*] Info: Dell Command not installed, Installing now"
    Write-Host "[*] Info: Downloading Dell Command Update"

    $program = Invoke-Download -url $Config.url.dellCommand -name "DellCommand.exe" 

    Write-Host "[*] Info: successfully finished downloading Dell Command Update"
    Write-Host "[*] Info: Installing Dell Command Update"

    Start-Process -FilePath .\$program -WarningAction "SilentlyContinue" -Wait -ArgumentList "/s" #runs dell C|U silently
    
    Write-Host "[*] Info: setting up install"

    Start-Sleep 10  #gives windows time update that dell command exists   
}

if($null -ne $computerName -or "" -ne $computerName){
    Rename-Computer -NewName $computerName -Force
}

if(Get-BitLockerStatus){ # suspends bitlocker incase bios updates are in order to prevent the drive from locking up
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    Write-Host "[*] Info: bitlocker suspended"

    invoke-expression $Config.general.runCommandUpdate
    
    Resume-BitLocker -MountPoint "C:"

    if (Get-BitLockerStatus){
        Write-Host "[*] Info: Bitlocker reactivated"
    }else{
        Write-Host "[!] Error: bitlocker reactivation failed" -ForegroundColor Red
    }
    
}else{

    invoke-expression $Config.general.runCommandUpdate
}
Write-Host 'Done with drivers and Basic programs' -ForegroundColor "Green"

Restart-Computer

