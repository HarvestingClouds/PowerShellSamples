param (
    [parameter(Mandatory=$true)]
    [Object]$RecoveryPlanContext
)

$connectionName = "AzureRunAsConnection"
$AutomationAccountName = "YourAutomationAccountName"
$ResourceGroupName = "Resource Group Name for Automation Account"
$RunbookName = "Secondary Runbook Name"
$HybridWorkerGroup = "Optional"
$IsSecondaryRunbookToBeRunOnHybrid = $true

try
{
    $Conn = Get-AutomationConnection -Name $connectionName 

    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

    Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

if($IsSecondaryRunbookToBeRunOnHybrid)
{
    Start-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -Name $RunbookName `
    -Parameters  @{"RecoveryPlanContext"=$RecoveryPlanContext;"connectionName"=$connectionName;"AutomationAccountName"=$AutomationAccountName;"ResourceGroupName"=$ResourceGroupName;"HybridWorkerGroup"=$HybridWorkerGroup}  `
    -RunOn $HybridWorkerGroup
}
else
{
    Start-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -Name $RunbookName `
    -Parameters  @{"RecoveryPlanContext"=$RecoveryPlanContext;"connectionName"=$connectionName;"AutomationAccountName"=$AutomationAccountName;"ResourceGroupName"=$ResourceGroupName;"HybridWorkerGroup"=$HybridWorkerGroup}
}


