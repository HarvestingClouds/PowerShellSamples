PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('Path')]
	[String] $ConfigFilePath = ".\Change-AzureVMSize - Config.csv",

    [Parameter(Mandatory = $True)]
    [Alias('Subscription')]
	[String] $SubscriptionName = "Your-Subscription-Name"
)

#region Functions
function Change-AzureVMSize {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
      HelpMessage='name of the Virtual Machine')]
    [Alias('vm')]
    [string]$virtualMachineName,

    [Parameter(Mandatory=$True,
      HelpMessage='new size of the Virtual Machine')]
    [Alias('size')]
    [string]$vmSize,
[Parameter(Mandatory=$True,
      HelpMessage='name of the Resource Group of the Virtual Machine')]
    [Alias('rg')]
    [string]$ResourceGroupName
  )
    
    Write-Verbose "Fetching the VM $virtualMachineName."
    $currentVm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $virtualMachineName -ErrorAction Stop
        
    if($currentVm -ne $null)
    {
        if($currentVm.HardwareProfile.VmSize -eq $vmSize )
        {
            Write-Verbose "VM $virtualMachineName is already of size $vmSize. No further action will be take on this VM."
            Write-Host "VM $virtualMachineName is already of size $vmSize. No further action will be take on this VM."
        }
        else
        {
            Write-Verbose "Changing Size of the VM $virtualMachineName."
            $currentVm.HardwareProfile.VmSize = $vmSize 
            
            Write-Verbose "Updating VM $virtualMachineName."
            Update-AzureRmVM -VM $currentVm -ResourceGroupName $ResourceGroupName

            Write-Verbose "Successfully changed size of the VM $virtualMachineName."
        }
    }
    else
    {
        throw "VM $virtualMachineName Not Found in resource group named $ResourceGroupName."
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
                Change-AzureVMSize -virtualMachineName $configSetting.Computer -ResourceGroupName $configSetting.ResourceGroupName -vmSize $configSetting.NewVMComputeSize
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