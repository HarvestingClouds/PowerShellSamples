#Input Parameters
$subscriptionName = "Your-Subscription-Name" # subscription name where the VM exists
#This path is only used to export the VM's JSON file in case of any script failures. 
#This should be any folder on your machine that should exist already
$PathForVMExport = "D:\DATA\Scripts\Move-AzVMToAvailabilityZone"
$resourceGroup = "Your-Resource-Group-Name" #Resouce group of the VM
$vmName = "Your-VM-Name" #VM Name
$location = "eastus2" #VM Location
$zone = "1" #Valid Values are 1, 2 or 3

function Export-VMConfig {
    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$True,
        HelpMessage='name of the Virtual Machine')]
      [Alias('vm')]
      [string]$virtualMachineName,
  
      [Parameter(Mandatory=$True,
        HelpMessage='name of the Resource Group of the Virtual Machine')]
      [Alias('rg')]
      [string]$ResourceGroupName,

      [Parameter(Mandatory=$True,
        HelpMessage='directory path for export file')]
      [Alias('path')]
      [string]$PathForVMExport      
    )
      try
      {
          Write-Host "Exporting Information for VM $virtualMachineName."
          $currentVm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $virtualMachineName -ErrorAction Stop
          
          $timeStamp = (Get-Date).ToString("MM-dd-yyyy-HH-mm-ss")
          $fileNameWithPath = ""
          if($PathForVMExport.EndsWith('\'))
          {
          $fileNameWithPath = $PathForVMExport + $virtualMachineName + "-" + $timeStamp + '.json'
          }
          else {
            $fileNameWithPath = $PathForVMExport + "\" + $virtualMachineName + "-" + $timeStamp + '.json'
          }

          Write-Host "Outputing VM configurations for VM $virtualMachineName at time $timeStamp ."
          $currentVm | ConvertTo-Json -Depth 100 | Out-File -FilePath $fileNameWithPath
  
          Write-Host -ForegroundColor Green "Successfully exported the information for the VM $virtualMachineName."
      }
      catch [system.exception]
      {
          Write-Host -ForegroundColor Red "Failed to export the information for VM $virtualMachineName. "
          Write-Host -ForegroundColor Red "Error in exporting VM Config for $virtualMachineName : $($_.Exception.Message) "
          Write-Host -ForegroundColor Red "Error Details are: "
          Write-Host -ForegroundColor Red $Error[0].ToString()
      }
  }

try
{
    #Logging in
    $env = Get-AzEnvironment -Name "AzureCloud"
    Connect-AzAccount -Environment $env
    Set-AzContext -SubscriptionName $subscriptionName

    #Exporting VM Config
    Export-VMConfig -virtualMachineName $vmName -ResourceGroupName $resourceGroup -PathForVMExport $PathForVMExport

    # Get the details of the VM to be moved to the Availability Set
    $originalVM = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName

    # Stop the VM to take a snapshot
    Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Force 

    # Create a SnapShot of the OS disk and then, create an Azure Disk with Zone information
    $snapshotOSConfig = New-AzSnapshotConfig -SourceUri $originalVM.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy -SkuName Standard_ZRS
    $OSSnapshot = New-AzSnapshot -Snapshot $snapshotOSConfig -SnapshotName ($originalVM.StorageProfile.OsDisk.Name + "-snapshot") -ResourceGroupName $resourceGroup 
    $diskSkuOS = (Get-AzDisk -DiskName $originalVM.StorageProfile.OsDisk.Name -ResourceGroupName $originalVM.ResourceGroupName).Sku.Name

    $diskConfig = New-AzDiskConfig -Location $OSSnapshot.Location -SourceResourceId $OSSnapshot.Id -CreateOption Copy -SkuName  $diskSkuOS -Zone $zone 
    $OSdisk = New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroup -DiskName ($originalVM.StorageProfile.OsDisk.Name + "zone")


    # Create a Snapshot from the Data Disks and the Azure Disks with Zone information
    foreach ($disk in $originalVM.StorageProfile.DataDisks) { 

       $snapshotDataConfig = New-AzSnapshotConfig -SourceUri $disk.ManagedDisk.Id -Location $location -CreateOption copy -SkuName Standard_ZRS
       $DataSnapshot = New-AzSnapshot -Snapshot $snapshotDataConfig -SnapshotName ($disk.Name + '-snapshot') -ResourceGroupName $resourceGroup

       $diskSkuData = (Get-AzDisk -DiskName $disk.Name -ResourceGroupName $originalVM.ResourceGroupName).Sku.Name
       $datadiskConfig = New-AzDiskConfig -Location $DataSnapshot.Location -SourceResourceId $DataSnapshot.Id -CreateOption Copy -SkuName $diskSkuData -Zone $zone
       $datadisk = New-AzDisk -Disk $datadiskConfig -ResourceGroupName $resourceGroup -DiskName ($disk.Name + "-zone")
    }

    # Remove the original VM
    Remove-AzVM -ResourceGroupName $resourceGroup -Name $vmName  -Force

    # Create the basic configuration for the replacement VM

    $newVM = New-AzVMConfig -VMName $originalVM.Name -VMSize $originalVM.HardwareProfile.VmSize -Zone $zone

    #Retaining the Tags
    $newVM.Tags = $originalVM.Tags

    #Retaining the Boot diagnostics storage account
    $newVM.DiagnosticsProfile = $originalVM.DiagnosticsProfile

    # Add the pre-existed OS disk 
    if($OSdisk.OsType -eq "Linux")
    {
       Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $OSdisk.Id -Name $OSdisk.Name -Linux
    }
    else {
       Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $OSdisk.Id -Name $OSdisk.Name -Windows
    }
    # Add the pre-existed data disks
    foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
        $datadisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName ($disk.Name + "-zone")
        Add-AzVMDataDisk -VM $newVM -Name $datadisk.Name -ManagedDiskId $datadisk.Id -Caching $disk.Caching -Lun $disk.Lun -DiskSizeInGB $disk.DiskSizeGB -CreateOption Attach 
    }

    # Add NIC(s) and keep the same NIC as primary
    # If there is a Public IP from the Basic SKU remove it because it doesn't supports zones
    foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) 
    {  
        $netInterface = Get-AzNetworkInterface -ResourceId $nic.Id 
        $publicIPId = $netInterface.IpConfigurations[0].PublicIpAddress.Id
        $publicIP = Get-AzPublicIpAddress -Name $publicIPId.Substring($publicIPId.LastIndexOf("/")+1) 
        if ($publicIP)
        {      
            if ($publicIP.Sku.Name -eq 'Basic')
            {
                $netInterface.IpConfigurations[0].PublicIpAddress = $null
                Set-AzNetworkInterface -NetworkInterface $netInterface
            }
        }
        if ($nic.Primary -eq "True")
           {
              Add-AzVMNetworkInterface -VM $newVM -Id $nic.Id -Primary
           }
           else
           {
              Add-AzVMNetworkInterface -VM $newVM -Id $nic.Id 
           }
    }

    # Recreate the VM
    New-AzVM -ResourceGroupName $resourceGroup -Location $originalVM.Location -VM $newVM -DisableBginfoExtension

    Write-Host -ForegroundColor Green "Successfully moved the VM to Availability Zone"
    Write-Host -ForegroundColor Red "MANUAL ACTION REQUIRED: Validate the new VM and then delete the older OS and Data disks and any related snapshots"

}
    catch [system.exception]
	{
		Write-Verbose "Error : $($_.Exception.Message) "
        Write-Host "Error : $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
	}
