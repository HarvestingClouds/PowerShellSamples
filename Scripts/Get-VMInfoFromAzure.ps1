param (
    [parameter(Mandatory=$true)]
    [Object]$VM,
    [parameter(Mandatory=$true)]
    [String]$AzureTenantId,
    [parameter(Mandatory=$true)]
    [String] $SubscriptionID
)

[String] $VMName = $VM.RoleName
[String] $VMResourceGroup = $VM.ResourceGroupName

$Cred = Get-AutomationPSCredential -Name 'ASRServicePrincipal'

#Connect to Azure
$AzureRMConn = Login-AzureRmAccount -ServicePrincipal -Credential $Cred -TenantId $AzureTenantId -ErrorAction SilentlyContinue -ErrorVariable LoginError

#Check for Login Errors
if($LoginError.Count -gt 0)
{
    $ErrorDetail = $LoginError.Exception.Message;

	$VM | Add-Member NoteProperty Errors $ErrorDetail;
}
else
{
    #Validate Connection Object Exists
    if($AzureRMConn -ne $null)
    {
        Write-Verbose "Setting Subscription to Id: $SubscriptionID"
        $ConnSubs = Select-AzureRmSubscription -SubscriptionId $SubscriptionID
        $VM = Get-AzureRmVM -ResourceGroupName $VMResourceGroup -Name $VMName

        <#
        $VMNetworkInterfaces = Get-AzureRmNetworkInterface -ResourceGroupName $VMResourceGroup | Where-Object {$_.Name -like "$VMName*"}
        
        $VMNICCount = $VMNetworkInterfaces.Count

        if($VMNICCount -gt 1)
        {
            $VMMainIPConfig = $VMNetworkInterfaces[0] | Get-AzureRmNetworkInterfaceIpConfig
        }
        else
        {
            $VMMainIPConfig = $VMNetworkInterfaces | Get-AzureRmNetworkInterfaceIpConfig
        }
        #>

        #Change Start
        $nicId = $VM.NetworkProfile.NetworkInterfaces[0].Id
        $VMNetowrkInterface = Get-AzureRmNetworkInterface -ResourceGroupName $VMResourceGroup -Name $nicId.Split('/')[8]
        $VMMainIPConfig = $VMNetowrkInterface | Get-AzureRmNetworkInterfaceIpConfig

        $strVMMainNicName = $VMMainIPConfig.Name
        $strVMMainNicIPAddress = $VMMainIPConfig.PrivateIpAddress
        
        $VMName = $VM.Name

        $VM | Add-Member NoteProperty VMIPAddress $strVMMainNicIPAddress -force
        $VM | Add-Member NoteProperty VMName $VMName -force
        $VM | Add-Member NoteProperty VMFQDN $VMName -force
        $VM | Add-Member NoteProperty VMIP $strVMMainNicIPAddress -force
        #Change Ends
       
    }
}

Write-output $VM