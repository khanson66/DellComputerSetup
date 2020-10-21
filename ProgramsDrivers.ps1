#Requires -RunAsAdministrator

[CmdletBinding()]
param()

#functions stored here
Import-Module .\Functions.psm1
#loads in configuration file
$Config = Get-Content ".\config.json"| ConvertFrom-Json



Write-Verbose -Message "Script Currently running in: $PSScriptRoot"

#Check to see if computer is to be add to active directory/renamed
$yesList = @("yes","y")
$noList = @("no","n")
do{
    $addADresponse = Read-Host -Prompt "Do you want to add the computer to Active Directory (Yes/No)"
}while(($addADresponse -notin $yesList) -and ($addADresponse -notin $noList))


#creates scheduled task to add computer to AD at logon
if($addADresponse -in $yesList){
    $computerName = Read-Host -Prompt "Please enter the name of the computer"
    $credentials = Get-Credential -Message "Please enter your credentials in"
    
    Write-Host -Object "What OU would you like to add the machine:"
    $i = 1
    foreach($ou in $Config.location.ou.name){
        Write-Host -Object "$i) $ou"
        $i++
    }
    Write-Host -Object "$i) Default OU/Other"
    $OUResponse = Read-Host -Prompt ">"
    if($OUResponse -ge $i -or $OUResponse -le 0){
        $ou = "default"
    }else{
        $ou = $Config.location.ou[$OUResponse-1]
    }
    
    
    $filePath = "$PSScriptRoot\SetupAD.ps1"
    $program = "powershell.exe"

    $uname = $credentials.UserName
    $pass = ConvertFrom-SecureString $credentials.Password
        
    $taskArguments  = "$FilePath -UserName $uname -SecuredPass $pass -Path $PSScriptRoot -OU"
    
    $programArguments = "-noexit -ExecutionPolicy Bypass -Command ""$taskArguments"""
    
    Add-LogonTask -Program $program -Arguments $programArguments -TaskName $Config.general.taskname
}


#downloads ninite
$program = Invoke-Download -url $Config.url.ninite -name "Ninite.exe"

#runs executable that when it sees the ninite app will automat the install of it
Start-Process -FilePath "$PSScriptRoot\niniteauto.exe" -WarningAction "SilentlyContinue"

Write-Verbose -Message "Ninite started installing"

#runs ninite executable
Start-Process -FilePath .\$program -wait -WarningAction "SilentlyContinue"


Write-Verbose -Message "Ninite successfully installed"
Write-Verbose -Message "Checking if Dell Command is installed"



#Installs Dell Command if Not Installed
if(!(Confirm-Installed -programName 'Dell Command | Update')){
    Write-Verbose -Message "Dell Command not installed, Installing now"
    Write-Verbose -Message "Downloading Dell Command Update"

    $program = Invoke-Download -url $Config.url.dellCommand -name "DellCommand.exe" 

    Write-Verbose -Message "successfully finished downloading Dell Command Update"
    Write-Verbose -Message "Installing Dell Command Update"

    Start-Process -FilePath .\$program -WarningAction "SilentlyContinue" -Wait -ArgumentList "/s" #runs dell C|U silently
    
    Write-Verbose -Message "setting up install"

    Start-Sleep 10  #gives windows time update that dell command exists   
}

if($null -ne $computerName -or "" -ne $computerName){
    Rename-Computer -NewName $computerName -Force
}

if(Get-BitLockerStatus){ # suspends bitlocker incase bios updates are in order to prevent the drive from locking up
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    Write-Verbose -Message "bitlocker suspended"

    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
    
    Resume-BitLocker -MountPoint "C:"

    if (Get-BitLockerStatus){
        Write-Verbose -Message "Bitlocker reactivated"
    }else{
        Write-Verbose -Message "bitlocker reactivation failed"
    }
    
}else{

    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
}
Write-Host 'Done with drivers and Basic programs' -ForegroundColor "Green"

Restart-Computer

