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
        Select-AzureRmSubscription -SubscriptionId $SubscriptionId

        #Getting all Azure Route Tables
        $routeTables = Get-AzureRmRouteTable

        foreach($routeTable in $routeTables)
        {
                Remove-AzureRmResourceLock -LockName DoNotDelete -ResourceGroupName $routeTable.ResourceGroupName -ResourceName $routeTable.Name -ResourceType $routeTable.Type -Force
        }

        }

        }