
$storageAccountName = "sttemp01"
$storageAccountKey = "d7fXPAIwn1pHemTEN8RBYGXvIyUiH+JQNppwigY6dUsfQHAWglPjryvKkkEGPoHriHwc+iIjxNBoMjW3hoaOjQ=="
$absoluteUri = "https://md-w3r4xdkvmmth.blob.core.windows.net/pvk0bggcjrnh/abcd?sv=2017-04-17&sr=b&si=b33474f4-9711-4d0f-8e35-c9f4512738d7&sig=sNJjIrMKZxGS4rDhbk6LsbKyE%2FNXla834cV9GH5hsYc%3D"
$destContainer = "vhds"
$blobName = "E2vwa-grcp1d-osdisk.vhd"

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