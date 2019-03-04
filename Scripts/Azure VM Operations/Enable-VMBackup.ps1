PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('Path')]
	[String] $ConfigFilePath = ".\Enable-VMBackup - Config.csv",

    [Parameter(Mandatory = $True)]
    [Alias('Subscription')]
	[String] $SubscriptionName = "Your-Subscription-Name"
)

#region Functions
function Enable-VMBackup {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
      HelpMessage='name of the Virtual Machine')]
    [Alias('vm')]
    [string]$virtualMachineName,

[Parameter(Mandatory=$True,
      HelpMessage='name of the Recovery Services Vault ')]
    [Alias('vault')]
    [string]$RecoveryServicesVaultName,

[Parameter(Mandatory=$True,
      HelpMessage='name of the Backup Protection Policy ')]
    [Alias('policy')]
    [string]$BackupProtectionPolicy,

[Parameter(Mandatory=$True,
      HelpMessage='name of the Resource Group of the Virtual Machine')]
    [Alias('rg')]
    [string]$ResourceGroupName
  )
    
    Write-Verbose "Enabling Backup on the VM $virtualMachineName."
    
    Write-Host "Fetching the Recovery Services Vault"
    $recoveryServicesVault = Get-AzureRmRecoveryServicesVault -Name $RecoveryServicesVaultName

    if($recoveryServicesVault -eq $null)
    {
        throw "Recovery Services Vault $RecoveryServicesVaultName not found in the current subscription."
    }

    Write-Host "Setting up the Recovery Services Vault Context"
    $recoveryServicesVault | Set-AzureRmRecoveryServicesVaultContext -ErrorAction Stop


    #Check if backup is already configured
    $namedContainerCheck = Get-AzureRmRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName $virtualMachineName
    
    if($namedContainerCheck -ne $null)
    {
        Write-Host "Backup is already configured on the VM $virtualMachineName"
    }
    else
    {
        #Enabling Backup
        Write-Host "Fetching the Backup Policy"
        $policy = Get-AzureRmRecoveryServicesBackupProtectionPolicy -WorkloadType "AzureVM" | where {$_.Name -eq $BackupProtectionPolicy}

        if($policy -eq $null)
        {
            throw "Recovery Policy $BackupProtectionPolicy is not found in the Vault $RecoveryServicesVaultName"
        }

        Write-Host "Enabling Backup on the VM"
        Enable-AzureRmRecoveryServicesBackupProtection -Policy $policy -Name $virtualMachineName -ResourceGroupName $ResourceGroupName -ErrorAction Stop

        #Triggering a Backup
        Write-Host "Fetching the Recovery Services Backup Container"
        $namedContainer = Get-AzureRmRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName $virtualMachineName
        Write-Host "Fetching the Recovery Services Backup Item"
        $item = Get-AzureRmRecoveryServicesBackupItem -Container $namedContainer -WorkloadType "AzureVM"
        Write-Host "Triggering a Backup on the VM"
        $job = Backup-AzureRmRecoveryServicesBackupItem -Item $item

        Write-Host "Successfully Enabled the Backup on the VM $virtualMachineName"
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
                Enable-VMBackup -virtualMachineName $configSetting.Computer -ResourceGroupName $configSetting.ResourceGroupName -RecoveryServicesVaultName $configSetting.RecoveryServicesVaultName -BackupProtectionPolicy $configSetting.BackupProtectionPolicy
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