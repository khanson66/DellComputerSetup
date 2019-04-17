
function Confirm-Installed {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true, 
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $programName
    )
    process {
        $installCount =(Get-ChildItem -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                        Get-ItemProperty -Name DisplayName -ErrorAction SilentlyContinue).DisplayName| 
                        Select-string $programName |
                        Measure-Object -Sum

        if($installCount -gt 0){
            $true
        }else{
            $false
        }

    }
}

function Get-BitLockerStatus{
    [CmdletBinding()]
    param(

    )

    process{
        $BLactive = Get-Bitlockervolume -MountPoint "C:"
        if($BLactive.ProtectionStatus -eq 'On' -and $BLactive.EncryptionPercentage -eq '100'){
            $true
        }else{
            $false
        }
    }
}

function Add-LogonTask {
    #creates task that runs script after reboot and login
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true)]
        [pscredential]
        $Credential,

        [Parameter(Mandatory = $true,
                   ValueFromPipeline =$true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $ComputerName,

        [parameter(Mandatory = $true)]
        [string]
        $FilePath

    )
    begin {
        #"final" Varibles TODO: find a better way to handle
        $taskname = "RunOnLogOn"

        if($Credential){
            if($null -eq $Credential ){

                Write-Error "No credentials given please add domain credentials"

                $Credential = Get-Credential -Message "Please insert your domain credentials"
            }
            
            $uname = $Credential.UserName
            $pass = Convertfrom-securestring $userCred.Password 
        }
        if($ComputerName -eq ""){
            $ComputerName = read-host -prompt "Please get the computername for the new computer. CHECK AD!"
        }
        
        
    }
    
    process {
        $taskexist = Get-ScheduledTask -TaskName $taskname -ErrorAction Ignore

        if ($taskexist){
            #TODO: Add protection like deleting existing. Needs more thought
            write-Verbose "task already made, skipping step"
        }else{
            Write-Verbose "Creating New Task"

            $taskArguments = @{
                noexit = $true
                ExecutionPolicy = Bypass
                Command = $FilePath
                taskname = $taskname
                CompName = $compName 
                uname =  $uname 
                pass =  $pass
            }
            
            $task = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument @taskArguments

            $trigger = New-ScheduledTaskTrigger -AtLogOn

            # TODO get auto deleteing working after one run

            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            
            $registerArguments = @{
                action = $task
                trigger = $trigger
                taskname = $taskname
                settings = $settings
                description = "runs to install programs and drivers"
                runlevel = Highest
            }

            Register-ScheduledTask @registerArguments
            
            Write-Verbose "task created"
        }
       
    }
    
    end {
    }
}
function Confirm-Admin{
    #checks to see if user is admin
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
function Invoke-Download {
    #installs program from given weblocation to the directory it is in
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('uri')]
        [string]
        $url,
        [string]
        $name = ""
    )
    
    begin {
        $ProgressPreference = 'silentlyContinue'    # removes the progress bar for download because slows downlaod  
    }
    
    process {
        #if no name varible it added it parses the name from the url
        
        if($name.Equals("")){
            Write-Verbose "No name inserted"
            $temp = $url.ToCharArray()  
            for ($i = $temp.Count; $i -gt 0; $i--) {
                $letter = $temp.Get($i)
                if($hold.Equals("/")){ 
                    break
                }
                $name = $letter + $name
            }
        }
        
        write-verbose("downloaded files name is " + $name)
        Invoke-WebRequest -outf $ProgInstaller -Uri $url


    }
    
    end {
        $ProgressPreference = 'continue'    #returns to normal operation
        write-verbose "Download finished for " + $name

        #returns name as allow flexablility
        $name
    }
}




