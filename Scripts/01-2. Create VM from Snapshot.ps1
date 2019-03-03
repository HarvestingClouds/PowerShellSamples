
#Add-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName "Subscription Name"

#Prepare the VM parameters 
$rgName = "Resource Group Name"
$location = "eastus2"
$vnet = "vNet-Name-USE2"
$subnet = "/subscriptions/aaaaaaa-1111-1111-1111-aaaaaaaaa/resourceGroups/RG-Dev-USE2/providers/Microsoft.Network/virtualNetworks/vNet-Name-USE2/subnets/sNet-Name-USE2"
$nicName = "VMName-nic"
$vmName = "VMName"
$osDiskName = "VMName-osdisk"
$osDiskUri = "https://StorageAccountName.blob.core.windows.net/vhds/VMName-osdisk.vhd"
$VMSize = "Standard_F8s_v2"
$storageAccountType = "StandardLRS"
$IPaddress = "192.168.0.5"

#Create the VM resources
$IPconfig = New-AzureRmNetworkInterfaceIpConfig -Name "IPConfig1" -PrivateIpAddressVersion IPv4 -PrivateIpAddress $IPaddress -SubnetId $subnet
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -IpConfiguration $IPconfig
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $VMSize
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id

$osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk (New-AzureRmDiskConfig -AccountType $storageAccountType -Location $location -CreateOption Import -SourceUri $osDiskUri) -ResourceGroupName $rgName
$vm = Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -StorageAccountType $storageAccountType -DiskSizeInGB 128 -CreateOption Attach -Windows
$vm = Set-AzureRmVMBootDiagnostics -VM $vm -disable

#Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -LicenseType "Windows_Server"