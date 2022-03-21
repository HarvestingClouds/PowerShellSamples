<# 	
 .NOTES
	==============================================================================================
	File:		Get-AzResourceInfo-VMsAndAllRelatedDisks.ps1
	
	Purpose:	To get the report of all the VM resources and related OS and data disks in Azure in a specific Resource Group
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Azure Resources Report Generation Script for a specific Resource Group
  
 .DESCRIPTION
	This script is used to get the report for all the VM resources and related OS and data disks in Azure in a specific Resource Group. 
		
 .EXAMPLE
	C:\PS>  .\Get-AzResourceInfo-VMsAndAllRelatedDisks.ps1
	
	Description
	-----------
	This command executes the script with default parameters.
     
 .INPUTS
    None.

 .OUTPUTS
    CSV file.
		   
 .LINK
	None.
#>

#Input
#Empty

#Output Path variable to the CSV file. This file will be created. IT should not be present. Only the path should be present.
$PathToOutputCSVReport = "D:\DATA\Scripts\Resource reports\ResourceReportVMAndDisks.csv"

#Adding Azure Account and Subscription
$env = Get-AzEnvironment -Name "AzureCloud"
Connect-AzAccount -Environment $env

#Creating Output Object
$results = @()

#Get all subscriptions
$allSubscriptions = Get-AzSubscription

foreach($currentSubscription in $allSubscriptions)
{
    #Selecting current subscription
    Select-AzSubscription -SubscriptionId $currentSubscription.Id

    #Selecting all RGs that begins with the text. Notice the wildcard in the name
    $allFilteredRGs = Get-AzResourceGroup -Name "*"

    foreach($currentRG in $allFilteredRGs)
    {
        #Fetch all resources in the RG
        $resources = Get-AzResource -ResourceGroupName $currentRG.ResourceGroupName
    
        foreach($resource in $resources)
        {
            #Declaring Variables
            $vmSize = ""
            $name = $resource.Name
            $diskSize = ""
            $diskType = ""
            $attachedToVM = ""
            $LUNNumber = ""
            $osType = ""
            $osDiskName = ""
            $osDiskSize = ""
            $osDiskType = ""
            $dataDiskName = ""
            $dataDiskSize = ""
            $dataDiskType = ""
            $dataDiskLUN = ""
            $dataDiskType = ""

            if($resource.Type -eq "Microsoft.Compute/virtualMachines")
            {
                #Write-Output "VM Found"
                # 1. VM
                $vm = Get-AzVM -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
                $vmSize = $vm.HardwareProfile.VmSize
                $attachedToVM = $vm.Name
                $storageProfile = $vm.StorageProfile
                $osType = $storageProfile.OsDisk.OsType

                #region Adding VM details to results
                $details = @{            
                    Name = $resource.Name
                    OsType = $osType
                    ResourceId = $resource.ResourceId
                    ResourceType = $resource.ResourceType
                    OSOrDataDisk = ""
                    ResourceGroupName =$resource.ResourceGroupName
                    Location = $resource.Location
                    SubscriptionId = $currentSubscription.Id 
                    SubscriptionName = $currentSubscription.Name
                    Sku = $resource.Sku.Name
                    VMSize = $vmSize
                    diskSize = $diskSize
                    diskType = $diskType
                    attachedToVM = $attachedToVM
                    LUNNumber = $LUNNumber
                    Caching = ""
                    WriteAcceleratorEnabled = ""
                }                           
                $results += New-Object PSObject -Property $details 
                #endregion

                # 2 OS Disk
                #OS Disk Info
                $osDiskName = $storageProfile.OsDisk.Name
                $osDiskSize = $storageProfile.OsDisk.DiskSizeGB
                $osDiskType = $storageProfile.OsDisk.ManagedDisk.StorageAccountType
                $osDiskCaching = $storageProfile.OsDisk.Caching
                $osDiskWriteAcceleratorEnabled = $storageProfile.OsDisk.WriteAcceleratorEnabled
                

                #region Adding OS Disk details to results
                $details = @{            
                    Name = $osDiskName
                    OsType = $osType
                    ResourceId = ""
                    ResourceType = "Microsoft.Compute/disks"
                    OSOrDataDisk = "OS Disk"
                    ResourceGroupName =$resource.ResourceGroupName
                    Location = $resource.Location
                    SubscriptionId = $currentSubscription.Id 
                    SubscriptionName = $currentSubscription.Name
                    Sku = $resource.Sku.Name
                    VMSize = $vmSize
                    diskSize = $osDiskSize
                    diskType = $osDiskType
                    attachedToVM = $attachedToVM
                    LUNNumber = $LUNNumber
                    Caching = $osDiskCaching
                    WriteAcceleratorEnabled = $osDiskWriteAcceleratorEnabled
                }                           
                $results += New-Object PSObject -Property $details 
                #endregion

                # 3 Data Disks
                #Data Disks
                $dataDisks = $storageProfile.DataDisks

                foreach ($dataDisk in $dataDisks) 
                {
                    $dataDiskName = $dataDisk.Name
                    $dataDiskSize = $dataDisk.DiskSizeGB
                    $dataDiskType = $dataDisk.OsDisk.ManagedDisk.StorageAccountType
                    $dataDiskLUN = $dataDisk.Lun
                    $dataDiskCaching = $dataDisk.Caching
                    $dataDiskWriteAcceleratorEnabled = $dataDisk.WriteAcceleratorEnabled
                    
                    $diskDetails = Get-AzDisk -ResourceGroupName $resource.ResourceGroupName -DiskName $dataDiskName
                    $dataDiskType = $diskDetails.Sku.Name

                    #region Adding Data Disk details to results
                    $details = @{            
                        Name = $dataDiskName
                        OsType = $osType
                        ResourceId = ""
                        ResourceType = "Microsoft.Compute/disks"
                        OSOrDataDisk = "Data Disk"
                        ResourceGroupName =$resource.ResourceGroupName
                        Location = $resource.Location
                        SubscriptionId = $currentSubscription.Id 
                        SubscriptionName = $currentSubscription.Name
                        Sku = $resource.Sku.Name
                        VMSize = $vmSize
                        diskSize = $dataDiskSize
                        diskType = $dataDiskType
                        attachedToVM = $attachedToVM
                        LUNNumber = $dataDiskLUN
                        Caching = $dataDiskCaching
                        WriteAcceleratorEnabled = $dataDiskWriteAcceleratorEnabled
                    }                           
                    $results += New-Object PSObject -Property $details 
                    #endregion
                }
            }
        }
    }
}

#Exporting to CSV
$results | export-csv -Path $PathToOutputCSVReport -NoTypeInformation
