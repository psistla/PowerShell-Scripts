$EDate = Get-Date -Format "yyyyMMdd"

$ExportBase = "C:\PowerPlatformGTZ"

$Folder = $ExportBase + "\" + $EDate
	
    #If the folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
	}

$logpath = $Folder + "\PowerApps.csv"

$environments = Get-AdminPowerAppEnvironment
$ppObjects=@()
foreach ($e in $environments) {
    
    $powerapps = Get-AdminPowerApp -EnvironmentName $e.EnvironmentName
    foreach ($pa in $powerapps) {
    
        foreach ($conRef in $pa.Internal.properties.connectionReferences) {
    
            foreach ($con in $conRef) {
    
                foreach ($conId in ($con | Get-Member -MemberType NoteProperty).Name) {
                    $conDetails = $($con.$conId)
                    $apiTier = $conDetails.apiTier
                    if ($conDetails.isCustomApiConnection) {$apiTier = "Premium (CustomAPI)"}
                    if ($conDetails.isOnPremiseConnection ) {$apiTier = "Premium (OnPrem)"}
    
                    $paObj=@{
                        type="Power App"
                        ConnectionName=$conDetails.displayName
                        Tier=$apiTier
                        Environment=$e.displayname
                        AppFlowName=$pa.DisplayName
                        createdDate=$pa.CreatedTime
                        createdBy=$pa.Owner
                    }
                    $ppObjects+=$(new-object psobject -Property $paObj)
                }
            }
        }
    }
    
    $flows=Get-AdminFlow -EnvironmentName $e.EnvironmentName
    foreach ($f in $flows) {
    
        $fl=get-adminflow -FlowName $f.FlowName
    
        foreach ($conRef in $fl.Internal.properties.connectionReferences) {
    
            foreach ($con in $conRef) {
    
                foreach ($conId in ($con | Get-Member -MemberType NoteProperty).Name) {
                    $conDetails = $($con.$conId)
                    $apiTier=$conDetails.apiDefinition.properties.tier
                    if ($conDetails.apiDefinition.properties.isCustomApi) {$apiTier = "Premium (CustomAPI)"}
    
                    $paObj=@{
                        type="Power Automate"
                        ConnectionName=$conDetails.displayName
                        Tier=$apiTier
                        Environment=$e.DisplayName
                        AppFlowName=$f.DisplayName
                        createdDate=$f.CreatedTime
                        createdBy=$f.CreatedBy
                    }
                    
                    $ppObjects+=$(new-object psobject -Property $paObj)
                }
            }
        }
    }
}

$ppObjects | Export-Csv $logpath -NoTypeInformation