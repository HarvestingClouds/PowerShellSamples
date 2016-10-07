#Adding Azure Account and Subscription
Add-AzureRmAccount

#Selecting the Azure Subscription
Select-AzureRmSubscription -SubscriptionName "Your Subscription Name Here"

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
        foreach($Tag in $Tags)
        {
            $TagsAsString += $Tag.Name + ":" + $Tag.Value + ";"
        }
    }
    else
    {
        $TagsAsString = "NULL"
    }

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

$results | export-csv -Path "C:\DATA\Projects\Accudyne\Resources By Tags\Tags-Accudyne-Operations-Production.csv" -NoTypeInformation