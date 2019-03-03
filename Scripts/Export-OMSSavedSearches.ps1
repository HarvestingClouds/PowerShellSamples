$ResourceGroupName = "Resource Group of Workspace"
$WorkspaceName = "Your Workspace Name"
$SubscriptionName = "YourSubscriptionName"

Add-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $SubscriptionName

# Export Saved Searches
(Get-AzureRmOperationalInsightsSavedSearch -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName).Value.Properties | ConvertTo-Json