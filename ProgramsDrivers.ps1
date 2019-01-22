
#-----------------------------------------this obtains admin privialages----------------------------------------------------
#Must be the first part of program
param([switch]$Elevated,                #used with checkadmin to denote if the program failed to elevate
[string]$taskname = "programsdrivers",  #control the taskname used in the windows schedule and allows name to pass through restart
[switch]$AddAD                          #if called the program names and add computer to Active Directory after restart 
)


function CheckAdmin {
    #checks to see if user is admin
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

#-----------------------------------------checks to see is called program is installed--------------------------------------
function Check_Program_Installed( $programName ) {
    
    #runs query to get all the objects with the name inputed the number of objects which is measured and counted 
    $wmi_check = (Get-WMIObject -Query "SELECT * FROM Win32_Product Where Name Like '$programName'" | measure-object).count 

    # if there are no object 0 is the returned by the above statment and the function returns true else false
    if($wmi_check -like "0"){
        return $true
    }else{
        return $false
    }

}
#---------------------------------------------------------------------------------------------------------------------------

#-----------------------------------------checks to see is bitlocker is active and at 100%----------------------------------
function Bitlocker_status{

    # loads bitlocker volume on the C drive to the varible
    $BLactive = Get-Bitlockervolume -MountPoint "C:"

    #checks to see if it is active and if it is at 100%
    if($BLactive.ProtectionStatus -eq 'On' -and $BLactive.EncryptionPercentage -eq '100'){
       return $true
    }else{
        return $false
    }
}
#---------------------------------------------------------------------------------------------------------------------------

#assures that the current directory pointer is in the CSOSetup folder
Write-host "Beginnging installation" -ForegroundColor Red
write-host $PSScriptRoot
Set-Location $PSScriptRoot


#-----------------------------------------Runs if AddAD Switch is called----------------------------------------------------
if ($AddAD){
    $userCred = Get-Credential
    $uname = $userCred.UserName
    $pass = Convertfrom-securestring $userCred.Password 
    $compName = read-host -prompt "Please get the computername for the new computer. CHECK AD!"
    $taskexist = Get-ScheduledTask -TaskName $taskname -ErrorAction Ignore
    
    Write-Host $taskexist
    if (!$taskexist){
        $task = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-noexit -ExecutionPolicy Bypass -Command $PSScriptRoot\SetupAD.ps1 -taskname $taskname  -CompName $compName -uname $uname -pass $pass"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        Register-ScheduledTask -Action $task -Trigger $trigger -TaskName $taskname -Description "runs to install programs and drivers" -RunLevel Highest
        Write-Host "task created"
    }
   
}
#---------------------------------------------------------------------------------------------------------------------------

#-----------------------------------------Downloads and runs Ninite---------------------------------------------------------

<# gets the ninite installer for the standard CSO programs. Url can be gotten by going and selecting programs clicking on 
download button and copying url. writes it to ninite.exe #>

#name of downloaded program
$ProgInstaller = "ninite.exe"
write-host "Ninite downloading"
#downloads ninite installer (TODO: figure out a selector of sorts order for part below does not matter)
Invoke-WebRequest -outf $ProgInstaller https://ninite.com/.net4.7.2-7zip-air-chrome-firefox-java8-shockwave-silverlight-vlc/ninite.exe
Start-Process .\$ProgInstaller
#runs the ninite installer and closes it when done. run autoit script in exe form
write-host "Ninite installing"
Start-Process ".\niniteauto.exe" -WarningAction SilentlyContinue -Wait
write-host "Ninite successfully installed"
#--------------------------------------------------------------------------------------------------------------------------- 

#-----------------------------------------Installs Dell Command Update------------------------------------------------------

Write-Host "Checking if Dell Command is installed"

#checks to see if Dell Command | Update is installed, if not it is installed
#set the the name for the setup file
$DellC = "dellcommand.exe"
if(Check_Program_Installed('Dell Command | Update')){
    write-host "Downloading Dell Command Update"
    
    #downloads dellcommand and names it
    Invoke-WebRequest -outf $DellC https://downloads.dell.com/FOLDER05055451M/1/Dell-Command-Update_DDVDP_WIN_2.4.0_A00.EXE
    
    Write-host " installing Dell Command Update"

    #runs dell setup for dell command silently
    Start-Process $DellC -WarningAction SilentlyContinue -Wait -ArgumentList "/s"
    
    #alls windows to update that it exists
    Write-host "setting up install"
    Start-Sleep 10
     
}
#---------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------Runs Dell Command Update----------------------------------------------------------
# checks if bitlocker is active
if(Bitlocker_status){
    <#if active suspends bitlocker and runs Dell Command Update. This is done incase of a bios update. If no restart happens
    then bitlocker is resumed as normal#>
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    write-host "bitlocker suspended"

    
    
    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
    
    
    Resume-BitLocker -MountPoint "C:"
    if (Bitlocker_status){
        write-host "Bitlocker reactivated"
    }else{
        write-host "bitlocker reactivation failed"
    }
}else{
    #If no bitlocker run Dell Command Update with out care
    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /log C:\"
    Restart-Computer
}

#---------------------------------------------------------------------------------------------------------------------------s
