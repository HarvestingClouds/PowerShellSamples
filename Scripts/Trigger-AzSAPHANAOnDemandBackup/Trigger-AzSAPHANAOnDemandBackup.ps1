#Validation - Check the field for "Recovery Point Expiry Time in UTC" in Backup Jobs
#Reference: https://docs.microsoft.com/en-us/azure/backup/tutorial-sap-hana-backup-cli#trigger-an-on-demand-backup

#region INPUT VARIABLES
$ConfigFilePath = "D:\DATA\Scripts\VMNames - DBs.csv"

#region Prod Variables
$subscriptionName = "Your-Subscription-Name"
$vaultName = "Your-RecoveryServices-Vault-Name"
$rgOfVault = "RG-of-The-RecoveryServices-Vault"
#endregion
#endregion


#Login
az login
# Set the Subscription Context
az account set --subscription $subscriptionName

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
        Set-AzRecoveryServicesVaultContext -Vault $vault
            
        #Iterating the CSV File
        foreach($configSetting in $configSettings)
        {
            #Setting values
            $vmName = $configSetting.VMName
            $instanceName = $configSetting.InstanceName
            $databasename = $configSetting.DatabaseName
            $VMResourceGroup = $configSetting.VMResourceGroup

            #setting item and container variables
            $itemName = "SAPHanaDatabase;$instanceName;$databaseName"
            $containerName = "VMAppContainer;Compute;$VMResourceGroup;$vmName"

            #Triggering the Backup
            #NOTE: This is the AZ CLI Command and not the PowerShell cmdlet, even though we are running it from the PowerShell console
            az backup protection backup-now --resource-group $rgOfVault --item-name $itemName --vault-name $vaultName --container-name $containerName --backup-type Full --output table
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
