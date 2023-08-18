function Add-RemoteLocalGroupMembers {
    <#
.SYNOPSIS
    Gathers disk information from system.
.DESCRIPTION
Add-RemoteLocalGroupMembers -computername <String[]> -LocalGroup <String[]> -Members <String[]> [-Credential]
The Add-RemoteLocalGroupMembers function is a PowerShell cmdlet that allows you to add members to a local group on remote computers. It provides the flexibility to specify multiple remote servers, local group names, and members to be added.
.EXAMPLE
Add-RemoteLocalGroupMembers -computername "Server1", "Server2" -LocalGroup "Administrators" -Members "User1", "User2"
This command will add "User1" and "User2" as members of the "Administrators" local group on "Server1" and "Server2" remote servers.

.EXAMPLE
Add-RemoteLocalGroupMembers -computername "Server3" -LocalGroup "Power Users" -Members "User3" -Credential
This command will add "User3" as a member of the "Power Users" local group on "Server3" remote server using the provided credentials.

.EXAMPLE
Add-RemoteLocalGroupMembers -computername "Server4" -LocalGroup "Users", "Backup Operators" -Members "User4", "User5"
This command will add "User4" and "User5" as members of the "Users" and "Backup Operators" local groups on "Server4" remote server.
.PARAMETER computername
-computername (mandatory): Specifies the list of remote servers to which the members will be added to the local group. Multiple server names can be provided.

.PARAMETER LocalGroup
-LocalGroup (mandatory): Specifies the name of the local group to which the members will be added. Multiple group names can be provided.

.PARAMETER Members
-Members (mandatory): Specifies the list of members to be added to the local group. Multiple member names can be provided.

.PARAMETER Credential
-Credential (optional): Used to pass credentials for authentication when accessing remote servers. If not provided, it will use the current user's credentials.

.NOTES
PrincipalSource is supported only by Windows 10, Windows Server 2016, and later versions of the Windows operating system. For earlier versions, the property is blank.

The Add-RemoteLocalGroupMembers function requires administrative privileges on the remote computers to modify local groups.
If the -Credential parameter is provided, the function will prompt for username and password credentials.

.LINK
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

                        Add-LocalGroupMember -Group $localgroup -Member $members
                    } -ErrorAction Stop

                } catch {
                    Write-Output "Error modifying local group for system: $($server) using $($Credential)"
                    Write-Output $_.Exception.Message
                }

                try {
                    Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup

                        Get-LocalGroupMember -Group $localgroup
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
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup
                        $members = $using:Members

                        Add-LocalGroupMember -Group $localgroup -Member $members
                    } -ErrorAction Stop

                } catch {
                    Write-Output "Error modifying local group for system: $($server)"
                    Write-Output $_.Exception.Message
                }

                try {
                    Invoke-Command -ComputerName $server -ScriptBlock {
                        $localgroup = Get-LocalGroup -Name $using:LocalGroup

                        Get-LocalGroupMember -Group $localgroup
                    } -ErrorAction Stop

                } catch {
                    Write-Output "Error gathering local group info for system: $($server)"
                    Write-Output $_.Exception.Message

                }
            }
        }
    }
}