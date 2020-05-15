<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Harvesting Clouds.  All rights reserved.   

	File:		Get-AzureRmTagsReport.ps1

	Purpose:	To get the report for tags of all the resources in Azure

	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Azure Resources Tags Report Generation Script
  
 .DESCRIPTION
	This script is used to get report for tags of all the resources in Azure. 
		
 .EXAMPLE
	C:\PS>  .\Get-AzureRmVMDiskDetails.ps1 -SubscriptionName "Your-Subscription-Name-Here"  -OutputPath "C:\AzureData\TagsResults"
	
	Description
	-----------
	This command executes the script with default parameters. Replace the value for SubscriptionName parameter as per your environment. Also replace the output path as per your environment. The script will prompt for Azure Credentials. It doesn't store these credentials anywhere.
     
 .PARAMETER SubscriptionName
    This is the name of the subscription for which you want the report. 
 
 .PARAMETER OutputPath
    This is the output directory path where you want to save the report. 
 
 .INPUTS
    None.

 .OUTPUTS
    None.
		   
 .LINK
	None.
#>

param
    (
        [Parameter(Mandatory=$True)]
        [string]$SubscriptionName,

        [Parameter(Mandatory=$True)]
        [string]$OutputPath

     )

try
{
    #Adding Azure Account and Subscription
    Add-AzureRmAccount

    #Selecting the Azure Subscription
    Select-AzureRmSubscription -SubscriptionName $SubscriptionName

    #Getting all Azure Resources
    $resources = Get-AzureRmResource

    #Declaring Variables
    $results = @()
    $TagsAsString = ""

    foreach($resource in $resources)
    {
        #Fetching Tags
        $Tags = $resource.Tags
    
        #Checkign if tags is null or have value
        if($Tags -ne $null)
        {

            $Tags.GetEnumerator() | % { $TagsAsString += $_.Key + ":" + $_.Value + ";" }
        }
        else
        {
            $TagsAsString = "NULL"
        }
        #$results = @()
        #Adding to Results
        $details = @{            
                    Tags = $TagsAsString
                    Name = $resource.Name
                    ResourceId = $resource.ResourceId
                    ResourceName = $resource.ResourceName
                    ResourceType = $resource.ResourceType
                    ResourceGroupName =$resource.ResourceGroupName
                    Location = $resource.Location
                    SubscriptionId = $resource.SubscriptionId 
                    Sku = $resource.Sku
            }                           
            $results += New-Object PSObject -Property $details 

        #Clearing Variable
        $TagsAsString = ""
    }

    #Generating Output
    $OutputPathWithFileName = $OutputPath + "\Tags-" + $SubscriptionName + ".csv"
    $results | export-csv -Path $OutputPathWithFileName -NoTypeInformation
}
catch [system.exception]
{
	Write-Output "Error in generating report: $($_.Exception.Message) "
    Write-Output "Error Details are: "
    Write-Output $Error[0].ToString()
	Exit $ERRORLEVEL
}
