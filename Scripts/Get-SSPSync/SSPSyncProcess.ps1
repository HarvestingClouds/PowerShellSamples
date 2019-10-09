param (
    [parameter(Mandatory = $true)]
    [String]$SqlServer,
    [parameter(Mandatory = $true)]
    [String]$Database
)

#$SubscriptionID = "adf124da-c139-44c5-b226-3a812fbe6cf0"  #DEV
#$SubscriptionID = "f1e34301-c396-4b15-9f25-cab99b61ce7a"  #HUB
#$SubscriptionID = "9fa297b7-731b-4d35-b494-e2b65749f1b7"  #PRD
#$SubscriptionID = "dc212303-893e-404d-a787-3a960b14e8bf"  #TST

$connectionName = "AzureRunAsConnection"
$Role = "Virtual Machine Operator"
$Scope = "VirtualMachine"
$SqlCred = Get-AutomationPSCredential -Name 'SSPAzureSQLServerAccount'
#$RecordsPerBatch = 10
$InitialExecutionDatetime = (Get-Date)
$RetunrObjItm = new-object PSObject
$DefaultRoleUserDisplayName = "Freddy Mora Silva"
$DefaultRoleUserSignInName = "freddy.silva@eversource.com"
$SqlServerPort = "1433"
$SqlUsername = $SqlCred.UserName
$SqlPass = $SqlCred.GetNetworkCredential().Password
$SQLConn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$SqlServer,$SqlServerPort;Database=$Database;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;") 
         
# Open the SQL connection 
Write-output "Connecting to SQL Database"
$SQLConn.Open() 

# Define the SQL command to run. In this case we are getting the number of rows in the table 
Write-output "Creating SQL Adapter, DataSet and Command Objects"

$SqlAdapter = New-Object system.Data.SqlClient.SqlDataAdapter
$Dataset = New-Object System.Data.DataSet
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand

$SQLCmd.CommandTimeout = 120 
$SqlCmd.Connection = $SQLConn

Write-output "Executing to get VMs Collection"

$Dataset.Reset()
$SqlQuery1 = "SELECT TOP 1 VMS.[RequestID],VMS.[AzureVMName],VMS.[Username],ST.StatusText,APR.ApproverName,BSS.BusinessUnitName,APT.AppTypeName,DPT.DepartmentName,VMS.[CostCenter],VMS.[OwnerDescription],ENV.EnvironmentName,REG.RegionName,NET.NetworkResourceGroupName,VRT.VirtualNetworkName,SNT.SubNetName FROM [dbo].[AzureVMs] VMS INNER JOIN RequestStatus ST On VMS.StatusID = ST.StatusID INNER JOIN Approvers APR On VMS.ApproverID = APR.ApproverID INNER JOIN BusinessUnits BSS On VMS.BusinessUnitID = BSS.BusinessUnitID INNER JOIN AppTypes APT On VMS.AppTypeID = APT.AppTypeID INNER JOIN Departments DPT On VMS.DepartmentID = DPT.DepartmentID INNER JOIN Environments ENV On VMS.EnvironmentID = ENV.EnvironmentID INNER JOIN Region REG On VMS.RegionID = REG.RegionID INNER JOIN NetworkResourceGroup NET On VMS.NetworkResourceGroupID = NET.NetworkResourceGroupID INNER JOIN VirtualNetwork VRT On VMS.VirtualNetworkID = VRT.VirtualNetworkID INNER JOIN SubNet SNT On VMS.SubNetID = SNT.SubNetID ORDER BY VMS.[RequestID] DESC"
$SqlCmd.CommandText = $SqlQuery1
$SqlAdapter.SelectCommand = $SqlCmd
$SqlAdapter.Fill($Dataset)

# Output the count 
$VMSTable = $Dataset.Tables[0]

#Load Data in Array
$VMSArray = @()
$VMSArray = @($VMSTable)

$CurrCount = $VMSArray.Count
$CurrentVMCount = 0

if ($CurrCount -gt 0) 
{
    $strCurrentVMCount = $VMSArray[0].RequestID
    $CurrentVMCount = [System.Int32]::Parse($strCurrentVMCount.Substring(10, 5))
}
else 
{
    $CurrentVMCount = 0
}

Write-output "Current VM Count in Database is $CurrentVMCount" 

#Get Names Collection
#Write-output "Get VM Names Collection"

#$VMNames = $VMSArray | Foreach-Object {$_.AzureVMName} | Select -Unique

#Get Current Resource Groups
# Execute the SQL command 
Write-output "Getting NetWork Resource Groups from DB"

$Dataset.Reset()
$SqlQuery2 = "Select [NetworkResourceGroupName] from [dbo].[NetworkResourceGroup]"
$SqlCmd.CommandText = $SqlQuery2
$SqlAdapter.SelectCommand = $SqlCmd
$SqlAdapter.Fill($Dataset)

# Output the count 
$ResGroupsTable = $Dataset.Tables[0]

#Load Data in Array
$ResGroupsArray = @()
$ResGroupsArray = @($ResGroupsTable)

#$VMSArray

#Get Names Collection
Write-output "Get Resource Group Names Collection"

$ResGroupNames = $ResGroupsArray | Foreach-Object {$_.NetworkResourceGroupName}  | Select -Unique

#Connect to Azure
Write-output "Connecting to Azure"

# Get the connection "AzureRunAsConnection "        
$Conn = Get-AutomationConnection -Name $connectionName 
$Cred = Get-AutomationPSCredential -Name 'ASRServicePrincipal'

$AzureLoginResults = Login-AzureRmAccount -ServicePrincipal -Credential $Cred -TenantId $Conn.TenantId -ErrorAction SilentlyContinue -ErrorVariable LoginError

#$AzureADLoginResults
#$LoginADError
if ($LoginError.Count -gt 0) 
{
    $ErrorDetails = $LoginError.Exception.Message;
    Write-Output "Login failed with Error: $ErrorDetails"
    $LoginStatus = "Failed"

    $RetunrObjItm = new-object PSObject
    $RetunrObjItm | add-member NoteProperty "Virtual Machine Operator Status" -value $LoginStatus
    $RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails
    
}
else 
{
    Write-Output "Setting Subscription"
    $subs = Get-AzureRmSubscription
    
    Write-Output "Connecting to Azure AD"

    $AzureADLoginResults = Connect-AzureAD -ApplicationId $Conn.ApplicationId -TenantId $Conn.TenantId -CertificateThumbprint $Conn.CertificateThumbprint -ErrorAction SilentlyContinue -ErrorVariable LoginADError
    
    #Check for Login Errors
    if ($LoginADError.Count -gt 0) 
    {
        $ErrorDetails = $LoginADError.Exception.Message;
        Write-Output "Login AD failed with Error: $ErrorDetails"
        $LoginStatus = "Failed"

        $RetunrObjItm = new-object PSObject
        $RetunrObjItm | add-member NoteProperty "Virtual Machine Operator Status" -value $LoginStatus
        $RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails
    
    }
    else 
    {
       Write-Output "Execute process per each Azure Subscription"

       foreach ($sub in $subs) 
       {
           $SubscriptionID=$sub.Id
           $SubsName = $sub.Name
           Write-Output "Connecting to Azure Subscription $SubsName"
           Select-AzureRmSubscription -SubscriptionId $SubscriptionID -TenantId $Conn.TenantId

           Write-output "Getting VM Collection from Azure"
           $VMs = Get-AzureRmVM -Status -WarningAction SilentlyContinue

           Write-output "Extracting Regions from VMs in Azure"

           $VMLocations = $VMs | Foreach-Object {$_.Location} | Select -Unique

           Write-output "Extracting Resource Groups from VMs in Azure"

           $VMResourceGroups = $VMs | Foreach-Object {$_.ResourceGroupName} | Select -Unique

           Write-output "Filtering Resource Groups from not existant in DB"

           $FilteredVMResourceGroups = $VMResourceGroups | Where-Object {$_ -notin $ResGroupNames}

           $SqlQuery3 = ""

           Write-output "Adding new Resource Groups from Azure to SQL Database"

           foreach ($ResGroupItm in $FilteredVMResourceGroups)
           {
                $ResourceGroupObj = Get-AzureRmResourceGroup -Name $ResGroupItm 

                $ResourceGroupRegion = $ResourceGroupObj.Location

                switch ($ResourceGroupRegion) {
                    "eastus2" {$VMRegionID = 1; break}
                    "eastus" {$VMRegionID = 2; break}
                }

                $ResourceGroupId = $ResourceGroupObj.ResourceId
                $ResourceGroupSubscription = $ResourceGroupObj.ResourceId.Split("/")[2]
                $ResourceGroupName = $ResourceGroupObj.ResourceGroupName

                $CurrSqlQuery = "Insert into [dbo].[NetworkResourceGroup] Values ('$ResourceGroupId','$ResourceGroupSubscription','$ResourceGroupName',$VMRegionID,'1'); "
                #$CurrSqlQuery
                $SqlQuery3 += $CurrSqlQuery
           }

           if ($SqlQuery3 -ne "") 
           {
                Write-output "New Resource Groups ready to be added to SQL Database"

                $SqlCmd.CommandText = $SqlQuery3
                $SqlAdapter.InsertCommand = $SqlCmd
                $SqlCmd.ExecuteNonQuery()

                Write-output "New Resource Groups added to SQL Database"
           }

           Write-output "Getting new collection of Resource Groups from SQL Database"

           $Dataset.Reset()
           $SqlQuery4 = "Select [NetworkResourceGroupID], [NetworkResourceGroupName], [RegionID] from [dbo].[NetworkResourceGroup]"
           $SqlCmd.CommandText = $SqlQuery4
           $SqlAdapter.SelectCommand = $SqlCmd
           $SqlAdapter.Fill($Dataset)

           # Output the count 
           $ResGroupsTable = $Dataset.Tables[0]

           #Load Data in Array
           $ResGroupsArray = @()
           $ResGroupsArray = @($ResGroupsTable)

           Write-output "Filter collection of VMs that are not in DB to add them to SQL Database"

           ##$FilteredNewVMs = $VMs | Where-Object {$_.Name -notin $VMNames -and $_.PowerState -eq "VM running"} | Select-Object -First 5
           #$FilteredNewVMs = $VMs | Where-Object {$_.Name -notin $VMNames} | Select-Object -First $RecordsPerBatch
           #$FilteredNewVMs = $VMs | Select-Object -First $RecordsPerBatch
           $FilteredNewVMs = $VMs

           Write-output "New VM Collection to be added to SQL Database"
           #$FilteredNewVMs

           #GET VMS COUNT
           $VMNewCount = $FilteredNewVMs.Count

           Write-output "VMs to be added to Temp Table are $VMNewCount"

           $CurrYear = (Get-Date).Year.ToString()

           $BulkSQLCommand = ""

           Write-output "Adding to SQL Command to Bulk execution"
           Select-AzureRmSubscription -SubscriptionId $SubscriptionID -TenantId $Conn.TenantId

            for ($itmNewVM = 0; $itmNewVM -lt $VMNewCount; $itmNewVM++) 
            {
                $CurrentVMCount += 1
                $VMRequestNumber = "AZUREQ" + $CurrYear + "{0:00000}" -f ($CurrentVMCount)

                $NewVM = $FilteredNewVMs[$itmNewVM]
                $VMName = $NewVM.Name
                $VMLocation = $NewVM.Location      
            
                $VMResourceGroup = $NewVM.ResourceGroupName
                $VMResourceGroupDB = $ResGroupsArray | Where-Object {$_.NetworkResourceGroupName -eq $VMResourceGroup}
                $VMResourceGroupID = $VMResourceGroupDB.NetworkResourceGroupID
                $VMRegionID = $VMResourceGroupDB.RegionID
                        
                $VMState = $NewVM.PowerState                

                switch ($VMState) 
                {
                    "VM deallocated" {$VMStateID = 9; break} 
                    "VM deallocating" {$VMStateID = 9; break} 
                    "VM stopped" {$VMStateID = 8; break} 
                    "VM stopping" {$VMStateID = 8; break} 
                    "VM starting" {$VMStateID = 7; break} 
                    "VM running" {$VMStateID = 7; break} 
                }
                $Tags = (Get-AzureRmResource -ResourceName $VMName -ResourceGroupName $VMResourceGroup).Tags
                $VMScope = (Get-AzureRmResource -ResourceGroupName $VMResourceGroup -ResourceName $VMName).ResourceId
                $AzureRoleObjColl = Get-AzureRmRoleAssignment -Scope $VMScope -RoleDefinitionName $Role -ErrorAction SilentlyContinue -ErrorVariable AzureRoleDefError
            
                $VMTagApplicationType = $Tags.ApplicationType
                $VMTagApplicationOwner = $Tags.ApplicationOwner
                $VMTagCostCenter = $Tags.CostCenter
                $VMTagApplicationCategory = $Tags.ApplicationCategory
                $VMTagDepartment = $Tags.Department                                                                                                       
            
                if ($VMTagApplicationType -eq "" -or $VMTagApplicationType -eq $null -or $VMTagApplicationType -eq "None") 
                {
                    $VMTagApplicationType = "N/A"
                }

                if ($VMTagApplicationOwner -eq "" -or $VMTagApplicationOwner -eq $null -or $VMTagApplicationOwner -eq "None") 
                {
                    $VMTagApplicationOwner = "N/A"
                }
            
                if ($VMTagCostCenter -eq "" -or $VMTagCostCenter -eq $null -or $VMTagCostCenter -eq "None") 
                {
                    $VMTagCostCenter = "N/A"
                }
            
                if ($VMTagApplicationCategory -eq "" -or $VMTagApplicationCategory -eq $null -or $VMTagApplicationCategory -eq "None") 
                {
                    $VMTagApplicationCategory = "N/A"
                }
            
                if ($VMTagDepartment -eq "" -or $VMTagDepartment -eq $null -or $VMTagDepartment -eq "None") 
                {
                    $VMTagDepartment = "N/A"
                }

                if ($AzureRoleObjColl -eq $null)
                 {
                    Write-output "Adding $VMRequestNumber Unassigned VM $VMName to to SQL Command"

                    $VMMachineComment = "Virtual Machine Unassigned"
                
                    $CurrentSQLCommand = " insert into  [dbo].[AzureTempVMs] values ('$VMRequestNumber','$VMName',0,23,0,23,'0',1,'$DefaultRoleUserDisplayName','password','$DefaultRoleUserSignInName',1,$VMStateID,1,1,4,1,NULL,'N/A','$VMMachineComment',1,$VMRegionID,$VMResourceGroupID,1,1,'$SubscriptionID'); "
                    #$CurrentSQLCommand

                    $BulkSQLCommand += $CurrentSQLCommand
                }
                else 
                {
                    foreach ($AzureRoleObj in $AzureRoleObjColl) 
                    {
                        #Iterate the Group and its members in Virtual Machine Operator Role
                        if($AzureRoleObj.ObjectType -eq 'Group')
                        {
                            $AzureObjectId = $AzureRoleObj.ObjectId
                            #$AzureObjectId
                            $members= Get-AzureADGroupMember -ObjectId $AzureObjectId -ErrorAction SilentlyContinue -ErrorVariable AzureADGroupMemberError

                            if ($AzureADGroupMemberError.Count -gt 0) 
                            {
                                $ErrorDetails = $AzureADGroupMemberError.Exception.Message;
                                Write-Output "Get-AzureADGroupMember failed with Error: $ErrorDetails"
                            }
                            else
                            {
                                foreach ($member in $members)
                                {
                                    $CurrentVMCount +=1
                                    $VMRequestNumber = "AZUREQ" + $CurrYear + "{0:00000}" -f ($CurrentVMCount)

                                    $RoleUserDisplayName = $member.DisplayName
                                    $RoleUserSignInName = $member.UserPrincipalName

                                    Write-output "Adding $VMRequestNumber assigned to $RoleUserDisplayName VM $VMName to to SQL Command"

                                    $VMMachineComment = "Virtual Machine Assigned to $RoleUserDisplayName"
                            
                                    $CurrentSQLCommand = " insert into  [dbo].[AzureTempVMs] values ('$VMRequestNumber','$VMName',0,23,0,23,'0',1,'$RoleUserDisplayName','password','$RoleUserSignInName',1,$VMStateID,1,1,4,1,NULL,'N/A','$VMMachineComment',1,$VMRegionID,$VMResourceGroupID,1,1,'$SubscriptionID'); "
                            #        $CurrentSQLCommand

                                    $BulkSQLCommand += $CurrentSQLCommand
                                }
                            }
                        }
                        #Iterate the User in Virtual Machine Operator Role
                        else
                        {
                            $CurrentVMCount += 1
                            $VMRequestNumber = "AZUREQ" + $CurrYear + "{0:00000}" -f ($CurrentVMCount)

                            $RoleUserDisplayName = $AzureRoleObj.DisplayName
                            $RoleUserSignInName = $AzureRoleObj.SignInName


                            Write-output "Adding $VMRequestNumber assigned to $RoleUserDisplayName VM $VMName to to SQL Command"

                            $VMMachineComment = "Virtual Machine Assigned to $RoleUserDisplayName"
                    
                            $CurrentSQLCommand = " insert into  [dbo].[AzureTempVMs] values ('$VMRequestNumber','$VMName',0,23,0,23,'0',1,'$RoleUserDisplayName','password','$RoleUserSignInName',1,$VMStateID,1,1,4,1,NULL,'N/A','$VMMachineComment',1,$VMRegionID,$VMResourceGroupID,1,1,'$SubscriptionID'); "
                            #$CurrentSQLCommand

                            $BulkSQLCommand += $CurrentSQLCommand
                        }
                    
                    }

                }

              #END OF FOR EACH VM
            }
           
            if ($BulkSQLCommand -ne "") 
            {
                Write-output "Prepared to Execute Bulk SQL Command"
                $BulkSqlCmd = New-Object System.Data.SqlClient.SqlCommand
                $BulkSqlAdapter = New-Object system.Data.SqlClient.SqlDataAdapter
                $BulkSqlCmd.CommandTimeout = 120 
                $BulkSqlCmd.Connection = $SQLConn
                $BulkSqlCmd.CommandType = [System.Data.CommandType]::Text
                $BulkSqlCmd.CommandText = $BulkSQLCommand
                $BulkSqlAdapter.InsertCommand = $BulkSqlCmd
                $BulkSqlCmd.ExecuteNonQuery()
                Write-output "Executed Bulk SQL Command"
                $BulkSQLCommand=""
                $BulkSqlCmd=$null
                $BulkSqlAdapter=$null
                #Executing Final Stored Procedure to Update VM Table

                Write-output "Executing Final Stored Procedure to Update VM Table"

                $SPSqlCmd = New-Object System.Data.SqlClient.SqlCommand
                $SPSqlAdapter = New-Object system.Data.SqlClient.SqlDataAdapter
                $SPSqlCmd.CommandTimeout = 120 
                $SPSqlCmd.Connection = $SQLConn
                $SPSqlCmd.CommandText = "UpDateVMTable"
                $SPSqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
                $SPSqlCmd.Parameters.Add("@SubscriptionID", "$SubscriptionID")
                $SPSqlAdapter.UpdateCommand = $SPSqlCmd
                $SPSqlCmd.ExecuteNonQuery()
                $SPSqlCmd=$null
                $SPSqlAdapter=$null
                Write-output "Executed UpdateVMTable Stored Procedure"
                $Dataset.Reset()
                $ResGroupsTable.Reset()
            }

           #END OF FOR EACH SUBS
       }

       #END OF ELSE
    }

    
}

# Close the SQL connection 
$SQLConn.Close()

$FinalExecutionDatetime = (Get-Date)

$InitialExecutionDatetimeDate = $InitialExecutionDatetime.Date 
$FinalExecutionDatetimeDate = $FinalExecutionDatetime.Date 

Write-Output "Script Started at $InitialExecutionDatetimeDate" 
Write-Output "Script Finished at $FinalExecutionDatetimeDate" 
 
[int32] $TotalExecutionTimeInSeconds = (New-TimeSpan -Start $InitialExecutionDatetime -End $FinalExecutionDatetime).TotalSeconds
[int32] $TotalExecutionTimeInMinutes = ($TotalExecutionTimeInSeconds / 60)


Write-Output "Total Script execution time in Seconds $TotalExecutionTimeInSeconds"
Write-Output "Total Script execution time in Minutes $TotalExecutionTimeInMinutes"
