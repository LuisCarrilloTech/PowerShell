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
Version: 1.1
#>

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
    Write-Host "PowerCLI module installed. Proceeding with the script..."
}

# Prompt user to input vCenter FQDN and connect to server:
if (!($global:DefaultVIServers)) {

    $vcenter = Read-Host -Prompt "Enter vCenter FQDN"
    while ((Test-Connection -ComputerName $vcenter -Quiet) -eq $false) {
        Write-Host "Please enter a valid FDQN for vCenter"
        $vcenter = Read-Host -Prompt "Enter vCenter FQDN"
    }

    # Prompt user for credentials and connect to vCenter:
    try {
        $credentials = Get-Credential -Message "Enter vCenter administrator credentials"
        Connect-VIServer -Server $vcenter -Credential $credentials -ErrorAction Stop
        Write-Host "Connected to vCenter $($vcenter)"
    } catch [VMware.Vim.VimException] {
        Write-Error "Failed to connect to vCenter. Please verify your credentials and try again."
    } catch {
        Write-Error "An error occurred. Please try again."
    }
}

# Prompt user to input VM names separated by commas and enable CBT on each VM:
$ctkenabled = Read-Host -Prompt "Enter VM Name(s) separated by commas ',' & no spaces. i.e. vm1,vm2,vm3"
$ctkenabled = $ctkenabled.Split(',')

foreach ($vm in $ctkenabled) {
    try {
        # Check if VM exists and get view object:
        $vmview = Get-VM $vm -ErrorAction Stop | Get-View
        $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    } catch {
        Write-Error "Failed to find VM $($vm). Please verify the VM name and try again."
        continue
    }

    # Create snapshot before enabling CBT and set setting:
    try {
        New-Snapshot $vm -Name "Prior to enabling CBT" -Verbose -ea Stop

    } catch {
        Write-Error "Failed to create snapshot for $($vm). Please verify try again."
        continue
    }

    # Enable CBT:
    $vmConfigSpec.changeTrackingEnabled = $true
    $vmview.reconfigVM($vmConfigSpec)

    # Wait for task to complete:
    Start-Sleep 15

    # Verify CBT is enabled, if so, delete pre cbt setting snapshot:
    if ((get-vm $vm | Get-AdvancedSetting -Name $ctkenabled).value) {
        Write-Host "CBT enabled on VM $($vm)."
        # Remove snapshot:
        try {
            Get-Snapshot -VM $vm -Name "Prior to enabling CBT" | Remove-Snapshot -Confirm:$false -ErrorAction Stop
            Write-Host "Snapshot removed."
        } catch {
            Write-Error "Failed to remove snapshot. Please check if the snapshot exists and try again."
            continue
        }
    }
}

# Disconnect from vCenter:
try {
    Disconnect-VIServer -Server $vcenter -Confirm:$false -ErrorAction Stop
    Write-Host "Disconnected from vCenter $($vcenter)."
} catch {
    Write-Error "Failed to disconnect from vCenter $($vcenter)."
}