<#.SYNOPSIS
This script enables Changed Block Tracking (CBT) on virtual machines in vCenter. Essentially, it allows for updating the Change Block Tracking on a VM through CLI. Normally, changing advanced settings on a powered ON VM requires shutting it down before modifying the settings. However, this script allows for the VM to remain powered ON while modifying the settings.

.DESCRIPTION
This script connects to vCenter and checks for the CBT advanced setting. If the setting is missing, the script creates a snapshot, enables CBT, and deletes the snapshot.


.PARAMETER vCenter
An array of vCenter server that the script will connect to.


.PARAMETER Credential
A PsCredential object containing the vCenter administrator credentials.


.PARAMETER ExcludeNames
An array of virtual machine names to exclude from being checked for CBT.

.NOTES
Author: Luis Carrillo
Date: 02/14/2023
Version: 1.0
#>

# Checks for vmware powercli module:
$moduleName = "VMware.vimautomation.core"
if (!(Get-Module -Name $moduleName -ErrorAction SilentlyContinue)) {
    Write-Warning "The PowerCLI module is required to run this script. Installing $moduleName module now..."
    try {
        Install-Module -Name $moduleName -Confirm:$false -Scope AllUsers -Force
    } catch {
        Write-Error "Failed to install $moduleName module. Please verify that you have an active internet connection and that you have sufficient permissions to install modules."
        exit 1
    }
} else {
    Write-Host "PowerCLI module is already installed."
    Import-Module -Name $moduleName -Force -Verbose
}

# You can add one or more servers to the list. Just make sure the last server has no comma at the end of the line
[string[]]$ctkenabled = Read-Host -Prompt "Enter VM Names followed by commas if entering multiple vms"

# Check and connect to vCenter:
$vcenter = Read-Host -Prompt "Enter vCenter FQDN"

if (!($global:DefaultVIServers)) {

    try {
        $username = Read-Host -Prompt "Enter Username to connect to vCenter"
        $userpassword = Read-Host -Prompt "Enter vCenter password\" -AsSecureString
        Connect-VIServer -Server $vcenter -User $username -Password $userpassword -ErrorAction Stop

    } catch {
        Write-Output "The vCenter cannot be resolved. Verify $($vcenter) is online."
        break
    }
}

# Start enabling CBT setting:
foreach ($vm in $ctkenabled) {
    try {
        $vmview = Get-VM $vm -ErrorAction Stop | Get-View
        $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    } catch {
        "Error with system $($vm)"
    }

    # Create snapshot before ctk enabled and set setting:
    try {
        New-Snapshot $vm -Name "ISD-Patching - Enable CBT" -Verbose -ea Stop
        $vmConfigSpec.changeTrackingEnabled = $true
        $vmview.reconfigVM($vmConfigSpec)
    } catch {
        "Error with system $($vm)"
    }

    Start-Sleep 15

    # Verify CBT is enabled, if so, delete pre cbt setting snapshot:
    if ((Get-VM $vm | Get-AdvancedSetting -Name ctkEnabled).value -eq $true) {
        Get-VM $vm | Get-Snapshot -Name "*Enable CBT*" | Remove-Snapshot -Verbose -Confirm:$false
    } else {
        Write-Output "CBT NOT Enabled on VM: $($vm)"
    }
}