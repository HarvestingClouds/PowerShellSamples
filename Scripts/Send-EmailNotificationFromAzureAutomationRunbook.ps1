  Param
  (
    [Parameter (Mandatory = $true)]
    [string] $SMTPServerUrl,

    [Parameter (Mandatory = $true)]
    [Int32] $SMTPServerPort,

    [Parameter (Mandatory = $true)]
    [Boolean] $UseCredentials,
    
    [Parameter (Mandatory = $false)]
    [string] $CredentialName,

    [Parameter (Mandatory = $true)]
    [Boolean] $EnableSsl,
    
    [Parameter (Mandatory = $true)]
    [string] $EmailFrom,
    
    [Parameter (Mandatory = $true)]
    [string] $EmailTo,

    [Parameter (Mandatory = $true)]
    [string] $EmailSubject,

    [Parameter (Mandatory = $true)]
    [string] $MessageBody

  )
 
 try
 {
    if($UseCredentials -eq $true)
    {
        # RetrieveOffice 365 credential from Azure Automation Credentials
        $O365Credential = Get-AutomationPSCredential -Name $CredentialName  
    }
     
    # Create new MailMessage
    $Message = New-Object System.Net.Mail.MailMessage
        
    # Set address-properties    
    $Message.From = $EmailFrom
    $Message.replyTo = $EmailFrom
    $Message.To.Add($EmailTo)

    # Set email subject
    $Message.SubjectEncoding = ([System.Text.Encoding]::UTF8)
    $Message.Subject = $EmailSubject
        
    # Set email body
    $Message.Body = $MessageBody
    $Message.BodyEncoding = ([System.Text.Encoding]::UTF8)
    $Message.IsBodyHtml = $true
        
    # Create and set SMTP
    $SmtpClient = New-Object System.Net.Mail.SmtpClient $SMTPServerUrl, $SMTPServerPort

    if($UseCredentials -eq $true)
    {
        $SmtpClient.Credentials = $O365Credential
    }

    if($EnableSsl -eq $true)
    {
        $SmtpClient.EnableSsl   = $true    
    }

    # Send email message
    $SmtpClient.Send($Message)

    Write-Output "Email(s) Sent"
 }
catch
{
    $ErrorMessage = $_.Exception.Message;
    Write-Verbose $ErrorMessage
    Write-Error -Message $_.Exception
}
