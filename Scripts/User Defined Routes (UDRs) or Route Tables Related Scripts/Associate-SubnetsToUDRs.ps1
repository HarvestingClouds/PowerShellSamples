$UDRsCSVFilePath = "C:\DATA\report.csv"

$ApplicationOwner = "ApplicationOwnerEmailIdOrName"
$ApplicationType = "UDR"
$Department = "Infra"
$CostCenter = "CostCenter"
$location="eastus2"
$BuildDate = "01/01/2019"

$tagsHashTable = @{ApplicationOwner=$ApplicationOwner;ApplicationType=$ApplicationType;Department=$Department;CostCenter=$CostCenter;BuildDate=$BuildDate}
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

    <#New-AzureRmResourceGroupDeployment -Mode Incremental -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $ARMTemplatePath  `
  -routeTableName $routeTableName -addressPrefix $addressPrefix -routeName $routeName -nextHopType $nextHopType -nextHopIpAddress $nextHopIpAddress `
  -ApplicationOwner $ApplicationOwner -ApplicationType $ApplicationType -Department $Department -CostCenter $CostCenter
  #>

  $virtualNetwork = Get-AzureRmVirtualNetwork -Name $vNetOfSubnet -ResourceGroupName $vNetResourceGroupName
  
  $routeTable = $null
  $routeTable = Get-AzureRmRouteTable -Name $routeTableName -ResourceGroupName $routeResourceGroupName

  <#
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
  #>
  Set-AzureRmVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -VirtualNetwork $virtualNetwork `
  -AddressPrefix $subnetAddressPrefix `
  -RouteTable $routeTable |
Set-AzureRmVirtualNetwork


  #Start-Sleep 5

}