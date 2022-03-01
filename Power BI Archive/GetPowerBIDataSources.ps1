If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }


# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential
# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

#Write-host "Script run stopped: " (Get-Date "MMddyyyy - hh:mm:ss") -F Yellow

$Workspaces = Get-PowerBIWorkspace -Scope Organization -First 3 | where state -eq "Active" | where type -eq "Workspace"

ForEach ($Workspace in $Workspaces)
{

$WSName = $Workspace.Name
$WSID = $Workspace.Id

$DataSourceExport = 'C:\PowerPlatform\DataSource\' + $WSName.Trim() + '_DataSources.csv'

# Get datasets within workspaces
$WSDatasets = Get-PowerBIDataset -Scope Organization -WorkspaceId $WSID | Select-Object *, @{Name="Workspace";Expression={$WSName}}

#Loop through datasets to get data sources
$WSDataSources = ForEach($DS in $WSDatasets)
    {
        $DSID = $DS.Id
        $DSName = $DS.Name
        $WSName = $DS.Workspace
        Get-PowerBIDatasource -Scope Organization -DatasetId $DSID | 
        Select-Object *,@{Name="Dataset";Expression={$DSName}},@{Name="Workspace";Expression={$WSName}},@{Name="DateRetrieved";Expression={Get-Date}}
    }

#Export data sources of workspace datasets to CSV
$WSDataSources | Export-Csv $DataSourceExport
}

#Write-host "Script run stopped: " (Get-Date "MMddyyyy - hh:mm:ss") -F Yellow

Disconnect-PowerBIServiceAccount