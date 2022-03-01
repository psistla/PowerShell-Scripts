
Update-Module -Name Microsoft.PowerApps.Administration.PowerShell 

#Connect
$cred = Get-Credential
$outputRoot = '.\PowerAppsReport'
$outputFile = '.\PowerAppsReport.csv'

Get-TenantSettings
$PAppEnv = Get-AdminPowerAppEnvironment
$PAppEnv | ft

$PApps = Get-AdminPowerApp
$PApps.count
$PApps | ft
#Export the Power Apps Inventory
$PApps | Select-Object `
    AppName,DisplayName,CreatedTime,`
    @{Name=“Owner”;Expression={($_.Owner | select *).UserPrincipalName}},`
    LastModifiedTime,`
    @{Name=“EnvironmentNameID”;Expression={$_.EnvironmentName}},`
    @{Name=“EnvironmentName”;Expression={(Get-AdminPowerAppEnvironment $_.EnvironmentName | select *).DisplayName}},`
    UnpublishedAppDefinition,`
    IsFeaturedApp,`
    IsHeroApp,`
    BypassConsent,`
    @{Name=“AppType”;Expression={($_.Internal | Select *).appType}}`
    | Export-Csv -Path "$outputRoot-Inventory.csv" -NoTypeInformation

#Display the number of apps each user owns
Get-AdminPowerApp | Select –ExpandProperty Owner | Select –ExpandProperty displayname | Group

#Display the number of apps in each environment
Get-AdminPowerApp | Select -ExpandProperty EnvironmentName | Group | %{ New-Object -TypeName PSObject -Property @{ DisplayName = (Get-AdminPowerAppEnvironment -EnvironmentName $_.Name | Select -ExpandProperty displayName); Count = $_.Count } }

#Download Power Apps user details
#Get-AdminPowerAppsUserDetails -OutputFilePath '.\adminUserDetails.txt' –UserPrincipalName 'admin@bappartners.onmicrosoft.com'

#Export a list of assigned user licenses
Get-AdminPowerAppLicenses -OutputFilePath "$outputRoot-Licenses.csv"
