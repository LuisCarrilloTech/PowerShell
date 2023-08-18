function Get-RemoteLocalGroupMembers {
    <#
.SYNOPSIS
This PowerShell function retrieves the members of a local group on multiple remote servers.
.DESCRIPTION
Get-RemoteLocalGroupMembers [-computername] <String[]> [-LocalGroup] <String[]> [[-Credential] <SwitchParameter>]
.PARAMETER Servers
-computername <String[]>: Specifies an array of remote server names.
.PARAMETER LocalGroup
-LocalGroup <String[]>: Specifies an array of local group names.
.PARAMETER Credential
-Credential [<SwitchParameter>]: Specifies whether to use a credential for accessing the remote servers. For example domain\useraccont.
.EXAMPLE
Retrieve the members of the "Administrators" local group on multiple remote servers without using different credentials:
.EXAMPLE
Get-RemoteLocalGroupMembers -computername "Server1", "Server2" -LocalGroup "Administrators"
Retrieve the members of the "PowerUsers" local group on multiple remote servers using different credentials:
.EXAMPLE
Get-RemoteLocalGroupMembers -computername "Server1", "Server2" -LocalGroup "PowerUsers" -Credential
Retrieve the members of multiple local groups on a single remote server using different credentials:
.EXAMPLE
Get-RemoteLocalGroupMembers -computername "Server1" -LocalGroup "Administrators", "PowerUsers"
.NOTES
PrincipalSource is supported only by Windows 10, Windows Server 2016, and later versions of the Windows operating system. For earlier versions, the property is blank.

This function requires administrative access to the remote servers in order to retrieve local group information.
If the credential parameter is not specified, the function will attempt to access the remote servers using the current user's credentials.

If an error occurs while retrieving local group information, the function will output an error message.

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

        [Parameter(
            Mandatory = $true)]
        [String[]]$LocalGroup,

        [Parameter()][switch]$Credential

    )

    Begin {
    }
    Process {
        if ($Credential) {
            [System.Management.Automation.PSCredential]$Credential = Get-Credential
            foreach ($server in $computername) {
                try {
                    $results = Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {

                        $localgroup = Get-LocalGroup -Name $using:LocalGroup
                        Get-LocalGroupMember -Group $localgroup
                    } -ErrorAction Stop

                    Write-Output $results | Select-Object Name, ObjectClass, SID
                    Write-Output $_.Exception.Message

                } catch {
                    Write-Output "Error gathering local group info for system: $($server) using $($Credential)"
                    Write-Output $_.Exception.Message

                }
            }

        } else {
            foreach ($server in $computername) {

                try {
                    $results = Invoke-Command -ComputerName $server -ScriptBlock {

                        $localgroup = Get-LocalGroup -Name $using:LocalGroup
                        Get-LocalGroupMember -Group $localgroup
                    } -ErrorAction Stop

                    Write-Output $results | Select-Object Name, ObjectClass, SID
                    Write-Output $_.Exception.Message

                } catch {
                    Write-Output "Error gathering local group info for system: $($server)"
                    Write-Output $_.Exception.Message

                }
            }
        }
    }
}