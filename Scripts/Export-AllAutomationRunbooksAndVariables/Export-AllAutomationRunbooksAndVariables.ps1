$SubscriptionName = "SubscriptionName"
$AutomationAccountName = "Automation Account Name"
$ResourceGroupName = "Resource Group of Automation Account"
$OutputFolder = "Output Folder Full Path without trailing slash sign"

#region Loggin in and selecting Subscription
Add-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $SubscriptionName

#endregion

#region 1. Exporting Runbooks

$AllRunbooks = Get-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName
$AllRunbooks | Export-AzureRmAutomationRunbook -OutputFolder $OutputFolder

#endregion


#region 2. Exporting Variables

$variables = Get-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName

$variablesFilePath = $OutputFolder + "\variables.csv"

$variables | Export-Csv -Path $variablesFilePath -NoTypeInformation

#endregion