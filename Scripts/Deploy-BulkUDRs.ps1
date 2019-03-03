$UDRsCSVFilePath = "C:\DATA\UDRs-DevInt2.csv"

$ApplicationOwner = "TestEmailId@YourDomain"
$ApplicationType = "UDR"
$Department = "Infrastructure"
$CostCenter = "000"
$location="eastus2"
$BuildDate = "01/01/2018"

$tagsHashTable = @{ApplicationOwner=$ApplicationOwner;ApplicationType=$ApplicationType;Department=$Department;CostCenter=$CostCenter;BuildDate=$BuildDate}
$csvUDRsContent = Import-Csv -Path $UDRsCSVFilePath

Add-AzureRmAccount

foreach($eachUDR in $csvUDRsContent)
{
    $routeTableName = $eachUDR.'Route Table Name'
    $addressPrefix = $eachUDR.Destination
    $routeName = $eachUDR.'UDR Name'
    $deploymentName = "deployment-"+$routeName
    $nextHopType = $eachUDR.'NextHop Type'
    $nextHopIpAddress = $eachUDR.'Next Hop'

    $subscriptionName = $eachUDR.Subscription
    $resourceGroupName = $eachUDR.'Resource Group'

    $subnetName = $eachUDR.'Atttached to (SRC)'
    $subnetAddressPrefix = $eachUDR.SubnetAddressPrefix
    $vNetOfSubnet = $eachUDR.vNetOfSubnet
    $vNetResourceGroupName = $eachUDR.vNetResourceGroup

    Select-AzureRmSubscription -SubscriptionName $subscriptionName


  $virtualNetwork = Get-AzureRmVirtualNetwork -Name $vNetOfSubnet -ResourceGroupName $vNetResourceGroupName
  
  $routeTable = $null
  $routeTable = Get-AzureRmRouteTable -Name $routeTableName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

  if($routeTable -eq $null)
  {
      $route = New-AzureRmRouteConfig `
    -Name $routeName `
    -AddressPrefix $addressPrefix `
    -NextHopType $nextHopType `
    -NextHopIpAddress $nextHopIpAddress

      $routeTable = New-AzureRmRouteTable `
      -Name $routeTableName `
      -ResourceGroupName $resourceGroupName `
      -location $location `
      -Route $route -Tag $tagsHashTable
  }
  else
  {
    $routeTable | Add-AzureRmRouteConfig -Name $routeName -AddressPrefix $addressPrefix -NextHopType $nextHopType -NextHopIpAddress $nextHopIpAddress | Set-AzureRmRouteTable
  }

  Set-AzureRmVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -VirtualNetwork $virtualNetwork `
  -AddressPrefix $subnetAddressPrefix `
  -RouteTable $routeTable |
Set-AzureRmVirtualNetwork

}