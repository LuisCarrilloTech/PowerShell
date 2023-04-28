### # Add vCenter connections here:
$vCenters = @(
    'vcenter-1.domain.com',
    'vcenter-2.domain.com',
    'vcenter-3.domain.com'
)

# Replace with your credentials file path:
$password = Get-Content -Path "C:\path\to\creds.txt" | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PsCredential('username@domain.com', $password)

if ((Get-PowerCLIConfiguration -Scope User).invalidcertificateAction -eq 'Ignore') {
    return
} else {
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope currentUser -Confirm:$false
}

# Checks for vmware powercli module:
if (!(Get-Module vmware.vimautomation.core)) {
    Write-Host -ForegroundColor Yellow "PowerCLI module required to run this CMDlet."
    break
}

Import-Module -Name vmware.vimautomation.core

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
    \n if (!(Get-VM $sys | Get-AdvancedSetting -Name *ctk*).Name) {
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