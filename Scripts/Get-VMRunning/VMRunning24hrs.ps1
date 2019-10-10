$InitialExecutionDatetime = (Get-Date)
$CurrentDateTime=$InitialExecutionDatetime.ToUniversalTime()
$connectionName = "AzureRunAsConnection"
$Conn = Get-AutomationConnection -Name $connectionName 
$Cred = Get-AutomationPSCredential -Name 'ASRServicePrincipal'
[int]$NoOfDays=1
#$AutomationAccountName = Get-AutomationVariable -Name 'AzureAutomationAccountName'
#$ResourceGroupName = Get-AutomationVariable -Name 'AzureAutomationAccountRG'
#$currentSubscriptionId=""
Write-output "Login to Azure"
$AzureLoginResults =Login-AzureRmAccount
#$AzureLoginResults = Login-AzureRmAccount -ServicePrincipal -Credential $Cred -TenantId $Conn.TenantId -ErrorAction SilentlyContinue -ErrorVariable LoginError
$RetunrObjItm = new-object PSObject
[int]$counter=0
$result=""
<#$AzureLoginResults = Login-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $Conn.TenantId `
    -ApplicationId $Conn.ApplicationId `
    -CertificateThumbprint $Conn.CertificateThumbprint -ErrorAction SilentlyContinue -ErrorVariable LoginError `#>

if ($LoginError.Count -gt 0)
 {
    $ErrorDetails = $LoginError.Exception.Message;
    Write-Output "Login failed with Error: $ErrorDetails"
    $LoginStatus = "Failed"

    
    $RetunrObjItm | add-member NoteProperty "Virtual Machine Operator Status" -value $LoginStatus
    $RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails
    
}
else 
{
    Write-Output "Successfully Login to Azure"    
    Write-Output "Setting Up Subscription"
    $subs = Get-AzureRmSubscription
    $jobs = @()
    foreach ($sub in $subs) 
    {
        #if ($sub.Id -eq "adf124da-c139-44c5-b226-3a812fbe6cf0" -or $sub.Id -eq "f1e34301-c396-4b15-9f25-cab99b61ce7a" -or $sub.Id -eq "dc212303-893e-404d-a787-3a960b14e8bf") 
        #{
            $SubscriptionID = $sub.Id
            $SelectSub = Select-AzureRmSubscription -SubscriptionId $SubscriptionID -TenantId $sub.TenantId
            Write-Output "Getting VM Collection from Azure for subscription $($sub.Name)"
            $VMs = Get-AzureRmVM -Status| Where-Object { $_.PowerState -in ('VM Running','VM allocating','VM Starting') } -WarningAction SilentlyContinue
            $VMs | Format-Table   
            foreach($VM in $VMs) 
            {
                $VMTime=(Get-AzureRmVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status).Statuses.Time
                $starTime=[System.DateTime]::Parse($VMTime)
                [int]$TotalExecutionTimeInHours = (New-TimeSpan -Start $starTime -End $CurrentDateTime).TotalDays
                if($TotalExecutionTimeInHours -gt $NoOfDays)
                {
                     Write-Output "VM Name $($VM.Name)"
                     $counter++
                     $RetunrObjItm | add-member NoteProperty "$($counter)) VMName" -value $VM.Name
                     $RetunrObjItm | add-member NoteProperty "$($counter)) ResourceGroupName" -value $VM.ResourceGroupName
                     $RetunrObjItm | add-member NoteProperty "$($counter)) NoOfDays$($VM.Name)Running" -value $TotalExecutionTimeInHours
                     $RetunrObjItm | add-member NoteProperty "$($counter)) $($VM.Name)SubscriptonName" -value $sub.Name
                     $RetunrObjItm | add-member NoteProperty "$($counter)) $($VM.Name)SubscriptonID" -value $sub.Id
                     $result+=$VM
                }
            }
            
        #}
    }
}
$RetunrObjItm

Write-Output "Sending an email"
$Username ="gurpreetsambhi" # Your user name - found in sendgrid portal
$Password = ConvertTo-SecureString "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" -AsPlainText -Force # SendGrid Password
$credential = New-Object System.Management.Automation.PSCredential $Username, $Password
$SMTPServer = "smtp.sendgrid.net"
$EmailFrom = "gurpreet_sambhi@outlook.com" # Can be anything - aaa@xyz.com
$EmailTo = "gurpreet.sambhi@infrontconsulting.com" # Valid recepient email address
$Subject = "Azure VM Running Report"
$Body = "Summary as of: " + (Get-Date -Format G) + " UTC"+ "`n`n" + $result

Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body 
#-Attachments $file_path_for_nsg, $file_path_for_running_VM, $file_path_for_deallocated_VM, $file_path_for_stopped_VM, $file_path_for_vm_with_no_backup


$FinalExecutionDatetime = (Get-Date)
[int32] $TotalExecutionTimeInMinutes = (New-TimeSpan -Start $InitialExecutionDatetime -End $FinalExecutionDatetime).TotalMinutes
Write-Output "Total Script execution time in Minutes $TotalExecutionTimeInMinutes"