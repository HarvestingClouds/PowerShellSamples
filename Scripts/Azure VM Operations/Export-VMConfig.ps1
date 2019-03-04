PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('Path')]
	[String] $ConfigFilePath = ".\Export-VMConfig - Config.csv",

    [Parameter(Mandatory = $True)]
    [Alias('Subscription')]
	[String] $SubscriptionName = "Your-Subscription-Name"
)

#region Functions
function Export-VMConfig {
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
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$True,
      HelpMessage='name of the Stage of Operation')]
    [Alias('stage')]
    [string]$OperationStage
  )
    try
    {
        Write-Verbose "Exporting Information for VM $virtualMachineName."
        $currentVm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $virtualMachineName -ErrorAction Stop
        
        $timeStamp = (Get-Date).ToString("MM-dd-yyyy-HH-mm-ss")
        $fileName = $virtualMachineName + "-" + $OperationStage + "-" + $timeStamp + '.json'

        Write-Host "Outputing VM configurations for VM $virtualMachineName at stage $OperationStage at time $timeStamp ."
        $currentVm | ConvertTo-Json -Depth 100 | Out-File -FilePath $fileName

        Write-Verbose "Successfully information for the VM $virtualMachineName."
    }
    catch [system.exception]
    {
	    Write-Verbose "Failed to export the information for VM $virtualMachineName. "
	    Write-Verbose "Error in Change-AzureVMSize(): $($_.Exception.Message) "
        Write-Host "Error in Change-AzureVMSize() for $virtualMachineName : $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
        Stop-Transcript

        Export-VMOperation
	    Exit $ERRORLEVEL
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
                Export-VMConfig -virtualMachineName $configSetting.Computer -OperationStage "Processing" -ResourceGroupName $configSetting.ResourceGroupName
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