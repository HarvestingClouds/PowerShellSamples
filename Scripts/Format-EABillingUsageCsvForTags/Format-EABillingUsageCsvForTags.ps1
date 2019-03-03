<# 	
 .NOTES
	==============================================================================================
	Copyright (c) Microsoft Corporation.  All rights reserved.   
	
	File:		Format-EABillingUsageCsvForTags.ps1
	
	Purpose:	To parse and format the Billing Usage CSV and split the Tags as per the standards
					
	Version: 	1.0.0.0 

	Author:	    Aman Sharma
 	==============================================================================================
 .SYNOPSIS
	Azure Resources Billing Usage Report Formatting Script as per Tags
  
 .DESCRIPTION
	This script is used to parse and format the Billing Usage CSV and split the Tags as per the standards. 
		
 .EXAMPLE
	C:\PS>  .\Format-EABillingUsageCsvForTags.ps1 -PathOfInputBillingUsageCsv "Your-Usage-File-Path-Here"  
	
	Description
	-----------
	This script is used to parse and format the Billing Usage CSV and split the Tags as per the standards. 
     
 .PARAMETER PathOfInputBillingUsageCsv
    This is the path to the Billing Usage Csv that we want to format as per Tags. 
 
 .INPUTS
    None.

 .OUTPUTS
    None.
		   
 .LINK
	None.
#>

#Path variable to the CSV file
$PathOfInputBillingUsageCsv = "C:\FullPath\Sample Input - EA Azure Billing CSV.csv"

$dateTime = Get-Date -Format "yyyy-MM-dd-hh-mm"
$PathToOutputCSVReport = "C:\FullPath\UsageWithTags-"+ $dateTime +".csv"

if(Test-Path $PathOfInputBillingUsageCsv)
{
    #Iterating the CSV file
    Import-CSV -Path $PathOfInputBillingUsageCsv |
    ForEach-Object {
        #Parsing values from the CSV file
        $tags = $null
        $tags = $_.Tags

        
        #Declaring variables for Tags
        #TODO 1 - Change these to the actual tags in your environment
        $ApplicationOwner = ""
        $ApplicationType = ""
        $BusinessUnit = ""
        $Department = ""
        
        #region Parsing Tags

        if(($tags -ne $null) -and ($tags -ne ""))
        {
            #Converting tags to PowerShell variable
            $psTags = $null
            #TODO 2 - Change these to the actual tags in your environment
            $tags1 = $tags.Replace("ApplicationOwner","ApplicationOwner1").Replace("ApplicationType","ApplicationType1").Replace("Department","Department1").Replace("BusinessUnit","BusinessUnit1")

            $psTags = ConvertFrom-Json $tags1

            #TODO 3 - Change these to the actual tags in your environment
            if($tags1.Contains("ApplicationOwner1"))
            {
                $ApplicationOwner = $psTags.ApplicationOwner1
            }
            if($tags1.Contains("Application Owner"))
            {
                $ApplicationOwner = $psTags."Application Owner"
            }
            if($tags1.Contains("ApplicationType1"))
            {
                $ApplicationType = $psTags.ApplicationType1
            }
            if($tags1.Contains("Application Type"))
            {
                $ApplicationType = $psTags."Application Type"
            }
            if($tags1.Contains("BusinessUnit1"))
            {
                $BusinessUnit = $psTags.BusinessUnit1
            }
            if($tags1.Contains("Business Unit"))
            {
                $BusinessUnit = $psTags."Business Unit"
            }
            if($tags1.Contains("Department1"))
            {
                $Department = $psTags.Department1
            }
        }
        #endregion

        #TODO 4 - Change these to the actual tags in your environment
        $_ | 
      Add-Member -MemberType NoteProperty -Name ApplicationOwner -Value $ApplicationOwner -PassThru |
      Add-Member -MemberType NoteProperty -Name ApplicationType -Value $ApplicationType -PassThru |
      Add-Member -MemberType NoteProperty -Name BusinessUnit -Value $BusinessUnit -PassThru |
      Add-Member -MemberType NoteProperty -Name Department -Value $Department -PassThru 

    } |
    Export-CSV $PathToOutputCSVReport -NoTypeInformation -ErrorAction Stop

    Write-Host "Generated the new CSV file. The file with complete path is: $PathToOutputCSVReport" -ForegroundColor Green
}
else
{
    Write-Host "Error - File not found at the path:" -ForegroundColor Red
    Write-Host $PathOfInputBillingUsageCsv
}