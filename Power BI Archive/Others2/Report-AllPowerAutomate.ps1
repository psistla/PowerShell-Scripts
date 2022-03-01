
$outputRoot = '.\PowerAutomateReport'
$outputFile = '.\PowerAutomateReport.csv'

$Flows = Get-AdminFlow
$flows.Count
#Export all flows to a CSV file
$Flows | Select-Object `
    FlowName,DisplayName,Enabled,CreatedTime,UserType,`
    @{Name=“CreatedBy”;Expression={(Get-AzureADUser -ObjectId ($_.CreatedBy | Select *).objectId).UserPrincipalName}},`
    LastModifiedTime,`
    @{Name=“EnvironmentNameID”;Expression={$_.EnvironmentName}},`
    @{Name=“EnvironmentName”;Expression={(Get-AdminPowerAppEnvironment $_.EnvironmentName | select *).DisplayName}}`
    | Export-Csv -Path "$outputRoot-Inventory.csv" -NoTypeInformation

#Display flow owner role details
#Get-AdminFlowOwnerRole –EnvironmentName 'EnvironmentName' –FlowName 'FlowName'

#Display flow user details
#Get-AdminFlowUserDetails –UserId $Global:currentSession.userId

#Export all flows to a CSV file
#Get-AdminFlow | Export-Csv -Path '.\FlowExport.csv'

#Display all native Connections in your default environment
$NativeConnections = Get-AdminPowerAppEnvironment -Default | Get-AdminPowerAppConnection
$NativeConnections | Select-Object `
    ConnectionName,ConnectionId,FullConnectorName,ConnectorName,DisplayName,CreatedTime,`
    @{Name=“CreatedBy”;Expression={($_.CreatedBy).UserPrincipalName}},`
    LastModifiedTime,`
    @{Name=“EnvironmentNameID”;Expression={$_.EnvironmentName}},`
    @{Name=“EnvironmentName”;Expression={(Get-AdminPowerAppEnvironment $_.EnvironmentName | select *).DisplayName}},
    @{Name=“Statuses”;Expression={($_.Statuses).status}}`
    | Export-Csv -Path "$outputRoot-NativeConnections.csv" -NoTypeInformation

#Display all custom connectors in the tenant
$CustomConnectors = Get-AdminPowerAppConnector
$CustomConnectors | Select-Object `
    ConnectorId,ConnectorName,DisplayName,CreatedTime,`
    @{Name=“CreatedBy”;Expression={($_.CreatedBy).UserPrincipalName}},`
    @{Name=“originalSwaggerUrl”;Expression={($_.ApiDefinitions).originalSwaggerUrl}},`
    LastModifiedTime,`
    @{Name=“EnvironmentNameID”;Expression={$_.EnvironmentName}},`
    @{Name=“EnvironmentName”;Expression={(Get-AdminPowerAppEnvironment $_.EnvironmentName | select *).DisplayName}},
    @{Name=“isCustomApi”;Expression={($_.Internal).isCustomApi}},`
    @{Name=“primaryRuntimeUrl”;Expression={($_.Internal).primaryRuntimeUrl}},`
    @{Name=“description”;Expression={($_.Internal).description}},`
    @{Name=“apiEnvironment”;Expression={($_.Internal).apiEnvironment}},`
    @{Name=“publisher”;Expression={($_.Internal).publisher}},`
    @{Name=“tier”;Expression={($_.Internal).tier}}`
    | Export-Csv -Path "$outputRoot-CustomConnectors.csv" -NoTypeInformation
