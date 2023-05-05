# TEST
function Get-VMTools {
    <#
.SYNOPSIS
   This function checks the VMware tools status on one or more virtual machines and returns the name of the virtual machine and VMware tools version installed
.DESCRIPTION
   This function gets the VMware tools status for one or more virtual machines. If VMware tools are not up to date or are not installed, this function will return the virtual machine name and the outdated tools version.
   For this function to work properly, VMware PowerCLI module needs to be installed.
.EXAMPLE
   Get-VMTools -VirtualMachine Luis-VM01
   This example gets the VMware tools status for the virtual machine named "Luis-VM01".
.EXAMPLE
   Get-VM | Get-VMTools
   This example gets all virtual machines and then checks the VMware tools status on each virtual machine.
.INPUTS
   The function accepts an array of strings that specifies one or more virtual machine names.
.OUTPUTS
   The function returns virtual machine name and VMware tools version installed.
.NOTES
   This function requires VMware PowerCLI module to be installed. The function also leverages PowerCLI’s Connect-VIServer cmdlet to connect to the vCenter server. Prompts the user to enter the vCenter server credentials.
.COMPONENT
   This script is a custom function created by Luis Carrillo.
   Github: https://github.com/LuisCarrilloTech
.ROLE
   This script checks the VMware tools status on one or more virtual machines.
.FUNCTIONALITY
   This function checks the VMware tools status on one or more virtual machines.
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            HelpMessage = 'Enter a VM or list of VMs')]
        [ValidateNotNullOrEmpty()]
        [String[]]$VirtualMachine,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false)]
        [string]$vCenters,

        [switch]$Disconnect
    )

    BEGIN {
        # Check if VMWare PowerCLI module is installed:
        $moduleName = "VMware.VimAutomation.Core"
        if (!(Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -Force
        } else {
            Write-Output "Loading module. Please wait..."
        }

        # Prompt user to input vCenter FQDN and connect to server:
        if (!($global:DefaultVIServers)) {

            [System.Management.Automation.PSCredential]$Credential = Get-Credential

            foreach ($vcenter in $vCenters) {
                # Connect to vCenter server:
                try {
                    Connect-VIServer -Server $vCenter -Credential $Credential -ErrorAction Stop
                    Write-Host "Connected to vCenter $($vCenter)"
                } catch [VMware.Vim.VimException] {
                    Write-Error "Failed to connect to vCenter. Please verify your credentials and try again."
                    break
                } catch {
                    Write-Error "An error occurred. Please try again."
                    break
                }
            }
        }
    }
    PROCESS {
        foreach ($VM in $VirtualMachine) {
            try {
                $vmTools = Get-VM $VM -ErrorAction Stop
                if ($vmTools.ExtensionData.Guest.ToolsStatus -ne "ToolsOK") {
                    Write-Host -ForegroundColor DarkYellow "VMware Tools out of date on VM $($VM.Name)"
                    Write-Verbose "VMware Tools - out of date on VM $($VM.Name)"
                    $vmTools | Select-Object Name, @{
                        N = "ToolsVersion"
                        E = { $_.ExtensionData.Guest.Toolsversion }
                    }
                }

                else {
                    Write-Host -ForegroundColor Green "VMTools - OK on VM $VM"
                    Write-Verbose "VMware Tools OK on VM $VM"
                    $vmTools | Select-Object Name, @{
                        N = "ToolsVersion"
                        E = { $_.ExtensionData.Guest.Toolsversion }
                    }
                }
            } catch {
                Write-Error "An error occurred while trying to retrieve VMware Tools information on VM $($VM.Name)"
            }
        }

        # Disconnect from vCenter:
        if ($Disconnect) {
            $global:DefaultVIServers | Disconnect-VIServer -Force -Confirm:$false
            Write-Output "Disconnected from vCenter $($vCenter)."
        } else {
            Write-Output "vCenter(s) $($vCenters) still connected."
        }

    }
    END {
    }
}
