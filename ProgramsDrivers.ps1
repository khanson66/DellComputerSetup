[CmdletBinding()]
param([switch]$Elevated)

Import-Module .\Configuration.psm1
. .\ConfigVar.ps1
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

Write-Verbose $PSScriptRoot

#intial load in of data



$yesList = @("yes","y")
$noList = @("no","n")
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
    $taskArguments = "-noexit -ExecutionPolicy Bypass -Command $FilePath -taskname $taskname -ComputerName $ComputerName -uname $uname -pass $pass"
    
    Add-LogonTask -Programs $program -Argument $taskArguments
}
#end load in

$program = Invoke-Download -url $NiniteURL -name "Ninite.exe"

Start-Process ".\niniteauto.exe" -WarningAction SilentlyContinue

Write-Verbose "Ninite started installing"

Start-Process .\$program -wait -WarningAction SilentlyContinue

Write-Verbose "Ninite successfully installed"

Write-Verbose "Checking if Dell Command is installed"

#Installs Dell Command if Not Installed
if(!(Confirm-Installed -programName 'Dell Command | Update')){
    Write-Verbose "Dell Command not installed, Installing now"

    Write-Verbose "Downloading Dell Command Update"
    $program = Invoke-Download -url $dellCommandURL -name "DellCommand.exe" 
    Write-Verbose "successfully finished downloading Dell Command Update"
    Write-Verbose "Installing Dell Command Update"

    Start-Process .\$program -WarningAction SilentlyContinue -Wait -ArgumentList "/s"
    
    #alls windows to update that it exists
    Write-Verbose "setting up install"

    Start-Sleep 10  #gives windows time update that dell command exists
    
}

if(Get-BitLockerStatus){
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

