<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Microsoft Corporation.  All rights reserved.   
	
	File:		Get-AzureRmTagsReport.ps1
	
	Purpose:	To get the report for tags of all the resources in Azure
					
	Version: 	3.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Azure Resources Tags Report Generation Script
  
 .DESCRIPTION
	This script is used to get the report for tags of all the resources in Azure. 
		
 .EXAMPLE
	C:\PS>  .\Get-AzureRmTagsReport.ps1 
	
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

#Path variable to the CSV file
#NOTE: Update this path before running the script
$PathToOutputCSVReport = "C:\DATA\TagsReport.csv"

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
            $CapitalProject = ""
            $CapitalProjectName = ""

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
                        ApplicationType = $ApplicationType
                        CostCenter = $CostCenter
                        Department = $Department
                        BuildDate = $BuildDate
                        AllTags = $TagsAsString
                }                           
                $results += New-Object PSObject -Property $details 

            #Clearing Variable
            $TagsAsString = ""
        }
    }

    $results | export-csv -Path $PathToOutputCSVReport -NoTypeInformation
}
else
{
    Write-Host -ForegroundColor Red "No Subscription Found"
}
