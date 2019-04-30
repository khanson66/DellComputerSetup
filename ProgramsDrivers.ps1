[CmdletBinding()]
param([switch]$Elevated)

#adds in functions and the Url varible file
Import-Module .\Configuration.psm1
. .\ConfigVar.ps1

# check and elevates if not run as administrator
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
        Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    }
    exit
}

Write-Verbose $PSScriptRoot

$yesList = @("yes","y")
$noList = @("no","n")
#Check to see if computer is to be add to active directory/renamed
do{
    $addADresponse = Read-Host -Prompt "Do you want to add the computer to Active Directory (Yes/No)"
}while(($addADresponse -notin $yesList) -and ($addADresponse -notin $noList))

if($addADresponse -in $yesList){
    $computerName = Read-Host -Prompt "Please enter the name of the computer"
    $credentials = Get-Credential
    
    $filePath = "$PSScriptRoot\SetupAD.ps1"
    $program = "powershell.exe"

    $uname = $credentials.UserName
    $pass = ConvertFrom-SecureString $credentials.Password
    $taskname = "RunOnLogin"
    
    $taskArguments  = "$FilePath -taskname $taskname -ComputerName $ComputerName -uname $uname -pass $pass"
    $programArguments = "-noexit -ExecutionPolicy Bypass -Command ""$taskArguments"""
    
    Add-LogonTask -Program $program -Argument $programArguments
}

#downloads and install ninite
$program = Invoke-Download -url $NiniteURL -name "Ninite.exe"

Start-Process ".\niniteauto.exe" -WarningAction SilentlyContinue

Write-Verbose "Ninite started installing"

Start-Process .\$program -wait -WarningAction SilentlyContinue

Write-Verbose "Ninite successfully installed"

# runs Drive updates with dell command update
Write-Verbose "Checking if Dell Command is installed"

#Installs Dell Command if Not Installed
if(!(Confirm-Installed -programName 'Dell Command | Update')){
    Write-Verbose "Dell Command not installed, Installing now"

    Write-Verbose "Downloading Dell Command Update"
    $program = Invoke-Download -url $dellCommandURL -name "DellCommand.exe" 
    Write-Verbose "successfully finished downloading Dell Command Update"
    Write-Verbose "Installing Dell Command Update"

    Start-Process .\$program -WarningAction SilentlyContinue -Wait -ArgumentList "/s" #runs dell C|U silently
    
    Write-Verbose "setting up install"

    Start-Sleep 10  #gives windows time update that dell command exists
    
}

if(Get-BitLockerStatus){ # suspends bitlocker incase bios updates are in order to prevent the drive from locking up
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    Write-Verbose "bitlocker suspended"

    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
    
    Resume-BitLocker -MountPoint "C:"
        
    if (Get-BitLockerStatus){
        Write-Verbose "Bitlocker reactivated"
    }else{
        Write-Verbose "bitlocker reactivation failed"
    }
    
}else{

    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
}
Write-Host 'Done with drivers and Basic programs' -ForegroundColor Green
Restart-Computer

