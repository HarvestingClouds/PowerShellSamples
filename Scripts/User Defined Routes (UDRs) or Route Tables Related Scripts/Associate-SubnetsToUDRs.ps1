$UDRsCSVFilePath = "C:\DATA\Associate-SubnetsToUDRs - input.csv"

#Importing the CSV file Content
$csvUDRsContent = Import-Csv -Path $UDRsCSVFilePath

Add-AzureRmAccount

foreach($eachUDR in $csvUDRsContent)
{
    $routeTableName = $eachUDR.routeTableName
    $addressPrefix = $eachUDR.subnetAddressPrefix
    $deploymentName = "deployment-"+$routeTableName
    $subscriptionId = $eachUDR.subscriptionId
    $routeResourceGroupName = $eachUDR.routeResourceGroup

    $subnetName = $eachUDR.subnetName
    $subnetAddressPrefix = $eachUDR.subnetAddressPrefix
    $vNetOfSubnet = $eachUDR.virtualNetworkName
    $vNetResourceGroupName = $eachUDR.vNetResourceGroupName

    Select-AzureRmSubscription -SubscriptionId $subscriptionId

    $virtualNetwork = Get-AzureRmVirtualNetwork -Name $vNetOfSubnet -ResourceGroupName $vNetResourceGroupName
  
    $routeTable = $null
    $routeTable = Get-AzureRmRouteTable -Name $routeTableName -ResourceGroupName $routeResourceGroupName


    Set-AzureRmVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -VirtualNetwork $virtualNetwork `
    -AddressPrefix $subnetAddressPrefix `
    -RouteTable $routeTable |
    Set-AzureRmVirtualNetwork

}