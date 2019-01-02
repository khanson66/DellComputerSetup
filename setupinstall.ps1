
#-----------------------------------------this obtains admin privialages----------------------------------------------------
#Must be the first part of program
param([switch]$Elevated)
function Check-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Check-Admin) -eq $false)  {
    if ($elevated){
        write-host "could not elevate, please quit"
    }else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    
    exit
}
#---------------------------------------------------------------------------------------------------------------------------


#-----------------------------------------checks to see is called program is installed--------------------------------------
function Check_Program_Installed( $programName ) {

    #runs query to get all the objects with the name inputed the number of objects which is measured and counted 
    $wmi_check = (Get-WMIObject -Query "SELECT * FROM Win32_Product Where Name Like '$programName'" | measure).count 

    # if there are no object 0 is the returned by the above statment and the function returns true else false
    if($wmi_check -like "0"){
        return $true
    }else{
        return $false
    }

}
#---------------------------------------------------------------------------------------------------------------------------

#-----------------------------------------checks to see is bitlocker is active and at 100%----------------------------------
function Bitlockerstatus{

    # loads bitlocker volume on the C drive to the varible
    $BLinfo = Get-Bitlockervolume -MountPoint "C:"

    #checks to see if it is active and if it is at 100%
    if($blinfo.ProtectionStatus -eq 'On' -and $blinfo.EncryptionPercentage -eq '100'){
       return $true
    }else{
        return $false
    }
}
#---------------------------------------------------------------------------------------------------------------------------

#assures that the current directory pointer is in the CSOSetup folder
write-host $PSScriptRoot
cd $PSScriptRoot


#-----------------------------------------Downloads and runs Ninite---------------------------------------------------------

<# gets the ninite installer for the standard CSO programs. Url can be gotten by going and selecting programs clicking on 
download button and copying url. writes it to ninite.exe #>

wget -outf ninite.exe https://ninite.com/.net4.7.2-7zip-air-chrome-firefox-java8-shockwave-silverlight-vlc/ninite.exe

#runs the ninite installer and closes it when done. run autoit script in exe form
Start-Process .\ninite-silent.exe -Wait
write-host "Ninite successfully installed"
#--------------------------------------------------------------------------------------------------------------------------- 

#-----------------------------------------Installs Dell Command Update------------------------------------------------------

Write-Host "Checking if Dell Command is installed"

#checks to see if Dell Command | Update is installed, if not it is installed

if(Check_Program_Installed('Dell Command | Update')){
    write-host "Downloading Dell Command Update"
    
    wget -outf dellcommand.exe https://downloads.dell.com/FOLDER05055451M/1/Dell-Command-Update_DDVDP_WIN_2.4.0_A00.EXE
    
    Write-host " installing Dell Command Update"

    .\dellcommand.exe /s
    
     
}
#---------------------------------------------------------------------------------------------------------------------------



#-----------------------------------------Break to allow windows to update manifests----------------------------------------
Write-host "setting up"
Start-Sleep 15
#---------------------------------------------------------------------------------------------------------------------------




#-----------------------------------------Runs Dell Command Update----------------------------------------------------------
# checks if bitlocker is active
if(Bitlockerstatus){
    <#if active suspends bitlocker and runs Dell Command Update. This is done incase of a bios update. If no restart happens
    then bitlocker is resumed as normal#>
    Suspend-BitLocker -MountPoint "C:" -RebootCount 0
    write-host "bitlocker suspended"
    write-host " "
    write-host " "
    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
    write-host " "
    write-host " "
    write-host "bitlocker resumed"
    Resume-BitLocker -MountPoint "C:"

}else{
    #If no bitlocker run Dell Command Update with out care
    invoke-expression "C:\'Program Files (x86)'\Dell\CommandUpdate\dcu-cli.exe /reboot /log C:\"
    
}

#---------------------------------------------------------------------------------------------------------------------------s
