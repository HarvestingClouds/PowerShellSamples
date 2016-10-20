#Uncomment the below line
Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionId "1aa1aaa1-111-11a1-1a1e-bdf5f12e61db"
#Select-AzureRmSubscription -SubscriptionId "1ea2dfe3-5183-44a3-8e8e-bdf5f12e61db"

$StorageAccountName = "armtemplatesrepo"
$ResourceGroupNameOfStorage = "ARMTemplatesRG"
$ContainerName = "armtemplatesblob"

#Set the Context in one of the 3 ways as per your security requirements
#Ref: - https://azure.microsoft.com/en-us/documentation/articles/storage-powershell-guide-full/
$StorageAccountKey = Get-AzureRmStorageAccountKey -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupNameOfStorage
$Ctx = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey[0].Value


#Uploading File
$BlobName = "Parameters.json"
$localFile = "D:\Local\" + $BlobName

#Note the Force switch will overwrite if the file already exists in the Azure container
Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $Ctx -Force


#Download File
$BlobName = "Parameters.json"
$localTargetDirectory = "D:\DownloadedFile"

Get-AzureStorageBlobContent -Blob $BlobName -Container $ContainerName -Destination $localTargetDirectory -Context $ctx