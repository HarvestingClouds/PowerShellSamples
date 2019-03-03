param (
    [parameter(Mandatory=$true)]
    [Object]$RecoveryPlanContext,
    [parameter(Mandatory=$true)]
    [Boolean]$TestExecution
)

Write-Verbose -Message $RecoveryPlanContext
Write-Verbose "checking variable"

#TESTING
if($TestExecution)
{
    Write-Verbose -Message "Using TestExecution Flag"
    $RecoveryPlanContextObj = $RecoveryPlanContext | ConvertFrom-Json
}
else
{
    $RecoveryPlanContextObj = $RecoveryPlanContext
    Write-Verbose -Message "Not Using TestExecution Flag"
}
#TESTING


#Write-Output "Using TestExecution Flag "
#Change
#$RecoveryPlanContextObj = $RecoveryPlanContext | ConvertFrom-Json
#Write-Output "Ccheck :: $VMMapColl"

Write-Verbose "getting vmmap object"
$VMMapColl = $RecoveryPlanContextObj.VmMap
Write-Verbose -Message $VMMapColl
Write-Verbose "after getting vmmap object"

$VMCollection = @()

if($VMMapColl -ne $null)
{
    Write-Verbose -Message "VMMapColl Variable is Not Null"
    #Write-Ouput "VMMapColl Variable is Not Null"
    $VMinfo = $VMMapColl | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
    #$vmMap = $RecoveryPlanContextObj.VmMap

    foreach($VMID in $VMinfo)
    {
        $VM = $VMMapColl.$VMID        
                
        if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) 
        {
            $VM | Add-Member NoteProperty RecoveryPlanName $RecoveryPlanContextObj.RecoveryPlanName
            $VM | Add-Member NoteProperty FailoverType $RecoveryPlanContextObj.FailoverType
            $VM | Add-Member NoteProperty FailoverDirection $RecoveryPlanContextObj.FailoverDirection
            $VM | Add-Member NoteProperty GroupId $RecoveryPlanContextObj.GroupId
            $VM | Add-Member NoteProperty VMId $VMID

            $VMCollection += $VM
        }
    }
}
else
{
     Write-Verbose -Message "VMMapColl Variable is Null"
     #Write-Output -Message "VMMapColl Variable is Null"
}

$CollectionCount = $VMCollection.Count
Write-Verbose "Collection Count: $CollectionCount" 

#Returning Collection
Write-Output $VMCollection