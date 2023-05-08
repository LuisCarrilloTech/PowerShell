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
        PS> $servers = @('server1', 'server2', 'server3')
        PS> $servers | foreach-object {Get-DiskInfo -computername $_}
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