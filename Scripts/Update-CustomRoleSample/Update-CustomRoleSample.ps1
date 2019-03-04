$SubscriptionName = "SubscriptionName"
$roleName = "Virtual Machine Operator"

#region Loggin in and selecting Subscription
Add-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName $SubscriptionName

#endregion

#View existing Azure Role Definition
Get-AzureRMRoleDefinition -Name $roleName | ConvertTo-Json

#Fetching the existing Role
$role = Get-AzureRmRoleDefinition $roleName

#Updating the existing Role
$role.Actions.Add("Microsoft.Compute/virtualMachines/deallocate/action")
$role.Description = "Can monitor, Start, Stop and restart virtual machines."

#Setting the updates back to the Azure
Set-AzureRmRoleDefinition -Role $role