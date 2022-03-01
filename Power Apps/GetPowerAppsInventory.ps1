
ConnectPowerApps

# get Date
$EDate = Get-Date -Format "MMddyyyy"
$ExportBase = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$Folder = $ExportBase + "\" + $EDate

#If folder doens't exists, folder is created.
If (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Force -Path $Folder
    Write-host -f Green "Folder created in path: " + $ExportBase
}

$logpath = $Folder + "\" + "PowerAppsInventory.csv"

$powerApps = Get-AdminPowerApp 

$AllPowerApps = @()

# loop through each app
foreach ($powerApp in $powerApps) {
    # loop through each connection reference for the respective APP
    foreach ($connectionReference in $powerApp.Internal.properties.connectionReferences) {
        #loop through each connection from the connection reference
        foreach ($connection in $connectionReference) {
            foreach ($connectionId in ($connection | Get-Member -MemberType NoteProperty).Name) {
                #get the connection details
                $connectionDetails = $($connection.$connectionId)

                #prep row
                $csvRow = @{
                    AppDisplayName       = $powerApp.displayName
                    AppName              = $powerApp.appName
                    EnvironmentName      = $powerApp.environmentName
                    ConnectorDisplayName = $connectionDetails.displayName
                    ConnectionId         = $connectionDetails.id
                    ConnectionName       = $connectionDetails.connectionName
                    CreatedByEmail       = $powerApp.owner.email
                    IsPremiumConnector   = $connectionDetails.apiTier -eq 'Premium'
                }
                $AllPowerApps += $(new-object psobject -Property $csvRow)
            }
        }        
    }
}

# output to file
$AllPowerApps | Export-Csv -Path $logpath