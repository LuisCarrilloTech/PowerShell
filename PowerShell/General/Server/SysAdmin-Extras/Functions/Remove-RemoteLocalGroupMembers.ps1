Function Remove-RemoteLocalGroupMembers {
    <#
.SYNOPSIS
Remove-RemoteLocalGroupMembers
This PowerShell function removes members from a local group on remote servers.
.DESCRIPTION
Remove-RemoteLocalGroupMembers -computername <String[]> -LocalGroup <String[]> -Members <String[]> [-Credential]

The Remove-RemoteLocalGroupMembers function removes specified members from the specified local groups on the specified remote servers. It uses PowerShell remoting to execute the necessary commands on the remote servers.
.EXAMPLE
Remove members from a local group on remote servers
$computername = "Server01", "Server02"
$localGroup = "Administrators"
$members = "User01", "User02"

Remove-RemoteLocalGroupMembers -computername $computername -LocalGroup $localGroup -Members $members
.EXAMPLE
Remove members from a local group on remote servers with different credentials
$computername = "Server03", "Server04"
$localGroup = "Power Users"
$members = "User03", "User04"
$credential = Get-Credential

Remove-RemoteLocalGroupMembers -computername
.PARAMETER computername
-computername <String[]>: Specifies the names of the remote servers from which to remove the local group members.
.PARAMETER LocalGroup
-LocalGroup <String[]>: Specifies the names of the local groups from which to remove the members.
.PARAMETER Members
-Members <String[]>: Specifies the names of the members to remove from the local groups.
.PARAMETER Credential
-Credential: Optional. Indicates that a credential is required to connect to the remote servers. If not provided, the function will run with the current user's credentials.
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

        [Parameter(
            Mandatory = $true)]
        [String[]]$LocalGroup,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [String[]]$Members,

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
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup
                        $members = $using:Members

                        Remove-LocalGroupMember -Group $localgroup -Member $members
                    } -ErrorAction Stop

                } catch {
                    Write-Output "Error modifying local group for system: $($server)"
                }

                try {
                    Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup

                        Get-LocalGroupMember -Group $localgroup
                    } -ErrorAction Stop

                } catch {
                    Write-Output "$($Credential) - Error gathering local group info for system: $($server)"

                }
            }

        } else {
            foreach ($server in $computername) {
                try {
                    Invoke-Command -ComputerName $server -ScriptBlock {
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup
                        $members = $using:Members

                        Remove-LocalGroupMember -Group $localgroup -Member $members
                    } -ErrorAction Stop

                } catch {
                    Write-Output "Error modifying local group for system: $($server)"
                }

                try {
                    Invoke-Command -ComputerName $server -ScriptBlock {
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup
                        Get-LocalGroupMember -Group $localgroup
                    } -ErrorAction Stop

                } catch {
                    Write-Output "Error gathering local group info for system: $($server)"

                }
            }
        }
    }
}