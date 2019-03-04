#region - Script Functions
<#
 ==============================================================================================	 
	Script Functions
		Get-IsElevated					- Checks if the script is in an elevated PS session
 ==============================================================================================	
#>
function Get-IsElevated
{
	# Get the ID and security principal of the current user account
	$WindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($WindowsID)
	
	# Get the security principal for the Administrator role
	$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	
	# Check to see if currently running "as Administrator"
	if ($WindowsPrincipal.IsInRole($adminRole))
	{
		return $True
	}
	else
	{
		return $False
	}
}

#endregion

#region - Script Control Routine
Start-Transcript $ScriptLog
Write-Verbose "======================================================================"
Write-Verbose "Script Started."

if(Get-IsElevated)
{
    try
    {
        # Insert code for elevated execution
		(Get-Host).UI.RawUI.WindowTitle = "$env:USERDOMAIN\$env:USERNAME (Elevated)"
		Write-Verbose "Script is running in an elevated PowerShell host. "

        
        #TODO - The Main Code will come here
    }
    catch [system.exception]
	{
		Write-Verbose "Script Error: $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
		Stop-Transcript

		Exit
	}
}
else
{
	# Insert code for non-elevated execution
	(Get-Host).UI.RawUI.WindowTitle = "$env:USERDOMAIN\$env:USERNAME (Not Elevated)"
	Write-Verbose "Please start the script from an elevated PowerShell host. "
	Stop-Transcript
	Exit
}
Write-Verbose "Script Completed. "
Write-Verbose "======================================================================"
Stop-Transcript
#endregion