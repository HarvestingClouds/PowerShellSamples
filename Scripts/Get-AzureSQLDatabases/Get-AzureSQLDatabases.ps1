#Logging into Azure
#Login-AzureRmAccount

$OutFileLocation='D:\Data\temp'
try
{
    $subscriptions=Get-AzureRmSubscription

    #output object
    $objects = @()
    
    #iterating subscriptions
    foreach ($subscription in $subscriptions)
    {
        #selecting subscription
        Select-AzureRmSubscription -Subscription $subscription.Id
        
        #Getting all sql resources
        $resources = Get-AzureRmResource | ?{ $_.kind -eq "v12.0,user"  } | select resourcename,resourceid

        #iterating sql resources
        foreach($resource in $resources)
        {
            $resourceGroupName = $resource.ResourceId.Split('/')[4]
            $serverName = $resource.ResourceId.Split('/')[8]
            $databaseName = $resource.ResourceId.Split('/')[10]

            $sqlDatabases = Get-AzureRmSqlDatabase -DatabaseName $databaseName -ServerName $servername -ResourceGroupName $resourceGroupName

            $objects += New-Object -Type PSObject -Prop @{'ResourceGroupName'=$resourceGroupName;'ServerName'=$serverName;'DatabaseName'=$databaseName;'SkuName'=$sqlDatabases.SkuName;'Status'=$sqlDatabases.Status; 'MaxSizeBytes'=$sqlDatabases.MaxSizeBytes}
        }

    }
        $objects|export-csv -NoTypeInformation  ($OutFileLocation + '\' + (get-date -format yyyy-MM-dd) + '_SQLDatabases.csv')
}

catch 
{
              throw $Error[0].Exception.Message
           }
