#Author: Aman Sharma @ http://HarvestingClouds.com

#Variables
$subscriptionName = "Your Subscription Name"
$salt = "<unique string used for hashing>"
$wacPort = "6516"
$Settings = @{"port" = $wacPort; "salt" = $salt}

try
{
    #Setting the Azure context
    $env = Get-AzEnvironment -Name "AzureCloud"
    Connect-AzAccount -Environment $env
    Set-AzContext -SubscriptionName $subscriptionName

    #Selecting all RGs that begins with the text. Notice the wildcard in the name
    #Update this as per your requirements
    $allRequiredRGs = Get-AzResourceGroup -Name "RG-*"

    #Iterating on the Resource Groups
    foreach($currentRG in $allRequiredRGs)
    {
        #Fetch all VMs in the current Resource Group
        $currentRGName = $currentRG.ResourceGroupName
        $VMs = Get-AzVM -ResourceGroupName $currentRGName

        #Iterating on all the VMs
        foreach ($vm in $VMs) 
        {
            $vmLocation = $vm.Location
            $vmName = $vm.Name

            #Finding VM's NSG dynamically
            $vmNsgId = (Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces.Id).NetworkSecurityGroup.Id
            $vmNsg = Get-AzResource -ResourceId $vmNsgId
            $vmNsgName = $vmNsg.Name

            # Open outbound port rule for WAC service
            $vmNsg | Add-AzNetworkSecurityRuleConfig -Name "PortForWACService" -Access "Allow" -Direction "Outbound" -SourceAddressPrefix "VirtualNetwork" -SourcePortRange "*" -DestinationAddressPrefix "WindowsAdminCenter" -DestinationPortRange "443" -Priority 100 -Protocol Tcp | Set-AzNetworkSecurityGroup

            # Install VM extension
            Set-AzVMExtension -ResourceGroupName $currentRGName -Location $vmLocation -VMName $vmName -Name "AdminCenter" -Publisher "Microsoft.AdminCenter" -Type "AdminCenter" -TypeHandlerVersion "0.0" -settings $Settings

            # Open inbound port rule on VM to be able to connect to WAC
            $vmNsg | Add-AzNetworkSecurityRuleConfig -Name "PortForWAC" -Access "Allow" -Direction "Inbound" -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange $wacPort -Priority 100 -Protocol Tcp | Set-AzNetworkSecurityGroup

        }

    }
}
catch 
{
    Write-Host -ForegroundColor Red "Error while installing extension."
    $Error[0]
    Write-Host -ForegroundColor Red "Error occured at:"
    $Error[0].InvocationInfo.PositionMessage
}
