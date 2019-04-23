Import-Module .\Configuration.psm1
. .\ConfigVar.ps1
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