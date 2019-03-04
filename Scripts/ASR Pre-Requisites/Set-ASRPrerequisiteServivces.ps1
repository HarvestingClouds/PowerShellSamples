<# 

 
This will query the remote computers and check for service status for the 3 ASR Required services, and export to CSV
	
.EXAMPLE
    PS $ComputerName = Get-Content C:\Users\svc_azure_siterecovp\Downloads\servers.txt
    PS C:\>.\set-Servivces.ps1 | Export-Csv C:\Users\svc_azure_siterecovp\Downloads\SetServicesReport.csv -NoTypeInformation
	
#>

foreach ($computer in $ComputerName) {
 
    $servicesToCheck = "MSDTC","VSS","COMSysApp"
    
    $services = Get-Service -ComputerName $computer | Select Name, Status, StartType
    
    $results = foreach ($service in $servicesToCheck) {
       
        $checkService = $services | Where{ $_.Name -eq $service}
        
        if (($checkService.status -eq 'running' ) -and ($checkservice.StartType -eq 'automatic')) {
         
         $props = @{ServerName=$computer;
                    Result="Set Correctly";
                    Service_Name=$service
                    }
            New-Object -TypeName PSObject -Property $props 
        }
        else{
           $service1 = Get-Service -Name 'msdtc' -ComputerName $computer
           $service2 = Get-Service -Name 'VSS' -ComputerName $computer
           $service3 = Get-Service -Name 'COMSysApp' -ComputerName $computer
                if (($Service1.status -eq 'running' ) -and ($service1.StartType -eq 'automatic')){
                        }
                            else {
                                Set-Service -name 'msdtc' -ComputerName $Computer -StartupType Automatic
                                Start-Sleep -s 5
                                Get-Service -Name 'msdtc' -ComputerName $computer| Start-Service
                   
                                }
                if (($Service2.status -eq 'running' ) -and ($service2.StartType -eq 'automatic')){
                        }
                            else {
                                Set-Service -name 'VSS' -ComputerName $Computer -StartupType Automatic
                                Start-Sleep -s 5
                                Get-Service -Name 'VSS' -ComputerName $computer| Start-Service
                                 }
                if (($Service3.status -eq 'running' ) -and ($service3.StartType -eq 'automatic')){
                        }
                            else {
                                Set-Service -name 'COMSysApp' -ComputerName $Computer -StartupType Automatic
                                Start-Sleep -s 5
                                Get-Service -Name 'COMSysApp' -ComputerName $computer| Start-Service
                                 }
                       
            $props = @{ServerName=$computer;
                    Result="Service Now Set Correctly";
                    Service_Name=$service
                    } 
                    New-Object -TypeName PSObject -Property $props                   
               }       
        }
    
    $results 
}

