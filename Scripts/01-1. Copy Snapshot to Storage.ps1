
$storageAccountName = "sttemp01"
$storageAccountKey = "YourKey"
$absoluteUri = "https://StorageAccountName.blob.core.windows.net/ContainerName/abcd?sv=2017-04-17&sr=b&si=b33474f4-9711-4d0f-8e35-c9f4512738d7&sig=signature"
$destContainer = "vhds"
$blobName = "VMName-osdisk.vhd"

$destContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$targetBlob = Start-AzureStorageBlobCopy -AbsoluteUri $absoluteUri -DestContainer $destContainer -DestContext $destContext -DestBlob $blobName

$targetBlob = Get-AzureStorageBlob -Blob $blobName -Container $destContainer -Context $destContext

$copyState = $targetBlob | Get-AzureStorageBlobCopyState

        while ($copyState.Status -ne "Success")
        {
            $percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100
            Write-Host "Completed $('{0:N2}' -f $percent)%"
            sleep -Seconds 20
            $copyState = $targetBlob | Get-AzureStorageBlobCopyState
        }