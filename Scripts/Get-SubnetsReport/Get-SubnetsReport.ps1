Login-AzureRmAccount

Get-AzureRmSubscription

Select-AzureRmSubscription -Subscription subprod01

#$AzureVirtualNetwork= Get-AzureRmVirtualNetwork | Select-Object -ExpandProperty ResourceGrounName, Name, Location, AddressSpace,Subnets
$OutFileLocation='C:\Projects\test'
try
{
    $subscriptions=Get-AzureRmSubscription
    $objects = @()
    foreach ($subscription in $subscriptions)
    {
        Select-AzureRmSubscription -Subscription $subscription.Id
        $AzureVirtualNetwork=Get-AzureRmVirtualNetwork | Select-Object  -Property Name ,@{ Name='AddressSpace';Express={$_.AddressSpace.AddressPrefixes} },@{ Name='virtualnetworkIP';Express={($_.AddressSpace.AddressPrefixes).Split('/')[0] } } ,@{ Name='SubnetName';Express={($_.Subnets.Name) } },@{ Name='SubnetAddress';Express={($_.Subnets.AddressPrefix) } }
     
        foreach ($vn in $AzureVirtualNetwork)                                                                                                                                               
        {
         
            for ($i = 0; $i -lt $vn.SubnetAddress.Count; $i++)
                { 
                   $subnetName=$vn.SubnetName[$i]
                   $virtualnetworkName=$vn.Name  
                 Write-Host "Getting Subnets for VirtualNetwork and SubnetName are $virtualnetworkName  $subnetName"

       
                 if ($vn.SubnetAddress.Count -eq 1)
                 {
                    $subnetName=$vn.SubnetName
                    $subnetLength=$vn.SubnetAddress.Split('/')[1] 
                    $subnetAddressSpace=$vn.SubnetAddress
                    $subnetAddress=$vn.SubnetAddress.Split('/')[0].Split('.')
                 }
                 else
                 {
                    $subnetLength=$vn.SubnetAddress[$i].Split('/')[1] 
                    $subnetAddress=$vn.SubnetAddress[$i].Split('/')[0].Split('.')
                    $subnetAddressSpace=$vn.SubnetAddress[$i]
                 }
      
                    switch ($subnetLength) {
                                               "24"  {$subnetRange=254; break}
                                                "25"  {$subnetRange=126; break}
                                               "26"  {$subnetRange=62; break}
                                               "27"  {$subnetRange=30; break}
                                               "28"  {$subnetRange=14; break}
                                               default {$subnetRange=0; break}
                                            }
                    for ($j = 1; $j -le $subnetRange; $j++)
                    {
                     $subnetIpAddresses=  $subnetAddress[0] + "." +  $subnetAddress[1] + "." +  $subnetAddress[2] + "." + ($j +$subnetAddress[3])
                     $objects += New-Object -Type PSObject -Prop @{'VirtualNetwork'=$vn.Name;'AddressSpace'=$vn.AddressSpace;'SubnetName'=$subnetName;'SubnetAddressSpace'=$subnetAddressSpace;'IPAddresses'=$subnetIpAddresses}
                    }

                    Write-Host "Test"
    
                }
     
        }
    }
        $objects|export-csv -NoTypeInformation  ($OutFileLocation + '\' + (get-date -format yyyy-MM-dd) + '_subnetAddresses.csv')
}

catch {
              throw $Error[0].Exception.Message
           }
