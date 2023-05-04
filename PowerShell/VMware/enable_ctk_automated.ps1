<#.SYNOPSIS
Below is the automated version of enable_ctk_manual.ps1 located in the same folder. This script allows you to automate the process by creating a scheduled task to run at whatever interval you like. You would export the username and password and retrieve it securely. This user would typically have power user VM access on vCenter.

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

# Add vCenter connections here:
$vCenters = @(
    'vcenter-1.domain.com',
    'vcenter-2.domain.com',
    'vcenter-3.domain.com'
)

# **** Run this once to export password. Comment it out after the first time: ****
(Get-Credential).password | ConvertFrom-SecureString | Set-Content "C:\path\creds.txt"

# Replace with your credentials file path:
$password = Get-Content -Path "C:\path\to\creds.txt" | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PsCredential('username@domain.com', $password)

# Check if VMWare PowerCLI module is installed:
$moduleName = "VMware.VimAutomation.Core"
if (!(Get-Module -Name $moduleName)) {
    try {
        Get-Module -list | Where-Object name -Match $moduleName | Import-Module -ErrorAction Stop
    } catch {
        Write-Error "Error loading $($moduleName). Please make sure it is installed."
        break
    }
} else {
    Write-Verbose "PowerCLI module installed. Proceeding with the script..."
}

# Gives import-module time to complete:
sleep 10

# If you have run this cmdlet before and are still connected to vcenters, function will skip trying to reconnect:
if (!($global:DefaultVIServers)) {

    Foreach ($vc in $vCenters) {
        try {
            Connect-VIServer -Server $vc -Credential $credential -Verbose
        } catch {
            "Error connecting to $vc. Verify vCenter is online or permissions are correct"
            break
        }
    }
}

# Gather VMs:
$cb = Get-Cluster Cluster-1, Cluster-2, Cluster-3 | Get-VM

# Filter VMs:
$ExcludeNames = '<enter any inclusions here>', 'CVM', 'VMware-NSX-Manager'

$excludePattern = $excludeNames -join '|'

$cb2 = $cb | Where-Object {
    $_.ExtensionData.guest.GuestFullname -match "Microsoft Windows Server" -or
    $_.ExtensionData.guest.GuestFullname -match 'Linux' -and
    $_.PowerState -eq 'PoweredOn' -and
    $_.Name -notmatch $excludePattern
}

# Check for missing CBT advanced setting:
$ctkenabled = foreach ($sys in $cb2.Name) {
    if (!(Get-VM $sys | Get-AdvancedSetting -Name *ctk*).Name) {
        Write-Output $sys
    } else {

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
        New-Snapshot $vm -Name "Patching - Enable CBT" -Verbose -ea Stop
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