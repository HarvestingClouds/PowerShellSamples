#View existing Azure Role Definition
Get-AzureRMRoleDefinition -Name "Virtual Machine Operator" | ConvertTo-Json

#Fetching the existing Role
$role = Get-AzureRmRoleDefinition "Virtual Machine Operator"

#Updating the existing Role
$role.Actions.Add("Microsoft.Compute/virtualMachines/deallocate/action")
$role.Description = "Can monitor, Start, Stop and restart virtual machines."

#Setting the updates back to the Azure
Set-AzureRmRoleDefinition -Role $role