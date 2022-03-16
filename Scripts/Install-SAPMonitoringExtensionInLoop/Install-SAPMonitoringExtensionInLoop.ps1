<# 	
 .NOTES
	==============================================================================================
	File:		Install-MonitoringExtensionInLoop.ps1
	
	Purpose:	To Install Monitoring Extension In Loop
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Installs monitoring extension in loop on Linux VMs
  
 .DESCRIPTION
	This script is used to Installs monitoring extension in loop on Linux VMs
		
 .EXAMPLE
	C:\PS>  .\Install-MonitoringExtensionInLoop.ps1
	
	Description
	-----------
	This command executes the script with default parameters.
     
 .INPUTS
    None.

 .OUTPUTS
    None.
		   
 .LINK
	https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/deployment-guide#2ad55a0d-9937-4943-9dd2-69bc2b5d3de0
#>

#Inputs
$subscriptionName = "you-subscription-name"

#Adding Azure Account and Subscription
$env = Get-AzEnvironment -Name "AzureCloud"
Connect-AzAccount -Environment $env
Set-AzContext -SubscriptionName $subscriptionName

#Selecting all RGs that begins with the text. Notice the wildcard in the name
#TODO: Update this to a specific resource group or a similar query with wildcards
$allSapRGs = Get-AzResourceGroup -Name "RG-IT-*"

foreach($currentRG in $allSapRGs)
{
    #Fetch all resources in the RG
    $currentRGName = $currentRG.ResourceGroupName
    $VMs = Get-AzVM -ResourceGroupName $currentRGName

    #Iterating on the VMs
    foreach ($vm in $VMs) 
    {
        $VMName = $vm.name
        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Host "Working on VM: $VMName"

        if ($osType -eq "Linux") {
            Write-Host "VM $VMName is a Linux VM. Proceeding with the installation."
            try {
                Set-AzVMAEMExtension -ResourceGroupName $currentRGName -VMName $VMName -InstallNewExtension

                Write-Host -ForegroundColor Green "Installed the extension on the VM $VMName"
            }
            catch {
                Write-Host -ForegroundColor Red "Error while installing extension."
                $Error[0]
                Write-Host -ForegroundColor Red "Error occured at:"
                $Error[0].InvocationInfo.PositionMessage
            }
        }
        else {
            Write-Host "VM $VMName is not a Linux VM"
        }
        
    }
}
