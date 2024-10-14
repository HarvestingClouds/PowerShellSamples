#Reference: https://docs.microsoft.com/en-us/azure/governance/policy/how-to/export-resources#export-with-azure-powershell
#Logging into Azure
$env = Get-AzEnvironment -Name "AzureCloud"
Connect-AzAccount -Environment $env

#Getting all Subscriptions in your environment
$allSubscriptions = Get-AzSubscription

#Iterating through subscriptions
foreach($currentSubscription in $allSubscriptions)
{
    #setting the context to the current subscription
    Set-AzContext -SubscriptionName $currentSubscription.Name

    #Getting all the custom policies
    $policies = Get-AzPolicyDefinition | where {$_.PolicyType -eq 'Custom'}
    
    #Iterating through the policies
    foreach ($policy in $policies) {
        
        #Getting the policy details
        $policyName = $policy.Name
        $fileName = $currentSubscription.Name + "_" + $policyName + ".json"

        #Exporting the current custom policy
        $policy | ConvertTo-Json -Depth 10 | Out-File ".\Export-AzurePolicies\Output\$fileName"
    }

}
