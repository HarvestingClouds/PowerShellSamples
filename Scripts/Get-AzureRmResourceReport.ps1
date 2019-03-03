<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Microsoft Corporation.  All rights reserved.   
	
	File:		Get-AzureRmResourceReport.ps1
	
	Purpose:	To get the report of all the resources in Azure
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Azure Resources Tags Report Generation Script
  
 .DESCRIPTION
	This script is used to get the report for tags of all the resources in Azure. 
		
 .EXAMPLE
	C:\PS>  .\Get-AzureRmVMDiskDetails.ps1 -SubscriptionName "Your-Subscription-Name-Here"  
	
	Description
	-----------
	This command executes the script with default parameters. Replace the value for SubscriptionName parameter as per your environment.
     
 .PARAMETER SubscriptionName
    This is the name of the subscription for which you want the report. 
 
 .INPUTS
    None.

 .OUTPUTS
    None.
		   
 .LINK
	None.
#>

#Input
$rgNameString = "metertocash"

#Path variable to the CSV file
$PathToOutputCSVReport = "C:\DATA\ResourceReport.csv"

#Adding Azure Account and Subscription
#Add-AzureRmAccount

#Getting all Azure Subscriptions
$subs = Get-AzureRmSubscription

#Checking if the subscriptions are found or not
if(($subs -ne $null) -or ($subs.Count -gt 0))
{
    #Creating Output Object
    $results = @()

    #Iterating over various subscriptions
    foreach($sub in $subs)
    {
        $SubscriptionId = $sub.SubscriptionId
        #Selecting the Azure Subscription
        Select-AzureRmSubscription -SubscriptionId $SubscriptionId

        #Getting all Azure Resources
        $resources = Get-AzureRmResource

        foreach($resource in $resources)
        {
            if($resource.ResourceGroupName -like "*$rgNameString*")
            {
            #Declaring Variables
            $TagsAsString = ""
            $ApplicationOwner = ""
            $ApplicationType = ""
            $CostCenter = ""
            $Department = ""
            $BuildDate = ""
            $ApplicationCategory = ""
            $vmSize = ""
            $sqlTier = ""
            $sqlCapacity = ""
            $name = $resource.Name

            if($resource.Type -eq "Microsoft.Compute/virtualMachines")
            {
                #Write-Output "VM Found"
                $vm = Get-AzureRmVM -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
                $vmSize = $vm.HardwareProfile.VmSize
            }
            
            elseif($resource.Type -eq "Microsoft.Sql/servers/databases")
            {
                #$vm = Get-AzureRmVM -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
                #$vmSize = $vm.HardwareProfile.VmSize
                #Get-AzureRmSqlDatabase -DatabaseName $resource.Name -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.ResourceId.Split('/')[8]

                #$sql = Get-AzureRmSqlDatabaseUpgradeHint -DatabaseName $resource.ResourceId.Split('/')[10] -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.ResourceId.Split('/')[8]
                
                $sql = Get-AzureRmResource -ResourceGroupName $resource.ResourceGroupName -ResourceType Microsoft.Sql/servers/databases -ResourceName "$name" -ApiVersion 2017-10-01-preview 
                $sqlTier = $sql.Sku.tier
                $sqlCapacity = $sql.Sku.capacity
            }
            elseif($resource.Type -eq "Microsoft.Compute/disks")
            {
                $disk = Get-AzureRmResource -ResourceGroupName $resource.ResourceGroupName -ResourceType "Microsoft.Compute/disks" -ResourceName "$name" -ApiVersion 2017-10-01-preview 
            }
            

            

            #Fetching Tags
            $Tags = $resource.Tags
    
            #Checkign if tags is null or have value
            if($Tags -ne $null)
            {

                $Tags.GetEnumerator() | % { $TagsAsString += $_.Key + ":" + $_.Value + ";" }

                if($Tags.ContainsKey("ApplicationOwner"))
                {
                    $ApplicationOwner = $Tags["ApplicationOwner"]
                }
                if($Tags.ContainsKey("Application Owner"))
                {
                    $ApplicationOwner = $Tags["Application Owner"]
                }
                if($Tags.ContainsKey("ApplicationType"))
                {
                    $ApplicationType = $Tags["ApplicationType"]
                }
                if($Tags.ContainsKey("Application Type"))
                {
                    $ApplicationType = $Tags["Application Type"]
                }
                if($Tags.ContainsKey("CostCenter"))
                {
                    $CostCenter = $Tags["CostCenter"]
                }
                if($Tags.ContainsKey("Cost Center"))
                {
                    $CostCenter = $Tags["Cost Center"]
                }
                if($Tags.ContainsKey("Department"))
                {
                    $Department = $Tags["Department"]
                }
                if($Tags.ContainsKey("BuildDate"))
                {
                    $BuildDate = $Tags["BuildDate"]
                }
                if($Tags.ContainsKey("Build Date"))
                {
                    $BuildDate = $Tags["Build Date"]
                }
                if($Tags.ContainsKey("ApplicationCategory"))
                {
                    $ApplicationCategory = $Tags["ApplicationCategory"]
                }
                if($Tags.ContainsKey("Application Category"))
                {
                    $ApplicationCategory = $Tags["Application Category"]
                }
                
            }
            else
            {
                $TagsAsString = "NULL"
            }
            #$results = @()
            #Adding to Results
            $details = @{            
                        Name = $resource.Name
                        ResourceId = $resource.ResourceId
                        ResourceName = $resource.ResourceName
                        ResourceType = $resource.ResourceType
                        ResourceGroupName =$resource.ResourceGroupName
                        Location = $resource.Location
                        SubscriptionId = $sub.SubscriptionId 
                        SubscriptionName = $sub.Name
                        Sku = $resource.Sku
                        ApplicationOwner = $ApplicationOwner
                        ApplicationCategory = $ApplicationCategory
                        ApplicationType = $ApplicationType
                        CostCenter = $CostCenter
                        Department = $Department
                        BuildDate = $BuildDate
                        VMSize = $vmSize
                        sqltier = $sqlTier
                        sqlCapacity = $sqlCapacity
                }                           
                $results += New-Object PSObject -Property $details 

            #Clearing Variable
            $TagsAsString = ""
        }
        }
    }

    $results | export-csv -Path $PathToOutputCSVReport -NoTypeInformation
}
else
{
    Write-Host -ForegroundColor Red "No Subscription Found"
}
