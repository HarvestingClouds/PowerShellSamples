<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Microsoft Corporation.  All rights reserved.   
	
	File:		Disassociate-SubnetsFromUDRs.ps1
	
	Purpose:	To get the report for tags of all the resources in Azure
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Disassociate Subnets from Route Tables
  
 .DESCRIPTION
	This script is used to disassociate subnets from route tables. 
		
 .EXAMPLE
	C:\PS>  .\Disassociate-SubnetsFromUDRs.ps1 
	
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

#Adding Azure Account and Subscription
Add-AzureRmAccount

#Getting all Azure Subscriptions
$subs = Get-AzureRmSubscription

#Checking if the subscriptions are found or not
if(($subs -ne $null) -or ($subs.Count -gt 0))
{
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
            $routeName = $routeTable.Name
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

                #$subnet = Get-AzureRmResource -ResourceId $subnetId
                write-output $subnet.Name
                ####$NSG=Get-AzureRmNetworkSecurityGroup | where { $_.ID -eq $NSGid }
                
                $virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $vNetResourceGroupName
                
                $subnet = $virtualNetwork.Subnets | where {$_.Name -eq $subnetName}

                #### Setting the Route table to Null
                $subnet.RouteTable = $null

                $subnetAddressPrefix = $subnet.AddressPrefix
                
                #Setting and committing the changes
                Set-AzureRmVirtualNetworkSubnetConfig `
                  -Name $subnetName `
                  -VirtualNetwork $virtualNetwork `
                  -AddressPrefix $subnetAddressPrefix `
                  -RouteTable $null |
                Set-AzureRmVirtualNetwork

            }

        }
    }

}
else
{
    Write-Host -ForegroundColor Red "No Subscription Found"
}
