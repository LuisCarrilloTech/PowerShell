Function Get-ADLockedAccount {
    <#
    .SYNOPSIS
This function will retrieve lockout events from a primary domain controller (PDC) by checking event viewer for event ID 4740. The function requires domain admin access.

.DESCRIPTION
The Get-ADLockedAccount function will query PDC domain controller for the specified domain to retrieve event logs for lockout events. The function will display the information in a table that includes the username, time of lockout, computer name, and caller computer. Use the -Domain parameter to specify the domain to check. Use the -Username parameter to restrict the output to events for a specific user. Use the -DaysAgo parameter to specify the number of days to check in the event logs (default is 3 days).

.PARAMETER Domain
Specifies the domain to check.

.PARAMETER Username
Specifies the username for which to retrieve lockout events. This parameter accepts a string array.

.PARAMETER DaysAgo
Specifies the number of days to check in the event logs.

.EXAMPLE
Get-ADLockedAccount -Username "username1", "username2" -Domain "mydomain.local" -DaysAgo 2 | Format-List

This example will generate a list of lockout events for the specified usernames on the primary domain controller for the "mydomain.local" domain, for events occurring in the last 2 days.

Use Format-List to expand the results.

.NOTES
Author: Luis Carrillo
GitHub: https://www.github.com/LuisCarrilloTech
    #>

    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0            )]
        [string[]]$Username,

        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Domain,

        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [int]$DaysAgo
    )


    PROCESS {

        Foreach ($User in $Username) {

            $filter = @{
                Logname   = 'security'
                Id        = 4740
                StartTime = (Get-Date).AddDays(-$DaysAgo)
                Data      = $User
            }

            Get-WinEvent -ComputerName ((Get-ADDomain -Server $Domain).PDCEmulator) -FilterHashtable $filter | Select-Object * -First 5 | Select-Object timecreated, message
        }
    }

}