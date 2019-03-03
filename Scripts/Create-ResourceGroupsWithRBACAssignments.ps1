$RGNamesUSE2 = "RG-01-Test-USE2", "RG-02-Test-USE2", "RG-03-Test-USE2", "RG-03-Test-USE2","RG-04-Test-USE2"
$RGNamesUSNC = "RG-01-Test-USNC", "RG-02-Test-USNC", "RG-03-Test-USNC", "RG-04-Test-USNC"


Add-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "SubscriptionName"

$ADGroup01 = Get-AzureRmADGroup -SearchString "ADGroup-01-Test-Contributors"
$App01 = Get-AzureRmADServicePrincipal -SearchString "AD-AppRegistration01-Test"
$ADGroup02 = Get-AzureRmADGroup -SearchString "ADGroup-02-Test-Readers"

foreach($rg in $RGNamesUSE2)
{
    New-AzureRmResourceGroup -Name $rg -Location eastus2

    New-AzureRmRoleAssignment -ObjectId $ADGroup01.Id -RoleDefinitionName "Contributor" -ResourceGroupName $rg

    New-AzureRmRoleAssignment -ObjectId $App01.Id -RoleDefinitionName "Contributor" -ResourceGroupName $rg

    #Remove-AzureRmRoleAssignment -ObjectId $ADGroup02.Id -RoleDefinitionName "Contributor" -ResourceGroupName $rg
    New-AzureRmRoleAssignment -ObjectId $ADGroup02.Id -RoleDefinitionName "Reader" -ResourceGroupName $rg

}
foreach($rg in $RGNamesUSNC)
{
    New-AzureRmResourceGroup -Name $rg -Location northcentralus
    
    New-AzureRmRoleAssignment -ObjectId $ADGroup01.Id -RoleDefinitionName "Contributor" -ResourceGroupName $rg

    New-AzureRmRoleAssignment -ObjectId $App01.Id -RoleDefinitionName "Contributor" -ResourceGroupName $rg

    #Remove-AzureRmRoleAssignment -ObjectId $ADGroup02.Id -RoleDefinitionName "Contributor" -ResourceGroupName $rg
    New-AzureRmRoleAssignment -ObjectId $ADGroup02.Id -RoleDefinitionName "Reader" -ResourceGroupName $rg
}