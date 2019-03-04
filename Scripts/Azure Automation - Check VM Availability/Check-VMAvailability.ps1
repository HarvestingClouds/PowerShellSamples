param (
        [parameter(Mandatory=$true)]
        [String]$NameOfTheVM,
        [parameter(Mandatory=$true)]
        [String]$IPOfVM
      )

#TESTING
#[String] $VMName = "cwv-webes8d-test"
#[String] $VMIP = "10.21.40.206"
#TESTING

$HKLM = [UInt32] "0x80000002"
$MachineKey = "SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

[String] $VMName = $NameOfTheVM
[String] $VMIP = $IPOfVM

Write-Verbose "VMName               : $VMName"
Write-Verbose "VMIP                 : $VMIP"

[String] $ErrorsFound = "0"
[String] $ErrorDetails = ""
[Boolean] $ResultAction = $false

$Cred = Get-AutomationPSCredential -Name 'ASRServiceAccount'

#PING CHECK
Write-Verbose "Check if VM is accessible by Ping"
$PingResults = Test-Connection $VMIP -Quiet -ErrorAction SilentlyContinue -ErrorVariable PingError

if($PingResults -eq $true)
{
    #SUCCESS
    Write-Verbose "VM with IP $VMIP is accessible by Ping"
    $PingCheck = $true
    $PingCheckStatus = "Succeed"

    #PS SESSION CHECK
    Write-Verbose "Check if VM $VMName is accessible by PS Session"
    $PSession = New-PSSession -ComputerName $VMName -Credential $Cred -ErrorAction SilentlyContinue -ErrorVariable SessionError

    if($PSession -ne $null)
    {
        #SUCCESS
        Write-Verbose "VM $VMName is accessible by PS Session"
        $PSSessionCheck = $true
        $PSSessionStatus = "Succeed"

        Remove-PSSession -Session $PSession

        #Remote WMI CHECK        
        Write-Verbose "Checking if VM with IP $VMIP is accessible by remote WMI registry"
        $wmi = Get-Wmiobject -list "StdRegProv" -namespace root\default -Computername $VMIP -Credential $Cred -ErrorAction SilentlyContinue -ErrorVariable ErrorWMI

        if($wmi -ne $null)
        {
            #SUCCESS
            Write-Verbose "VM with IP $VMIP is accessible by remote WMI registry"
            $ConnectedToWMI = $true
            $WMIConnectionStatus = "Succeed"
            Write-Verbose "Checking if VM $VMName is accessible by WinRM Connectivity"

            $WinRm = Test-WSMan -ComputerName $VMName -ErrorAction SilentlyContinue -ErrorVariable WinRMError

            if($WinRm -ne $null)
            {
                #SUCCESS
                $ConnectedToWinRM = $true
                $WinRMConnectionStatus = "Succeed"
                Write-Verbose "VM $VMName is accessible by WinRM Connectivity"

                Write-Verbose "Get FQDN from VM"
                $Domain = $wmi.GetStringValue($HKLM, $MachineKey, "NV Domain").sValue
                $FQDN = "$VMName.$Domain"
                Write-Verbose "FQDN from VM: $FQDN" 
            }
            else
            {
                #ERROR
                Write-Verbose "VM $VMName is Not accessible by WinRM Connectivity"
                
                $ConnectedToWinRM = $false
                $WinRMConnectionStatus = "Failed"
                
                $ErrorDetails = "VM $VMName is Not accessible by WinRM Connectivity"
                $ErrorsFound = "1"
                Write-Verbose "Errors: $ErrorDetails" 

                if($WinRMError.Count -gt 0)
                {
                    $ErrorDetails = $WinRMError[0].Exception.Message
                    Write-Verbose "Error while connecting to VM WinRM Provider Additinal Errors: $ErrorDetails"        
                }
            }
        }
        else
        {
            #ERROR
            Write-Verbose "VM with IP $VMIP is Not accessible by remote WMI registry"

            $ConnectedToWMI = $false
            $ConnectedToWinRM = $false
            $WMIConnectionStatus = "Failed"
            $WinRMConnectionStatus = "Failed"

            $ErrorDetails = "VM with IP $VMIP is Not accessible by remote WMI registry"
            $ErrorsFound = "1"
            Write-Verbose "Errors: $ErrorDetails" 
            
            if($ErrorWMI.Count -gt 0)
            {
                $ErrorDetails = $ErrorWMI[0].Exception.Message
                Write-Verbose "Error while connecting to VM WMI Provider Additinal Errors: $ErrorDetails"        
            }
        }

    }
    else
    {
        #ERROR
        Write-Verbose "VM $VMName is Not accessible by PS Session"

        $PSSessionCheck = $false
        $ConnectedToWMI = $false
        $ConnectedToWinRM = $false

        $PSSessionStatus = "Failed"
        $WMIConnectionStatus = "Failed"
        $WinRMConnectionStatus = "Failed"

        $ErrorDetails = "VM $VMName is Not accessible by PS Session"
        $ErrorsFound = "1"
        Write-Verbose "Errors: $ErrorDetails" 

        if($SessionError.Count -gt 0)
        {
            $ErrorDetails = $SessionError[0].Exception.Message
            Write-Verbose "Error while Check if VM $VMName is accessible by PS Session Additinal Errors: $ErrorDetails"        
        }
    }
}
else
{
    #ERROR
    Write-Verbose "VM with IP $VMIP is Not accessible by Ping"

    $PingCheck = $false
    $PSSessionCheck = $false
    $ConnectedToWMI = $false
    $ConnectedToWinRM = $false

    $PingCheckStatus = "Failed"
    $PSSessionStatus = "Failed"
    $WMIConnectionStatus = "Failed"
    $WinRMConnectionStatus = "Failed"
    $ErrorsFound = "1"
    $ErrorDetails = "VM with IP $VMIP is Not accessible by Ping"
    Write-Verbose "Errors: $ErrorDetails"

    if($PingError.Count -gt 0)
    {
        $ErrorDetails = $PingError[0].Exception.Message
        Write-Verbose "Error while Check if VM is accessible by Ping Additinal Errors: $ErrorDetails"        
    }
}

Write-Verbose "Creating Return Object with Results"

$RetunrObjItm = new-object PSObject
$RetunrObjItm | add-member NoteProperty "VMName" -value $VMName
$RetunrObjItm | add-member NoteProperty "VMIP" -value $VMIP
$RetunrObjItm | add-member NoteProperty "VMFQDN" -value $FQDN
$RetunrObjItm | add-member NoteProperty "PingCheckStatus" -value $PingCheckStatus
$RetunrObjItm | add-member NoteProperty "PSSessionStatus" -value $PSSessionStatus
$RetunrObjItm | add-member NoteProperty "WMIConnectionStatus" -value $WMIConnectionStatus
$RetunrObjItm | add-member NoteProperty "WinRMConnectionStatus" -value $WinRMConnectionStatus
$RetunrObjItm | add-member NoteProperty "ErrorsFound" -value $ErrorsFound
$RetunrObjItm | add-member NoteProperty "ErrorDetails" -value $ErrorDetails

Write-Verbose "RetunrObjItm : $RetunrObjItm"

Write-Output $RetunrObjItm