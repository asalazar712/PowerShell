
<#
Demo Script DO NOT USE IN PRODUCTION
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

Install-Module Microsoft.Graph -AllowPrerelease -AllowClobber -Force

param(
    [Parameter(Mandatory=$True)]
    [string]$appId_DEV,
    [Parameter(Mandatory=$True)]
    [string]$appSecret_DEV,
    [Parameter(Mandatory=$True)]
    [string]$tenantId_DEV
)

# Add environment variables to be used by Connect-MgGraph.
$Env:AZURE_CLIENT_ID = $appId_DEV #application id of the client app
$Env:AZURE_TENANT_ID = $tenantId_DEV #Id of your tenant
$Env:AZURE_CLIENT_SECRET = $appSecret_DEV #secret of the client app

# Tell Connect-MgGraph to use your environment variables.
Connect-MgGraph -EnvironmentVariable​


####################################################

Function Test-JSON(){

<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-JSON
#>

param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
    break

    }

}

####################################################

Function Add-DeviceCompliancePolicy(){

<#
.SYNOPSIS
This function is used to add a device compliance policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device compliance policy
.EXAMPLE
Add-DeviceCompliancePolicy -JSON $JSON
Adds an Android device compliance policy in Intune
.NOTES
NAME: Add-DeviceCompliancePolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "v1.0"
$Resource = "deviceManagement/deviceCompliancePolicies"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON


        }

    }

    catch {

    Write-Host
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

#region Authentication

####################################################

$JSON_Android = @"

    {
    "passwordExpirationDays": null,
    "requireAppVerify":  true,
    "securityPreventInstallAppsFromUnknownSources":  true,
    "@odata.type":  "microsoft.graph.androidCompliancePolicy",
    "scheduledActionsForRule":[{"ruleName":"PasswordRequired","scheduledActionConfigurations":[{"actionType":"block","gracePeriodHours":0,"notificationTemplateId":""}]}],
    "passwordRequiredType":  "numeric",
    "storageRequireEncryption":  true,
    "storageRequireRemovableStorageEncryption":  true,
    "passwordMinutesOfInactivityBeforeLock":  15,
    "passwordPreviousPasswordBlockCount":  null,
    "passwordRequired":  true,
    "description":  "Android Compliance Policy",
    "passwordMinimumLength":  4,
    "displayName":  "Android Compliance Policy",
    "securityBlockJailbrokenDevices":  true,
    "deviceThreatProtectionRequiredSecurityLevel":  "low",
    "deviceThreatProtectionEnabled":  true,
    "securityDisableUsbDebugging":  true
    }

"@

####################################################

$JSON_iOS = @"

  {
  "@odata.type": "microsoft.graph.iosCompliancePolicy",
  "description": "iOS Compliance Policy",
  "displayName": "iOS Compliance Policy",
  "scheduledActionsForRule":[{"ruleName":"PasswordRequired","scheduledActionConfigurations":[{"actionType":"block","gracePeriodHours":0,"notificationTemplateId":""}]}],
  "passcodeBlockSimple": true,
  "passcodeExpirationDays": null,
  "passcodeMinimumLength": 4,
  "passcodeMinutesOfInactivityBeforeLock": 15,
  "passcodePreviousPasscodeBlockCount": null,
  "passcodeMinimumCharacterSetCount": null,
  "passcodeRequiredType": "numeric",
  "passcodeRequired": true,
  "securityBlockJailbrokenDevices": true,
  "deviceThreatProtectionEnabled": true,
  "deviceThreatProtectionRequiredSecurityLevel": "low"
  }

"@

####################################################

Write-Host "Adding Android Compliance Policy from JSON..." -ForegroundColor Yellow

Add-DeviceCompliancePolicy -JSON $JSON_Android

Write-Host "Adding iOS Compliance Policy from JSON..." -ForegroundColor Yellow
Write-Host

Add-DeviceCompliancePolicy -JSON $JSON_iOS