<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Microsoft Corporation.  All rights reserved.   
	
	File:		Report-UDRsWithSubnetInfo.ps1
	
	Purpose:	To get the report for tags of all the resources in Azure
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Disassociate Subnets from Route Tables
  
 .DESCRIPTION
	This script is used to disassociate subnets from route tables. 
		
 .EXAMPLE
	C:\PS>  .\Report-UDRsWithSubnetInfo.ps1 
	
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

$PathToOutputCSVReport = "C:\DATA\report.csv"

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
        Write-Output $SubscriptionName

        #Selecting the Azure Subscription
        Select-AzureRmSubscription -SubscriptionName $SubscriptionId

        #Getting all Azure Route Tables
        $routeTables = Get-AzureRmRouteTable

        foreach($routeTable in $routeTables)
        {
            $routeTableName = $routeTable.Name
            $routeResourceGroup = $routeTable.ResourceGroupName
            Write-Output $routeName

            #Fetch Route Subnets
            $routeSubnets = $routeTable.Subnets

            foreach($routeSubnet in $routeSubnets)
            {
                $subnetName = $routeSubnet.Name
                Write-Output $subnetName

                $subnetId = $routeSubnet.Id

                ###Getting information
                $splitarray = $subnetId.Split('/')
                $subscriptionId = $splitarray[2]
                $vNetResourceGroupName = $splitarray[4]
                $virtualNetworkName = $splitarray[8]
                $subnetName = $splitarray[10]

                $subnetAddressPrefix = $subnet.AddressPrefix

                $details = @{            
                        routeTableName=$routeTableName
                        routeResourceGroup=$routeResourceGroup
                        subnetName=$subnetName
                        subscriptionId=$subscriptionId
                        vNetResourceGroupName=$vNetResourceGroupName
                        virtualNetworkName=$virtualNetworkName
                        subnetAddressPrefix=$subnetAddressPrefix
                }                           
                $results += New-Object PSObject -Property $details
                

            }

        }
    }
    $results | export-csv -Path $PathToOutputCSVReport -NoTypeInformation
}
else
{
    Write-Host -ForegroundColor Red "No Subscription Found"
}
