#Requires -RunAsAdministrator

[CmdletBinding()]
param()

#functions stored here
Import-Module .\Functions.psm1
#loads in configuration file
$Config = Get-Content "$PSscriptRoot\config.json"| ConvertFrom-Json

#define defaults
$isLab = $config.general.isLab
if ($null -eq $isLab){
    $isLab = $false
}
$yesList = @("yes","y")
$noList = @("no","n")

Write-Verbose -Message "[*]Script Currently running in: $PSScriptRoot"
if($isLab){
    Write-Host "[!] Running Lab Setup Script version!" -ForegroundColor Cyan
}

#Check to see if computer is to be add to active directory/renamed
if (!$isLab){
    do{
        $addADresponse = Read-Host -Prompt "Do you want to add the computer to Active Directory (Yes/No)"
    }while(($addADresponse -notin $yesList) -and ($addADresponse -notin $noList))
}else{
    $addADresponse = "yes"
}


write-host "[*] Info: Testing network connection"

$error_count = 0
while(!(Test-Connection -ComputerName 8.8.8.8 -Count 2 -Delay 1 -Quiet)){
    if($error_count -eq 4){
        Write-Host "[!] Error: Can't internet exiting now" -ForegroundColor Red
        exit(1)
    }
    Write-Host "[!] Error: Can't connect to the internet. Trying again in 30 seconds" -ForegroundColor Red
    Start-Sleep -Seconds 30
    $error_count ++
}
$computerName = Read-Host -Prompt "Please enter the name of the computer(or just it enter to skip):"
#creates scheduled task to add computer to AD at logon
if($addADresponse -in $yesList){
    #Set Registry Key to prompt in command line
    $key = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds"
    Set-ItemProperty -Path $key -Name ConsolePrompting -Value True
    $credentials = Get-Credential -Message "Please enter your admin credentials in" 
    Remove-ItemProperty -Path $key -Name ConsolePrompting 
    
    if ($isLab){
        write-host -Object ("OU is being set to " + $Config.location[0].name)
        if($null -eq $Config.location[0].path){
            Write-Error -Message "No OU was supplied for the computers to be added to"
        }
        $Config.location[0].path
    }else{
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
            $ou = $Config.location[$OUResponse-1].path
        }
        
    }


    $filePath = "$PSScriptRoot\SetupAD.ps1"
    $program = "powershell.exe"

    $uname = $credentials.UserName
    $pass = ConvertFrom-SecureString $credentials.Password
        
    $taskArguments  = "$FilePath -UserName $uname -SecuredPass $pass -Path $PSScriptRoot -OU '$ou'"
    
    $programArguments = "-noexit -ExecutionPolicy Bypass -Command ""$taskArguments"""
    
    Add-LogonTask -Program $program -Arguments $programArguments -TaskName $Config.general.taskname
}else{
    
    if($null -ne $computerName -or "" -ne $computerName){
        Rename-Computer -NewName $computerName -Force
    }
    
}

#downloads ninite
$program = Invoke-Download -url $Config.url.ninite -name "Ninite.exe"

#runs executable that when it sees the ninite app will automatically the install it
Start-Process -FilePath "$PSScriptRoot\niniteauto.exe" -WarningAction "SilentlyContinue"

Write-Host "[*] Info: Ninite started installing"

#runs ninite executable
Start-Process -FilePath .\$program -wait -WarningAction "SilentlyContinue"


Write-Host "[*] Info: Ninite successfully installed"
Write-Host "[*] Info: Checking if Dell Command is installed"

#Installs Dell Command if Not Installed
if(!(Confirm-Installed -programName 'Dell Command | Update')){
    Write-Host "[*] Info: Dell Command not installed, Installing now"

    $program = Invoke-Download -url $Config.url.dellCommand -name "DellCommand.exe" 

    Write-Host "[*] Info: Installing Dell Command Update"
    
    Start-Process -FilePath .\$program -WarningAction "SilentlyContinue" -Wait -ArgumentList "/s" #runs dell C|U silently
    
    Write-Host -Object "[*] Info: Install Complete. Registering with system."

    Start-Sleep 10  #gives windows time update that dell command exists   
}

#runs drivers

if(Get-BitLockerStatus){ # suspends bitlocker incase bios updates are in order to prevent the drive from locking up
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    Write-Host "[*] Info: bitlocker suspended"

    Start-Process -FilePath $Config.general.CommandUpdatePath -ArgumentList $Config.general.CommandUpateArgs -Wait -NoNewWindow
    
    Resume-BitLocker -MountPoint "C:"

    if (Get-BitLockerStatus){
        Write-Host -Object "[*] Info: Bitlocker reactivated"
    }else{
        Write-Error -Message "[!] Error: bitlocker reactivation failed" 
    }
    
}else{

    Start-Process -FilePath $Config.general.CommandUpdatePath -ArgumentList $Config.general.CommandUpateArgs -Wait -NoNewWindow
}

Write-Host 'Done with drivers and Basic programs' -ForegroundColor "Green"

Start-Sleep -Seconds 5

Restart-Computer

