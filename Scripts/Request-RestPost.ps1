#Reference: http://blogs.technet.com/b/scorch/archive/2011/05/25/getting-ready-for-orchestrator-2012-accessing-rest-web-services-using-powershell.aspx

function Request-Rest{    
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$False)]
        [String]$RequestBody,
        
        [Parameter(Mandatory=$true)]
        [String] $URL,

        [Parameter(Mandatory=$False)]
        [Switch]$listUpdate,

        [Parameter(Mandatory=$False)]
        [String]$RequestDigest,
    
        [Parameter(Mandatory=$false)]
        [System.Net.NetworkCredential] $credentials,
                
        [Parameter(Mandatory=$false)]
        [String] $UserAgent = "PowerShell API Client",
        
        [Parameter(Mandatory=$false)]
        [Switch] $JSON,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Raw
    )
    #Create a URI instance since the HttpWebRequest.Create Method will escape the URL by default.   
    #$URL = Fix-Url $Url
    $URI = New-Object System.Uri($URL,$true)   

    #Create a request object using the URI   
    $request = [System.Net.HttpWebRequest]::Create($URI)   
    
    #Build up a nice User Agent   
    $request.UserAgent = $(   
        "{0} (PowerShell {1}; .NET CLR {2}; {3})" -f $UserAgent, $(if($Host.Version){$Host.Version}else{"1.0"}),  
        [Environment]::Version,  
        [Environment]::OSVersion.ToString().Replace("Microsoft Windows ", "Win")  
        )

    if ($credentials -eq $null)
    {
        $request.UseDefaultCredentials = $true
    }
    else
    {
        $request.Credentials = $credentials
    }

    $request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")

    #Request Method
    $request.Method = "POST"

    #Headers
    if($listUpdate)
    {
        $request.Headers.Add("X-RequestDigest", $RequestDigest)
        $request.Headers.Add("If-Match", "*")
        $request.Headers.Add("X-HTTP-Method", "MERGE")
            
        $request.ContentType = "application/json;odata=verbose"
        $request.Accept = "application/json;odata=verbose"
    }

    #Request Body
    if($RequestBody) {  
        $Body = [byte[]][char[]]$RequestBody   
        $request.ContentLength = $Body.Length 

        $stream = $request.GetRequestStream()
        $stream.Write($Body, 0, $Body.Length)
    }
    else {
        $request.ContentLength = 0
    }


    try
    {
        [System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()
    }
    catch
    {
            Throw "Exception occurred in $($MyInvocation.MyCommand): `n$($_.Exception.Message)"
    }
    
    $reader = [IO.StreamReader] $response.GetResponseStream()  

    if (($PSBoundParameters.ContainsKey('JSON')) -or ($PSBoundParameters.ContainsKey('Raw')))
    {
        $output = $reader.ReadToEnd()  
    }
    else
    {
        $output = $reader.ReadToEnd()  
    }
    
    $reader.Close()  

    if($output.StartsWith("<?xml"))
    {
        [xml]$outputXML = [xml]$output
    }
    else
    {
        [xml]$outputXML = [xml] ("<xml>" + $output + "</xml>")
    }

    Write-Output $outputXML 

    $response.Close()
}