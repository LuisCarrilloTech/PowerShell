function Get-RemoteLocalGroup {
    <#
.SYNOPSIS
This PowerShell function retrieves the local groups on remote computers.

.DESCRIPTION
The Get-RemoteLocalGroup function allows you to retrieve the local groups on one or multiple remote computers. It can be used with or without providing specific credentials for remote authentication.

.PARAMETER ComputerName
Specifies the name(s) of the remote computer(s). You can provide multiple computer names separated by commas.

.PARAMETER Credential
Switch parameter. If specified, you will be prompted to provide credentials for remote authentication. If not specified, the function will attempt to retrieve the local groups using the current user's credentials.

.EXAMPLE
Get-RemoteLocalGroup -ComputerName "Server01, Server02, Server03" -Credential
Prompts for credentials and retrieves the local groups on Server01, Server02, and Server03 using the provided credentials.

.EXAMPLE
Get-RemoteLocalGroup -ComputerName "Server04"
Retrieves the local groups on Server04 using the current user's credentials.

.NOTES
PrincipalSource is supported only by Windows 10, Windows Server 2016, and later versions of the Windows operating system. For earlier versions, the property is blank.

Author: Luis Carrillo
GitHub: https://www.github.com/LuisCarrilloTech
#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [String[]]$computername,

        [Parameter()][switch]$Credential

    )

    Begin {
    }
    Process {
        if ($Credential) {
            [System.Management.Automation.PSCredential]$Credential = Get-Credential
            foreach ($server in $computername) {
                try {
                    Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
                        Get-LocalGroup | Sort-Object
                    } -ErrorAction Stop
                } catch {
                    Write-Output "Error gathering local group info for system: $($server) using $($Credential)"
                    Write-Output $_.Exception.Message
                }
            }

        } else {
            foreach ($server in $computername) {

                try {
                    Invoke-Command -ComputerName $server -ScriptBlock {
                        Get-LocalGroup | Sort-Object
                    } -ErrorAction Stop
                } catch {
                    Write-Output "Error gathering local group info for system: $($server)"
                    Write-Output $_.Exception.Message
                }
            }
        }
    }
}
