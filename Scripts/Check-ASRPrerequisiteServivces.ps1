<# 

 
This will query the remote computers and check for service status for the 3 ASR Required services, and export to CSV
	
.EXAMPLE
    PS $ComputerName = Get-Content C:\Users\svc_azure_siterecovp\Downloads\servers.txt
    PS C:\>.\Check-ASRPrerequisiteServivces.ps1 | Export-Csv C:\Users\svc_azure_siterecovp\Downloads\CheckServicesReport.csv -NoTypeInformation
	
#>

foreach ($computer in $ComputerName) {
 
    $servicesToCheck = "MSDTC","VSS", "COMSysApp"
    
    $services = Get-Service -ComputerName $computer | Select Name, Status, StartType
    $IP_Config = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $computer
    $IP_Result = $IP_Config.DhcpEnabled

    $IP_Output = if ($IP_Result -eq 'True' ) {
    
        $IP_Props = @{ServerName=$computer;
                    Result="IP Set Incorectly"
                  }
                    New-Object -TypeName PSObject -Property $IP_Props
                  }
                  Else {
                  $IP_Output =
        $IP_Props = @{ServerName=$computer;
                    Result="IP Set Correctly"
                  }
                    New-Object -TypeName PSObject -Property $IP_Props
                  }

    $results = foreach ($service in $servicesToCheck) {
       

        $checkService = $services | Where{ $_.Name -eq $service}
        
        if (($checkService.status -eq 'running' ) -and ($checkservice.StartType -eq 'automatic')) {
            
            
         $props = @{ServerName=$computer;
                    Result="Set Correctly";
                    Service_Name=$service
                    
                    }
            New-Object -TypeName PSObject -Property $props 
        }
        else {
            
            $props = @{ServerName=$computer;
                    Result="Set Incorectly";
                    Service_Name=$service
                    }
            New-Object -TypeName PSObject -Property $props
        }
    }
    
    $results 
    $IP_Output
}

