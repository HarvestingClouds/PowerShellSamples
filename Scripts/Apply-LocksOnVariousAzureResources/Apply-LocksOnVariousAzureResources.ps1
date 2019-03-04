Add-AzureRmAccount

$subs = Get-AzureRmSubscription

foreach($sub in $subs)
{
    Select-AzureRmSubscription -SubscriptionName $sub.SubscriptionName

    # 1. Virtual Networks
    $vNets = Get-AzureRmVirtualNetwork

    foreach($vNet in $vNets)
    {
        New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $vNet.Name -ResourceType $vNet.Type -ResourceGroupName $vNet.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
    }
    
    # 2. Route Tables
    $routes = Get-AzureRmRouteTable

    foreach($route in $routes)
    {
        New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $route.Name -ResourceType $route.Type -ResourceGroupName $route.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
    }
    
    # 3. Express Routes
    $expressRoutes = Get-AzureRmExpressRouteCircuit

    foreach($expressRoute in $expressRoutes)
    {
        New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $expressRoute.Name -ResourceType $expressRoute.Type -ResourceGroupName $expressRoute.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
    }

    #region 4. Virtual network Gateway
    $gateway = $null
    $rgName = "RG-Test-USE2"
    if((Get-AzureRmResourceGroup -Name $rgName -ErrorAction Ignore) -ne $null)
    {
        $gateways = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $rgName

        foreach($gateway in $gateways)
        {
            New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $gateway.Name -ResourceType $gateway.Type -ResourceGroupName $gateway.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
        }
    }
    $gateway = $null
    $rgName = "RG-Test-USNC"
    if((Get-AzureRmResourceGroup -Name $rgName -ErrorAction Ignore) -ne $null)
    {
        $gateways = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $rgName

        foreach($gateway in $gateways)
        {
            New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $gateway.Name -ResourceType $gateway.Type -ResourceGroupName $gateway.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
        }
    }
    #endregion 
    
    #region 5. Virtual Network Gateway Connections
    # 5.1 USE Region
    $gateway = $null
    $rgName = "RG-Test-USE"
    if((Get-AzureRmResourceGroup -Name $rgName -ErrorAction Ignore) -ne $null)
    {
        $gatewayConnections = Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName $rgName

        foreach($gatewayConnection in $gatewayConnections)
        {
            New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $gatewayConnection.Name -ResourceType $gatewayConnection.Type -ResourceGroupName $gatewayConnection.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
        }
    }

    # 5.2 USNC region
    $gateway = $null
    $rgName = "RG-Test-USNC"
    if((Get-AzureRmResourceGroup -Name $rgName -ErrorAction Ignore) -ne $null)
    {
        $gatewayConnections = Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName $rgName
        
        foreach($gatewayConnection in $gatewayConnections)
        {
            New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $gatewayConnection.Name -ResourceType $gatewayConnection.Type -ResourceGroupName $gatewayConnection.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
        }
    }
    #endregion
    

    # 6. Recovery Services Vaults (ASR Vaults)
    $vaults = Get-AzureRmRecoveryServicesVault

    foreach($vault in $vaults)
    {
        New-AzureRmResourceLock -LockLevel CanNotDelete -LockName DoNotDelete -ResourceName $vault.Name -ResourceType $vault.Type -ResourceGroupName $vault.ResourceGroupName -LockNotes "Do Not Delete Lock" -Confirm -Force
    }


}
