<#
.Synopsis
   PowerShell script will grant role to users or groups at Subscription/ResourceGroup/VirtualMachine Level
.DESCRIPTION
   PowerShell script will grant role to users or groups at Subscription/ResourceGroup/VirtualMachine Level
.EXAMPLE
   Apply-RBACRoleToResources -csvLocation "C:\Users\aman\Documents\AzureVM.csv" -role "Virtual Machine Operator" -Scope "VirtualMachine" -UserNames "gurpreet,aman" -GroupNames "abac" 
.EXAMPLE
   Apply-RBACRoleToResources -csvLocation "C:\Users\aman\Documents\AzureVM.csv" -role "Virtual Machine Operator" -Scope "ResourceGroup" -UserNames "gurpreet,aman" -GroupNames "abac" 
.INPUTS
   CSVLocation, role, scope, usernames, groupnames,
    •	csvLocation:- Path of the CSV File
    •	Role:- Name of the role
    •	Scope:- Grant access at Subscription\ResourceGroup\VirtualMachine Level
    •	UserNames:- Give multiple user names separated by a comma
    •	GroupNames:- Give multiple groups separated by a comma
 
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Apply-RBACRoleToResources
{
    param 
    (
        [parameter(Mandatory = $true)]
        [String]$csvLocation,
        [parameter(Mandatory = $true)]
        [String]$role,
        [parameter(Mandatory = $false)]
        [ValidateSet("VirtualMachine", "Subscription", "ResourceGroup")]
        [String]$Scope,
        [parameter(Mandatory = $false)]
        [String]$UserNames,
        [parameter(Mandatory = $true)]
        [String]$GroupNames,
        [parameter(Mandatory = $false)]
        [boolean] $RBACVMOperatorFlag = $true
    )

    if ($RBACVMOperatorFlag) 
    {
        $UserFlag = $True
        $GroupFlag = $True
        $UserNamesArray = @() 
        $GroupNamesArray = @()  
 
        if ($UserNames -ne $null) 
        {
            $UserNamesArray = $UserNames.Split(',')
            $UserFlag = $True
        } 
        else 
        {
            $UserFlag = $False
        }
        if ($GroupNames -ne $null) 
        {
            $GroupNamesArray = $GroupNames.Split(',')
            $GroupFlag = $True
        } 
        else 
        {
            $GroupFlag = $False
        }
        if ($UserFlag -or $GroupFlag) 
        {   
            if (Test-Path -Path $csvLocation) 
            {
           
                Write-Host "Importing CSV File"
                $csvImport = Import-Csv -Path $csvLocation 
            }
            else {
                Write-Host "CSV FILE NOT FOUND!"
                Exit
            }
           
            $AzureLoginResults = Login-AzureRmAccount -ErrorAction SilentlyContinue -ErrorVariable LoginError
            Write-Host "Login to Azure"
            #Check for Login Errors
            if ($LoginError.Count -gt 0) 
            {
                $ErrorDetail = $LoginError.Exception.Message;
                Write-Verbose "Login failed with Error: $ErrorDetails"
                $LoginStatus = "Failed"
                $RetunrObjItm = new-object PSObject
                $RetunrObjItm | add-member NoteProperty "VMName" -value $VMName
                $RetunrObjItm | add-member NoteProperty "RBAC Virtual Machine Operator Status" -value $LoginStatus
                $RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails
    
            }
            else 
            {  
                foreach ($csvItem in $csvImport) 
                {
                   $VMName = $csvItem.VM
                   $VMResourceGroup = $csvItem.ResourceGroup
                   #$SelectSub = Select-AzureRmSubscription -SubscriptionId $AzureLoginResults.SubscriptionId
                   $AzureROleObj = Get-AzureRmRoleDefinition $role -ErrorAction SilentlyContinue -ErrorVariable AzureRoleDefError

                    if ($AzureRoleDefError.Count -gt 0) 
                    {
                        $ErrorDetails = $AzureRoleDefError[0].Exception.Message
                        Write-Verbose "RBAC for $role failed with Error: $ErrorDetails"
                        $RBACStatus = "Failed"
                        $RetunrObjItm = new-object PSObject
                        $RetunrObjItm | add-member NoteProperty "RBAC ROle" -value $role
                        $RetunrObjItm | add-member NoteProperty "RBAC Status" -value $RBACStatus
                        $RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails

                    }
                    else 
                    {       
                        if ($Scope -eq "Subscription") 
                        {
                            $scope = "/subscriptions/" + $AzureLoginResults.SubscriptionId
                            
                        }
                        elseif ($Scope -eq "ResourceGroup") 
                        {
                            $scope = (Get-AzureRmResourceGroup -Name $VMResourceGroup).ResourceId
                        }
                        elseif ($Scope -eq "VirtualMachine") 
                        {
                           
                            $scope = (Get-AzureRmResource -ResourceGroupName $VMResourceGroup -ResourceName $VMName).ResourceId

                        }
                        if ($scope -ne $null) 
                        {
                            $RetunrObjItm = new-object PSObject
                            [int]$countUser = 0
                            [int]$countGroup = 0
                            foreach ($UserName in $UserNamesArray) 
                            {
                                $countUser++
                                $ObjectID = (Get-AzureRmADUser -SearchString $UserName).Id
                                $RBACObj = New-AzureRmRoleAssignment -ObjectId $ObjectID -Scope $scope -RoleDefinitionName $AzureROleObj.Name -ErrorAction SilentlyContinue -ErrorVariable RBACError
                                if ($RBACError.Count -gt 0) 
                                {
                                    $ErrorDetails = $RBACError[0].Exception.Message
                                    Write-Verbose "RBAC for $UserName failed with Error: $ErrorDetails"
                                    $RBACStatus = "Failed"
                                    $RetunrObjItm | add-member NoteProperty "User Name$countUser" -value $UserName
                                    $RetunrObjItm | add-member NoteProperty "RBAC User Status$countUser" -value $RBACStatus
                                    $RetunrObjItm | add-member NoteProperty "ErrorDetails User$countUser" -value $ErrorDetails
                                }
                                else 
                                {               
                                    Write-Verbose "RBAC for $UserName Succeed"
                                    $RBACStatus = "Succeed"
                                    $RetunrObjItm | add-member NoteProperty "User Name$countUser" -value $UserName
                                    $RetunrObjItm | add-member NoteProperty "RBAC User Status$countUser" -value $RBACStatus             
                                }           
                            }
                            foreach ($GroupName in $GroupNamesArray) 
                            {
                                $countGroup++
                                $ObjectID = (Get-AzureRmADGroup -SearchString $GroupName).Id
                                $RBACObj = New-AzureRmRoleAssignment -ObjectId $ObjectID -Scope $scope -RoleDefinitionName $AzureROleObj -ErrorAction SilentlyContinue -ErrorVariable RBACError
                                if ($RBACError.Count -gt 0) 
                                {
                                    $ErrorDetails = $RBACError[0].Exception.Message
                                    Write-Verbose "RBAC for $GroupName failed with Error: $ErrorDetails"
                                    $RBACStatus = "Failed"
                                    $RetunrObjItm | add-member NoteProperty "Group Name$countGroup" -value $GroupName
                                    $RetunrObjItm | add-member NoteProperty "RBAC Group Status$countGroup" -value $RBACStatus
                                    $RetunrObjItm | add-member NoteProperty "ErrorDetails Group$countGroup" -value $ErrorDetails
                                }
                                else 
                                {               
                                    Write-Verbose "RBAC for $GroupName Succeed"
                                    $RBACStatus = "Succeed"
                                    $RetunrObjItm | add-member NoteProperty "Group Name$countGroup" -value $GroupName
                                    $RetunrObjItm | add-member NoteProperty "RBAC Group Status$countGroup" -value $RBACStatus             
                                }           
                            }
                        }
                        else 
                        {
                            $ErrorDetails = "RBAC for role failed with Error: Unable to retreive Scope ResourceID"
                            Write-Verbose $ErrorDetails
                            $RBACStatus = "Failed"
                            $RetunrObjItm = new-object PSObject
                            $RetunrObjItm | add-member NoteProperty "RBAC ROle" -value $role
                            $RetunrObjItm | add-member NoteProperty "RBAC Status" -value $RBACStatus
                            $RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails
                        }                            
                         
                    }
 
                }
            }
        }
        else 
        {
            Write-Host "Please enter user or group details"
        }
    }
    else 
    {
        Write-Host "RBACFlag is set to False.No RBAC task is performed"
        $RBACStatus = "RBAC Backup Flag is False.No RBAC task is performed"
        $RetunrObjItm = new-object PSObject
        $RetunrObjItm | add-member NoteProperty "RBACStatus" -value $RBACStatus
    }
    Write-Verbose "RetunrObjItm : $RetunrObjItm"
    Write-Output $RetunrObjItm
}