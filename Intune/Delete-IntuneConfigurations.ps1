
install-module -name Microsoft.Graph.Devices.CorporateManagement #Permissions DeviceManagementApps.ReadWrite.All
install-module -name Microsoft.Graph.DeviceManagement.Enrolment
install-module -name Microsoft.Graph.DeviceManagement

$permissions = find-mggraphCommand -command Get-MgDeviceManagementConfigurationPolicy | select -first 2 -ExpandProperty Permissions
connect-mggraph -TenantId stratustechconsulting.com -Scopes $permissions.name
Get-MgDeviceManagementConfigurationPolicy


# Valid Query 
#Get-MgDeviceManagementConfigurationPolicy -Top 100 -Filter "(platforms eq 'windows10')" | select name
# Get-MgDeviceManagementConfigurationPolicy -Top 100 -Filter "(platforms eq 'windows10' or platforms eq 'macOS' or platforms eq 'iOS') and (technologies eq 'mdm' or technologies eq 'windows10XManagement' or technologies eq 'appleRemoteManagement' or technologies eq 'mdm,appleRemoteManagement') and (templateReference/templateFamily eq 'none')" | select name
#  Get-MgDeviceManagementDeviceConfiguration -Filter "(displayname eq 'Prod_Win_Custom_Chrome')" | select *

#Deletes all App Configuration Policies
$AppConfiguration = Get-MgDeviceAppMgtTargetedManagedAppConfiguration

foreach ($ACP in $AppConfiguration){
    $id = $ACP.Id
    write-host $ACP.DisplayName
    Remove-MgDeviceAppMgtTargetedManagedAppConfiguration -TargetedManagedAppConfigurationId $id
}

#Deletes all App Protection Policies
$AppProtection = Get-MgDeviceAppMgtManagedAppPolicy

foreach ($APP in $AppProtection){
    $id = $APP.Id
    write-host $APP.DisplayName
    Remove-MgDeviceAppMgtTargetedManagedAppConfiguration -TargetedManagedAppConfigurationId $id
}

#Delete all Assignment Filters 
$AssignmentFilters = Get-MgDeviceManagementAssignmentFilter

foreach ($filter in $AssignmentFilters){
    $id = $filter.Id
    Write-Host $filter.DisplayName
    Remove-MgDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $filter.id 
}


#Delete all Application
$Applications = Get-MgDeviceAppMgtMobileApp -Filter "(microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true)"  

foreach ($app in $Applications) {
    $id = $app.Id
    write-host $app.displayname
    remove-mgdeviceappmgtmobileapp -MobileAppId $id
}

#Delete all Autopilot profiles
#Permissions DeviceManagementServiceConfig.Read.All,  DeviceManagementServiceConfig.ReadWrite.All
# Deletion Might fail with assignments 
$AutoPilot = Get-MgDeviceManagementWindowAutopilotDeploymentProfile

foreach($AP in $AutoPilot){
    $id = $AP.id
    Write-host $AP.displayname
    Remove-MgDeviceManagementWindowAutopilotDeploymentProfile -WindowsAutopilotDeploymentProfileId $id
}

#Delete all Compliance policies
$CompliancePolicy = Get-MgDeviceManagementDeviceCompliancePolicy

foreach ($policy in $CompliancePolicy){
    $id = $policy.Id
    write-host $policy.displayname
    Remove-MgDeviceManagementDeviceCompliancePolicy -DeviceCompliancePolicyId $id
}

#Get created Settings Catalog Policies 
#Creation Source excludes these policies - Firewall Windows default policy and NGP Windows default policy
$SC = get-mgdevicemanagementconfigurationpolicy -filter "(platforms eq 'windows10') and (CreationSource ne 'MdeDeviceConfigurationPolicies')"

foreach ($Catalog in $SC){
    $id = $Catalog.Id
    write-host = $catalog.displayname
    Remove-MgDeviceManagementConfigurationPolicy -DeviceManagementConfigurationPolicyId $id
}


$CSP = Get-MgDeviceManagementDeviceConfiguration

foreach ($policy in $CSP){
    write-host $policy.DisplayName
    remove-MgDeviceManagementDeviceConfiguration -DeviceConfigurationId $policy.id  
    
}

#macOS Scripts

$ShellScript = Get-MgDeviceManagementDeviceShellScript

foreach ($script in $ShellScript){
    $id = $script.Id
    Remove-MgDeviceManagementDeviceShellScript -DeviceShellScriptId $id
}




$featureUpdates = Get-MgDeviceManagementWindowFeatureUpdateProfile

foreach ($update in $featureUpdates){
    $id = $update.Id
    write-host $update.DisplayName
    Remove-MgDeviceManagementWindowFeatureUpdateProfile -WindowsFeatureUpdateProfileId $id
}

#Windows PowerShell Scripts 
$PSScript = Get-MgDeviceManagementScript   

foreach ($script in $PSScript){
    $id = $script.Id
    Remove-MgDeviceManagementScript -DeviceManagementScriptId $id
}

#Compliance Policy notifications

$Notifications = Get-MgDeviceManagementNotificationMessageTemplate

foreach($note in $Notifications){
    Write-Host $note.displayname
    remove-MgDeviceManagementNotificationMessageTemplate -NotificationMessageTemplateId $note.id
}


#Enrollment Restrictions


<# Delete all group policy analyzer

$GroupPolicy = (Get-MgDeviceManagementGroupPolicyMigrationReport).id

foreach ($policy in $GroupPolicy){
>> Remove-MgDeviceManagementGroupPolicyMigrationReport -GroupPolicyMigrationReportId $policy}
#>