function Get-DiskInfo {
    <#
    .SYNOPSIS
        Gathers disk information from system.

    .DESCRIPTION
        Gathers and displays disk information along with drive letters, disk size allocated and disk usage.

    .PARAMETER ComputerName
        Specifies the name(s) of the remote computer(s) to obtain disk information from.

   .NOTES
         Author: Luis Carrillo
         GitHub: https://www.github.com/LuisCarrilloTech

    .EXAMPLE
        PS> Get-DiskInfo -ComputerName server1
        Retrieves disk information for the specified server.

    .EXAMPLE
        PS> $computername = @('server1', 'server2', 'server3')
        PS> $computername | foreach-object {Get-DiskInfo -computername $_}
        Created a array of systems and pass them thru Get-DiskInfo.

   .EXAMPLE

         Get-DiskInfo -ComputerName Server01

         SystemName Drive Size_GB UsedSpace_GB FreeSpace_GB PercentFree
         ---------- ----- ------- ------------ ------------ -----------
         Server01     C:    79.5    32.6         46.9         59
         Server01     D:    3,899.9 3,511.3      388.6        10
         Server01     E:    69.9    44.3         25.6         37
         Server01     F:    299.9   62.3         237.6        79
         Server01     G:    249.9   37.3         212.6        85
         Server01     J:    1,123.9 877.5        246.4        22
         Server01     K:    1,149.9 1,056.5      93.4         8
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName
    )

    foreach ($item in $ComputerName) {
        try {
            Write-Verbose "Gathering disk information for $item machine. Please wait..."
            $diskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3' -ComputerName $item -ErrorAction stop | ForEach-Object {
                [PSCustomObject] @{
                    SystemName   = $_.SystemName
                    Drive        = $_.DeviceID
                    Size_GB      = '{0:N1}' -f ($_.Size / 1GB)
                    UsedSpace_GB = '{0:N1}' -f (($_.size / 1GB) - ($_.freespace / 1GB))
                    FreeSpace_GB = '{0:N1}' -f ($_.FreeSpace / 1GB)
                    PercentFree  = '{0:N0}' -f (($_.freespace * 100) / $_.Size)
                }
            }

            $diskInfo | Format-Table -AutoSize
        } catch {
            Write-Error -Message "Error retrieving disk info for $($item): $($_.Exception.Message)"
        }
    }
}

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
                    Write-Output "$($Credential) - Error gathering local group info for system: $($server)"
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
                }
            }
        }
    }
}
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

                } catch {
                    Write-Output "($Credential) - Error gathering local group info for system: $($server)"

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

                } catch {
                    Write-Output "Error gathering local group info for system: $($server)"

                }
            }
        }
    }
}
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

                        Add-LocalGroupMember -Group $localgroup -Member $members
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
