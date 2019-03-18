
param([switch]$Elevated,               
[string]$taskname = "programsdrivers",  
[switch]$AddAD                         
)
function Check-Admin {
    #checks to see if user is admin
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


function Check-Installed( $programName ) {
    Get-CMIObject -Query "SELECT * FROM Win32_Product Where Name Like '$programName'" | 
    measure-object -Sum
}

function Bitlocker_status{
    $BLactive = Get-Bitlockervolume -MountPoint "C:"
    if($BLactive.ProtectionStatus -eq 'On' -and $BLactive.EncryptionPercentage -eq '100'){
       return $true
    }else{
        return $false
    }
}

if ((Check-Admin) -eq $false)  {
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


Write-Debug $PSScriptRoot
Set-Location $PSScriptRoot

if ($AddAD){
    $userCred = Get-Credential
    $uname = $userCred.UserName
    $pass = Convertfrom-securestring $userCred.Password 
    $compName = read-host -prompt "Please get the computername for the new computer. CHECK AD!"
    $taskexist = Get-ScheduledTask -TaskName $taskname -ErrorAction Ignore
    
    
    
    if (!$taskexist){
        Write-Verbose "Creating New Task"
        $arguments = @
        
        
        $task = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-noexit -ExecutionPolicy Bypass -Command $PSScriptRoot\SetupAD.ps1 -taskname $taskname  -CompName $compName -uname $uname -pass $pass"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        # TODO get auto deleteing working after one run
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
         
        Register-ScheduledTask -Action $task -Trigger $trigger -TaskName $taskname -Settings $settings -Description "runs to install programs and drivers" -RunLevel Highest
        Write-Host "task created"
    }
   
}

#name of downloaded program
$ProgInstaller = "ninite.exe"
write-host "Ninite downloading starting"


$ProgressPreference = 'silentlyContinue'    # removes the progress bar for download because slows downlaod

#downloads ninite installer (TODO: figure out a selector of sorts order for part below does not matter)
$uri = 'https://ninite.com/.net4.7.2-7zip-air-chrome-firefox-java8-shockwave-silverlight-vlc/ninite.exe'
Invoke-WebRequest -outf $ProgInstaller -Uri $uri


$ProgressPreference = 'continue'    #returns to normal operation
write-host "Download finished"


Start-Process ".\niniteauto.exe" -WarningAction SilentlyContinue 

Write-Verbose "Ninite started installing"


Start-Process .\$ProgInstaller -wait -WarningAction SilentlyContinue

Write-Verbose "Ninite successfully installed"

Write-Verbose "Checking if Dell Command is installed"

if(Check-Installed('Dell Command | Update') -eq 0){
    $DellC = "dellcommand.exe"
    Write-Verbose "Downloading Dell Command Update"
    
    $ProgressPreference = 'silentlyContinue'   
    
    #downloads dellcommand and names it
    Invoke-WebRequest -outf $DellC https://downloads.dell.com/FOLDER05055451M/1/Dell-Command-Update_DDVDP_WIN_2.4.0_A00.EXE 
    
    
    $ProgressPreference = 'continue'    
    Write-Verbose "successfully finished downloading Dell Command Update"
    Write-Verbose "Installing Dell Command Update"

    
    Start-Process $DellC -WarningAction SilentlyContinue -Wait -ArgumentList "/s"
    
    #alls windows to update that it exists
    Write-Verbose "setting up install"
    
    Start-Sleep 10 #gives windows time update that dell command exists
    
}

if(Bitlocker_status){
    
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    Write-Verbose "bitlocker suspended"

    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
    
    Resume-BitLocker -MountPoint "C:"
    
    
    if (Bitlocker_status){
        Write-Verbose "Bitlocker reactivated"
    }else{
        Write-Verbose "bitlocker reactivation failed"
    }
    Write-Host 'Install Finished' -ForegroundColor Green
}else{

    
    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /log C:\"
    
    Restart-Computer
}

