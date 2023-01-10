param(
    [Parameter(Mandatory=$True)]
    [string]$appId_DEV,
    [Parameter(Mandatory=$True)]
    [string]$appSecret_DEV,
    [Parameter(Mandatory=$True)]
    [string]$tenantId_DEV
)

Install-module -name Msal.ps -AllowClobber -Force

Install-Module Microsoft.Graph -AllowClobber -Force



# Add environment variables to be used by Connect-MgGraph.
$authparams = @{
    ClientId    = $appId_DEV
    TenantId    = $tenantId_DEV
    ClientSecret = ($appSecret_DEV | ConvertTo-SecureString -AsPlainText -Force)
}
$auth = Get-MsalToken @authParams
$AccessToken = $auth.AccessToken

# Tell Connect-MgGraph to use your environment variables.
Connect-MgGraph -AccessToken $AccessToken


####################################################

Function Get-DeviceCompliancePolicy(){

<#
.SYNOPSIS
This function is used to get device compliance policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device compliance policies
.EXAMPLE
Get-DeviceCompliancePolicy
Returns any device compliance policies configured in Intune
.EXAMPLE
Get-DeviceCompliancePolicy -Android
Returns any device compliance policies for Android configured in Intune
.EXAMPLE
Get-DeviceCompliancePolicy -iOS
Returns any device compliance policies for iOS configured in Intune
.NOTES
NAME: Get-DeviceCompliancePolicy
#>

[cmdletbinding()]

param
(
    
    [switch]$Android,
    
    [switch]$iOS,
    
    [switch]$Win10
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/deviceCompliancePolicies"
    
try {

        $Count_Params = 0

        if($Android.IsPresent){ $Count_Params++ }
        if($iOS.IsPresent){ $Count_Params++ }
        if($Win10.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){
        
        write-host "Multiple parameters set, specify a single parameter -Android -iOS or -Win10 against the function" -f Red
        
        }
        
        elseif($Android){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-MgGraphRequest -uri $uri -Method GET).Value | Where-Object { ($_.'@odata.type').contains("android") }
        
        }
        
        elseif($iOS){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-MgGraphRequest -uri $uri -Method GET).Value | Where-Object { ($_.'@odata.type').contains("ios") }
        
        }

        elseif($Win10){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-MgGraphRequest -uri $uri -Method GET).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") }
        
        }
        
        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-MgGraphRequest -uri $uri -Method GET).Value

        }

    }

    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Export-JSONData(){

<#
.SYNOPSIS
This function is used to export JSON data returned from Graph
.DESCRIPTION
This function is used to export JSON data returned from Graph
.EXAMPLE
Export-JSONData -JSON $JSON
Export the JSON inputted on the function
.NOTES
NAME: Export-JSONData
#>

param (

$JSON,
$ExportPath

)

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON..." -f Red

        }

        else {

        $JSON1 = ConvertTo-Json $JSON -Depth 5

        $JSON_Convert = $JSON1 | ConvertFrom-Json

        $displayName = $JSON_Convert.displayName

        # Updating display name to follow file naming conventions - https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
        $DisplayName = $DisplayName -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"

        $Properties = ($JSON_Convert | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" }).Name

            $FileName_CSV = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".csv"
            $FileName_JSON = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json"

            $Object = New-Object System.Object

                foreach($Property in $Properties){

                $Object | Add-Member -MemberType NoteProperty -Name $Property -Value $JSON_Convert.$Property

                }

            write-host "Export Path:" "$ExportPath"

            $Object | Export-Csv -Path "$FileName_CSV" -NoTypeInformation -Append
            $JSON1 | Set-Content -Path "$FileName_JSON"
            
        }

    }

    catch {

    $_.Exception

    }

}



####################################################

$CPs = Get-DeviceCompliancePolicy

    foreach($CP in $CPs){

    
    Export-JSONData -JSON $CP -ExportPath "$ExportPath"
    

    }