#Path Variables. Update as per your environment
$InputVMsCSVFilePath = "D:\DATA\RoutesTestEnvironment\EnvironmentDetails-ForAutomation.csv" #Make sure you have updated this CSV as per your environment. This is the INPUT to the script
$PathToOutputCSVReport = "D:\DATA\RoutesTestEnvironment\EnvironmentDetails-ForAutomation-Result.csv"
#Inputs
$subscriptionName = "you-subscription-name"

try {
    
    #Adding Azure Account and Subscription
    $env = Get-AzEnvironment -Name "AzureCloud"
    Connect-AzAccount -Environment $env
    Set-AzContext -SubscriptionName $subscriptionName

    #Reading the CSV Content
    $csvVMsContent = Import-Csv -Path $InputVMsCSVFilePath

    #Output variable
    $outputResults = @()

    foreach($eachVM in $csvVMsContent)
    {
        #Reading from the input CSV File
        $SourceVMSubscriptionName = $eachVM.SourceSubscription
        $SourceVMResourceGroupName = $eachVM.SourceRG
        $SourceVMName = $eachVM.SourceVMName
        $SourceVMIPAddress = $eachVM.'Source IP - Indicative'
        $DestinationIPAddress = $eachVM.'DestinationIP-Actual'
        $SourceLocation = $eachVM.SourceLocation
        
        #Setting the Subscription Context
        Select-AzSubscription -SubscriptionName $SourceVMSubscriptionName
        
        #Getting the required variables
        $nw = $null
        if($SourceLocation -eq "centeralus")
        {
            $nw = Get-AzNetworkWatcher -Name NetworkWatcher_centralus -ResourceGroupName NetworkWatcherRG
        }
        else
        {
            $nw = Get-AzNetworkWatcher -Name NetworkWatcher_eastus2 -ResourceGroupName NetworkWatcherRG
        }

        #Fetching the Azure VM
        $vm = Get-AzVM -Name $SourceVMName -ResourceGroupName $SourceVMResourceGroupName
        
        Write-Host "Testing the Source VM $SourceVMName and Destination IP address $DestinationIPAddress." -ForegroundColor Green
        #Testing and fetching the next hop
        $nextHop = Get-AzNetworkWatcherNextHop -NetworkWatcher $nw -TargetVirtualMachineId $vm.Id -SourceIPAddress $SourceVMIPAddress -DestinationIPAddress $DestinationIPAddress

        #Fetching the results
        $eachVM.NextHopType = $nextHop.NextHopType
        $eachVM.IPAddressResult = $nextHop.NextHopIpAddress
        $eachVM.RouteTableID = $nextHop.RouteTableId

        #Adding to the output
        $outputResults += $eachVM
    }
    $outputResults | export-csv -Path $PathToOutputCSVReport -NoTypeInformation
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "ErrorMessage:-" $ErrorMessage -ForegroundColor RED
    Break
}
