#The below line will prompt for your credentials to login into Azure
Add-AzAccount

#Selecting the subscription if you have more than one subscriptions in your Azure account
$context = Get-AzSubscription -SubscriptionId "1aa1aaa1-111-11a1-1a1e-bdf5f12e61db"
Set-AzContext $context

$StorageAccountName = "armtemplatesrepo"
$ResourceGroupNameOfStorage = "ARMTemplatesRG"
$ContainerName = "armtemplatesblob"

#Set the Context in one of the 3 ways as per your security requirements
#Ref: - https://azure.microsoft.com/en-us/documentation/articles/storage-powershell-guide-full/
$StorageAccountKey = Get-AzStorageAccountKey -AccountName $StorageAccountName -ResourceGroupName $ResourceGroupNameOfStorage
$Ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey[0].Value


#Uploading File
$BlobName = "Parameters.json"
$localFile = "D:\Local\" + $BlobName

#Note the Force switch will overwrite if the file already exists in the Azure container
Set-AzStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $Ctx -Force


#Download File
$BlobName = "Parameters.json"
$localTargetDirectory = "D:\DownloadedFile"

Get-AzStorageBlobContent -Blob $BlobName -Container $ContainerName -Destination $localTargetDirectory -Context $ctx
