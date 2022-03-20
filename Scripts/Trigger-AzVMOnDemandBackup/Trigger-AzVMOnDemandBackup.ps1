#Validation - Check the field for "Recovery Point Expiry Time in UTC" in Backup Jobs

#Reference: https://docs.microsoft.com/en-us/powershell/module/az.recoveryservices/backup-azrecoveryservicesbackupitem?view=azps-7.1.0
#https://docs.microsoft.com/en-us/azure/backup/quick-backup-vm-powershell#start-a-backup-job
#https://docs.microsoft.com/en-us/azure/backup/powershell-backup-samples

#region INPUT VARIABLES
#region Environment Variables
$subscriptionName = "Your-Subscription-Name"
$vaultName = "Your-RecoveryServices-Vault-Name"
$rgOfVault = "RG-of-The-RecoveryServices-Vault"
#endregion

#Expiry of the on-demand VM backup
$dateTillExpiry = Get-Date -Month 12 -Day 18 -Year 2021 -Hour 0 -Minute 0 -Second 0

#Path of the Config File containing all VM Names for which to trigger the on-demand backup
$ConfigFilePath = "D:\DATA\Scripts\Start-AzureBackup\VMNames-Config.csv"

#endregion

#Setting the right context
$env = Get-AzEnvironment -Name "AzureCloud"
Connect-AzAccount -Environment $env
Set-AzContext -SubscriptionName $subscriptionName

#Internal custom funtion for checking if the file exists
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
	}
}

#Check if the config file with VM names exists or not
if(Test-FileExists -SourceFile $ConfigFilePath)
{
    try
    {
        #Importing the CSV File
        $configSettings = Import-Csv -Path $ConfigFilePath

        #Setting the Vault Context
        $vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgOfVault
        #Setting the Recovery Services Vault Context
        Set-AzRecoveryServicesVaultContext -Vault $vault
            
        #Iterating the CSV File
        foreach($configSetting in $configSettings)
        {
            #Getting VM Name from the CSV File
            $vmName = $configSetting.VMName

            #Getting the Backup Container
            $backupcontainer = Get-AzRecoveryServicesBackupContainer `
                -ContainerType "AzureVM" `
                -FriendlyName $vmName
            
            #Getting the Backup Item
            $item = Get-AzRecoveryServicesBackupItem `
                -Container $backupcontainer `
                -WorkloadType "AzureVM"
            
            #Triggering the Backups
            Backup-AzRecoveryServicesBackupItem -Item $item -ExpiryDateTimeUTC $dateTillExpiry
        }
            
    }
    catch [system.exception]
	{
		Write-Verbose "Error : $($_.Exception.Message) "
        Write-Host "Error : $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
	}
}
else
{
    Write-Host "Please check the confi file is available at the path specified in the inputs."
}
