# Import-Module Microsoft.PowerApps.Administration.PowerShell

# get Date
$EDate = Get-Date -Format "MMddyyyy"
$ExportBase = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$Folder = $ExportBase + "\" + $EDate

#If folder doens't exists, folder is created.
If (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Force -Path $Folder
    Write-host -f Green "Folder created in path: " + $ExportBase
}

$logpath = $Folder + "\" + "AppsAndFlows.csv"
   
If (Test-Path $logpath) {
    Remove-Item $logpath
}
"Type" + "," + "DisplayName" + "," + "OwnerEmail" | Out-File $logpath -Encoding ascii
    
Add-PowerAppsAccount
    
$flows = Get-AdminFlow
$powerApps = Get-AdminPowerApp


#Flows
foreach ($flow in $flows) {
    $flowDetails = $flow | Get-AdminFlow
    $flowName = $flow.DisplayName -replace '[,]'
    $flowOwnerObj = Get-UsersOrGroupsFromGraph -ObjectId $flow.createdBy.objectId
    $ownerUPN = $flowOwnerObj.UserPrincipalName
    foreach ($connector in $flowDetails.Internal.properties.connectionReferences) {
        foreach ($connection in ($connector | gm -MemberType NoteProperty).Name) {
                
            "Flow" + "," + $flowName + "," + $ownerUPN | Out-File $logpath -Encoding ascii -Append
               
        }
    }
}


#Apps
foreach ($app in $powerApps) {
    $appName = $app.DisplayName
    $ownerObject = $app.owner.id
    $appOwnerObj = Get-UsersOrGroupsFromGraph -ObjectId $ownerObject
    $ownerUPN = $appOwnerObj.UserPrincipalName
    foreach ($connector in $app.Internal.properties.connectionReferences) {
        foreach ($connection in ($connector | gm -MemberType NoteProperty).Name) {
            $connectionProperties = $($connector.$connection)
            write-host $connectionProperties.DisplayName
                
            "PowerApp" + "," + $appName + "," + $ownerUPN | Out-File $logpath -Encoding ascii -Append
                
        }
    }
}
#endregion