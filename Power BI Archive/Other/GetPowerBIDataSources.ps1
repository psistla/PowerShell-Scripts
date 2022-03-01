Connect-PowerBIServiceAccount


Function Get-DataSourcesfromWorkspace {

param
    (
        [string]$WS_Name  = $(throw "Workspace Name"),
        [string]$WS_ID = $(throw "Workspace ID")
    )


$WSName = $WS_Name
$WSID = $WS_ID

$DataSourceExport = 'C:\PowerPlatform\Inventory\ds\' + $WSName.Trim() + '_DataSources.csv'

# Get workspace ID
# $WSID = (Get-PowerBIWorkspace -Scope Organization -Name $WSName).Id

# Get datasets within workspaces
$WSDatasets = Get-PowerBIDataset -Scope Organization -WorkspaceId $WSID | Select-Object *, @{Name="Workspace";Expression={$WSName}}

#Loop through datasets to get data sources
$WSDataSources = ForEach($DS in $WSDatasets)
    {
        $DSID = $DS.Id
        $DSName = $DS.Name
        $WSName = $DS.Workspace
        Get-PowerBIDatasource -Scope Organization -DatasetId $DSID | `
        Select-Object *,@{Name="Dataset";Expression={$DSName}},@{Name="Workspace";Expression={$WSName}},@{Name="DateRetrieved";Expression={Get-Date}}
    }

#6. Export data sources of workspace datasets to CSV
$WSDataSources | Export-Csv $DataSourceExport

}




#Read the CSV file
$CSVData = Import-CSV -path "C:\PowerPlatform\Inventory\OnlyWorkspaces.csv"
$listcount = 0

foreach ($row in $CSVData) 
    {
        if($row.State -eq "Active")
            {
                Write-Host "Reading through Workspace :" $row.Name -ForeGroundColor green
                $listcount += 1
                Get-DataSourcesfromWorkspace $row.Name $row.Id
                }
    }
    Write-Host "Total Workspaces checked : " $listcount -ForeGroundColor yellow