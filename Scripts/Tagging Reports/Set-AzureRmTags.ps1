#Reference Link: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags

#Path variable to the CSV file
#NOTE 1: Update this path before running the script
#NOTE 2: Please ensure that the Build Date format in the CSV is dd-MMM-yy
$InputCSVFilePath = "C:\DATA\TagsReportInputs.csv"


#Adding Azure Account and Subscription
Add-AzureRmAccount

$csvContent = Import-Csv -Path $InputCSVFilePath

Add-AzureRmAccount

foreach($eachRecord in $csvContent)
{
    $ResourceId = $eachRecord.ResourceId
    $ResourceGroupName = $eachRecord.ResourceGroupName
    $CostCenter = $eachRecord.CostCenter
    $ApplicationOwner = $eachRecord.ApplicationOwner
    $ApplicationType = $eachRecord.ApplicationType
    $Department = $eachRecord.Department
    $BuildDate = $eachRecord.BuildDate
    $subscriptionName = $eachRecord.SubscriptionName

    if($BuildDate -ne $null)
    {
        $BuildDate = [datetime]::parseexact($BuildDate, 'dd-MMM-yy', $null).ToString('MM/dd/yy')
    }
    
    #Selecting the Subscription
    Select-AzureRmSubscription -SubscriptionName $subscriptionName -ErrorAction Stop

    #Getting Azure Resource
    $r = Get-AzureRmResource -ResourceId $ResourceId -ErrorAction Continue

    if($r -ne $null)
    {
        if($r.tags)
        {
            # Tag - Cost Center
            if($r.Tags.ContainsKey("CostCenter"))
            {
                $r.Tags["CostCenter"] = $CostCenter
            }
            else
            {
                $r.Tags.Add("CostCenter", $CostCenter) 
            }
        
            # Tag - Application Owner
            if($r.Tags.ContainsKey("ApplicationOwner"))
            {
                $r.Tags["ApplicationOwner"] = $ApplicationOwner
            }
            else
            {
                $r.Tags.Add("ApplicationOwner", $ApplicationOwner) 
            }
        
            # Tag - Application Type
            if($r.Tags.ContainsKey("ApplicationType"))
            {
                $r.Tags["ApplicationType"] = $ApplicationType
            }
            else
            {
                $r.Tags.Add("ApplicationType", $ApplicationType) 
            }
        
            # Tag - Department
            if($r.Tags.ContainsKey("Department"))
            {
                $r.Tags["Department"] = $Department
            }
            else
            {
                $r.Tags.Add("Department", $Department) 
            }
        
            # Tag - Build Date
            if($r.Tags.ContainsKey("BuildDate"))
            {
                $r.Tags["BuildDate"] = $BuildDate
            }
            else
            {
                $r.Tags.Add("BuildDate", $BuildDate) 
            }
            
            #Setting the tags on the resource
            Set-AzureRmResource -Tag $r.Tags -ResourceId $r.ResourceId -Force
        }
        else
        {
            #Setting the tags on a resource which doesn't have tags
            Set-AzureRmResource -Tag @{ CostCenter=$CostCenter; ApplicationOwner=$ApplicationOwner; ApplicationType=$ApplicationType; Department=$Department; BuildDate=$BuildDate; ApplicationCategory=$ApplicationCategory } -ResourceId $r.ResourceId -Force
        }
    }
    else
    {
        Write-Host "Resource Not Found with Resource Id: " + $ResourceId
    }
}