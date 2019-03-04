PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('Path')]
	[String] $ConfigFilePath = ".\Convert-VMToManagedDisk - Config.csv",

    [Parameter(Mandatory = $True)]
    [Alias('Subscription')]
	[String] $SubscriptionName = "Your-Subscription-Name"
)

#region Functions
function Convert-VMToManagedDisk {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
      HelpMessage='name of the Virtual Machine')]
    [Alias('vm')]
    [string]$virtualMachineName,
[Parameter(Mandatory=$True,
      HelpMessage='name of the Resource Group of the Virtual Machine')]
    [Alias('rg')]
    [string]$ResourceGroupName
  )
    
    Write-Verbose "Converting the VM $virtualMachineName to Managed Disks. "
        
    $currentVm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $virtualMachineName -ErrorAction Stop
    if($currentVm.StorageProfile.OsDisk.ManagedDisk -eq $null)
    {
        if($currentVm.AvailabilitySetReference -ne $null)
        {
            Write-Host "Current VM $virtualMachineName is in an Availability Set."
            $asIds = $currentVm.AvailabilitySetReference.Id.Split("/")
            $rgName = $asIds[4]
            $asName = $asIds[8]

            $avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $asName -ErrorAction Stop

            if($avSet.Managed -eq $False)
            {
                Update-AzureRmAvailabilitySet -AvailabilitySet $avSet -Managed -ErrorAction Stop
            }

            foreach($vmInfo in $avSet.VirtualMachinesReferences)
            {
                $vm =  Get-AzureRmVM -ResourceGroupName $rgName | Where-Object {$_.Id -eq $vmInfo.id}

                if($vm.StorageProfile.OsDisk.ManagedDisk -eq $null)
                {
                    Write-Host "Stopping the VM $($vm.Name)."
                    Stop-AzureRmVM -ResourceGroupName $rgName -Name  $vm.Name -Force

                    Write-Host "Converting the VM $($vm.Name) to Managed Disks VM."
                    ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vm.Name

                    Start-Sleep -Seconds 600

                    Write-Verbose "Successfully converted the VM $($vm.Name) to Managed Disks. "
                }
                else
                {
                    Write-Host "VM $($vm.Name) in Availability Set $asName is already a Managed Disks VM"
                }

            }
        }
        else
        {
            Write-Host "Current VM $virtualMachineName is not in an Availability Set."
                
            Write-Host "Stopping the VM $virtualMachineName."
            Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $virtualMachineName -Force

            Write-Host "Converting the VM $virtualMachineName to Managed Disks VM."
            ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $ResourceGroupName -VMName $virtualMachineName

            Write-Verbose "Successfully converted the VM $virtualMachineName to Managed Disks. "
        }
    }
    else
    {
        Write-Host "Current VM $virtualMachineName is already Managed Disks VM."
    }
}

function Test-FileExists
{
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SourceFile
	)
	
	try
	{
		if (Test-Path $SourceFile)
		{
			Write-Debug "   Located: $SourceFile. "
			
			return $true
		}
		else
		{
			Write-Debug "   Could not locate: $SourceFile. "
			return $false
		}
	}
	catch [system.exception]
	{
		Write-Verbose "Error in Test-FileExists(): $($_.Exception.Message) "
        Write-Host "Error in Test-FileExists(): $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
		Stop-Transcript
		Exit $ERRORLEVEL
	}
}

#endregion


Start-Transcript $ScriptLog
Write-Verbose "======================================================================"
Write-Verbose "Script Started."

    try
    {
        #region Login into the Azure Subscription
        #TODO - If you want to make script fully automated, you can change this line to use a Service Principal (i.e. An App Registration) for Loging into Azure
        Add-AzureRmAccount

        Select-AzureRmSubscription -SubscriptionName $SubscriptionName

        #endregion

        if(Test-FileExists -SourceFile $ConfigFilePath)
        {
            $configSettings = Import-Csv -Path $ConfigFilePath
            
            foreach($configSetting in $configSettings)
            {
                Convert-VMToManagedDisk -virtualMachineName $configSetting.Computer -ResourceGroupName $configSetting.ResourceGroupName
                #TODO - Any Additional Code can come here
            }
        }
        else
        {
            Write-Host "Configuration File not found."
        }
    }
    catch [system.exception]
	{
		Write-Verbose "Script Error: $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
		Stop-Transcript
	}

Write-Verbose "Script Completed. "
Write-Verbose "======================================================================"
Stop-Transcript
#endregion