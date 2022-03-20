<# 	
 .NOTES
	==============================================================================================
	File:		Enable-RHELBYOLLicense.ps1
	
	Purpose:	To enable RHEL BYOL on Azure VMs
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	To enable RHEL BYOL on Azure VMs
  
 .DESCRIPTION
	This script is used to enable RHEL BYOL on Azure VMs
		
 .EXAMPLE
	C:\PS>  .\Enable-RHELBYOLLicense.ps1
	
	Description
	-----------
	This command executes the script with default parameters.
     
 .INPUTS
    None.

 .OUTPUTS
    None.
		   
 .LINK
	None.
#>

#Inputs
$subscriptionName = "Your-Subscription-Name-Here"

#Adding Azure Account and Subscription
$env = Get-AzEnvironment -Name "AzureCloud"
Connect-AzAccount -Environment $env
Set-AzContext -SubscriptionName $subscriptionName

#Selecting all RGs that begins with the text. Notice the wildcard in the name
$allRHELRGs = Get-AzResourceGroup -Name "RG-IT-*"

foreach($currentRG in $allRHELRGs)
{
    #Fetch all VMs in the RG
    $currentRGName = $currentRG.ResourceGroupName
    $VMs = Get-AzVM -ResourceGroupName $currentRGName

    #Iterating through all VMs in the RG
    foreach ($vm in $VMs) 
    {
        $VMName = $vm.name
        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Host "Working on VM: $VMName"

        #Checking if the OS type is Linux or not for the VM
        if ($osType -eq "Linux") {
            Write-Host "VM $VMName is a Linux VM"
            try {
                #Setting the License Type
                $vm.LicenseType = "RHEL_BYOS"
                #Updating the VM with the License type
                Update-AzVM -VM $vm -ResourceGroupName $currentRGName
                Write-Host -ForegroundColor Green "Set the License type to RHEL_BYOS on $VMName"
            }
            catch {
                # Printing Error details
                Write-Host -ForegroundColor Red "Error while setting License type."
                $Error[0]
                Write-Host -ForegroundColor Red "Error occured at:"
                $Error[0].InvocationInfo.PositionMessage
            }
        }
        else {
            #The VM is not a Linux VM
            Write-Host "VM $VMName is not a Linux VM"
        }
        
    }
}
