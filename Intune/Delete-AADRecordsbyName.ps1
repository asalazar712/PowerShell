

#This Script uses the MSAL library and delegated permissions to delete recrords 


#Based on this script https://smsagent.blog/2020/03/17/delete-device-records-in-ad-aad-intune-autopilot-configmgr-with-powershell/

[CmdletBinding(DefaultParameterSetName='All')]
Param
(
    [Parameter(ParameterSetName='All',Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Individual',Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    $ComputerName,
    [Parameter(ParameterSetName='All',Mandatory=$true)]
    [Parameter(ParameterSetName='Individual',Mandatory=$true)]
    [string]$tenantid,
    [Parameter(ParameterSetName='All')]
    [switch]$All = $True,
    [Parameter(ParameterSetName='Individual')]
    [switch]$AAD,
    [Parameter(ParameterSetName='Individual')]
    [switch]$Intune,
    [Parameter(ParameterSetName='Individual')]
    [switch]$Autopilot
)

Set-Location $env:SystemDrive


 

# Load required modules
If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot")  -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Importing modules..." -NoNewline
        If ($PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("All"))
        {
            Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
        }
        If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("All"))
        {
            Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
        }
        If ($PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
        {
            Import-Module Microsoft.Graph.DeviceManagement.Enrolment -ErrorAction Stop
        }
       
        Write-host "Success" -ForegroundColor Green 
    }
    Catch
    {
        Write-host "$($_.Exception.Message)" -ForegroundColor Red
        Return
    }
}

# Authenticate with Azure
If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-Host "Authenticating with MG Graph and Azure AD..." -NoNewline
        
        $ScopePermissions = @(
            "DeviceManagementManagedDevices.ReadWrite.All"
            "DeviceManagementServiceConfig.ReadWrite.All"
            "Device.Read.All"
            "Directory.ReadWrite.All"
            "Directory.AccessAsUser.All"
        )
                  
            
        Connect-MGGraph -TenantId $tenantid -Scopes $ScopePermissions
         
        Select-MgProfile -Name beta
        Write-host "Success" -ForegroundColor Green
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        Write-host "$($_.Exception.Message)" -ForegroundColor Red
        Return
    }
}

Write-host "$($ComputerName.ToUpper())" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow




# Delete from Azure AD
If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Retrieving " -NoNewline
        Write-host "Azure AD " -ForegroundColor Yellow -NoNewline
        Write-host "device record/s..." -NoNewline 
        [array]$AzureADDevices = get-mgdevice -Filter "DisplayName eq '$ComputerName'"  -ErrorAction Stop
        
        
        If ($AzureADDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            Foreach ($AzureADDevice in $AzureADDevices)
            {
                Write-host "   Deleting DisplayName: $($AzureADDevice.DisplayName)  |  AADDeviceId: $($AzureADDevice.DeviceId)  |  ObjectID: $($AzureADDevice.Id) ..." -NoNewline
                Remove-MgDevice -DeviceId $AzureADDevice.Id -ErrorAction Stop 
                Write-host "Success" -ForegroundColor Green
            }      
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        $_
    }
}

# Delete from Intune
If ($PSBoundParameters.ContainsKey("Intune")  -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Retrieving " -NoNewline
        Write-host "Intune " -ForegroundColor Yellow -NoNewline
        Write-host "managed device record/s..." -NoNewline
        [array]$IntuneDevices = Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$ComputerName'" -ErrorAction Stop
        If ($IntuneDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            If ($PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("All"))
            {
                foreach ($IntuneDevice in $IntuneDevices)
                {
                    Write-host "   Deleting DeviceName: $($IntuneDevice.DeviceName)  |  Id: $($IntuneDevice.Id)  |  AzureADDeviceId: $($IntuneDevice.azureADDeviceId)  |  SerialNumber: $($IntuneDevice.serialNumber) ..." -NoNewline
                    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDevice.ID -Verbose -ErrorAction Stop 
                    Write-host "Success" -ForegroundColor Green
                }
            }
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        $_
    }
}

# Delete Autopilot device
If ($PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
{
    If ($IntuneDevices.Count -ge 1)
    {
        Try
        {
            Write-host "Retrieving " -NoNewline
            Write-host "Autopilot " -ForegroundColor Yellow -NoNewline
            Write-host "device registration..." -NoNewline
            #Creating an Array
            $AutopilotDevices = New-Object System.Collections.ArrayList
            foreach ($IntuneDevice in $IntuneDevices)
            {
                
                $AutopilotDevice = Get-MgDeviceManagementWindowAutopilotDeviceIdentity | where {$_.SerialNumber -eq $IntuneDevice.SerialNumber}
                [void]$AutopilotDevices.Add($AutopilotDevice)
            }
            Write-Host "Success" -ForegroundColor Green

            foreach ($device in $AutopilotDevices)
            {
                Write-host "   Deleting SerialNumber: $($Device.serialNumber)  |  Model: $($Device.model)  |  Id: $($Device.id)  |  GroupTag: $($Device.groupTag)  |  ManagedDeviceId: $($device.managedDeviceId) ..." -NoNewline
                Remove-MgDeviceManagementWindowAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Device.Id 
                Write-Host "Success" -ForegroundColor Green
            }
        }
        Catch
        {
            Write-host "Error!" -ForegroundColor Red
            $_
        }
    }
}


Set-Location $env:SystemDrive




