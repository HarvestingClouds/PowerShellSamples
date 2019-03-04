<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Microsoft Corporation.  All rights reserved.   
	
	File:		Get-AzureRmAllResourcesReport.ps1
	
	Purpose:	To get the report of all the resources in Azure
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Azure Resources Tags Report Generation Script
  
 .DESCRIPTION
	This script is used to get the report for all the resources in Azure.
		
 .EXAMPLE
	C:\PS>  .\Get-AzureRmAllResourcesReport.ps1  
	
	Description
	-----------
	This command executes the script with default parameters.
     
 .INPUTS
    None.

 .OUTPUTS
    None.
		   
 .LINK
	None.
#>

#Path variable to the Output CSV file
$PathToOutputCSVReport = "C:\DATA\ResourceReport.csv"

#Adding Azure Account and Subscription
Add-AzureRmAccount

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
                $vm = Get-AzureRmVM -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
                $vmSize = $vm.HardwareProfile.VmSize
            }
            
            elseif($resource.Type -eq "Microsoft.Sql/servers/databases")
            {
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
                        VMSize = $vmSize
                        sqltier = $sqlTier
                        sqlCapacity = $sqlCapacity
                        Tags = $Tags
                }                           
                $results += New-Object PSObject -Property $details 
        }
    }

    $results | export-csv -Path $PathToOutputCSVReport -NoTypeInformation
}
else
{
    Write-Host -ForegroundColor Red "No Subscription Found"
}
