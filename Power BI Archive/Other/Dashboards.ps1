# Run this if you want only workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

Write-Host "Processing Dashboards..."
$logpath = $Folder + "\" + "Dashboards.csv"

#Make sure to point to the right csv file
$CSVData = Import-CSV -path $WSPath

$Dashboards =

ForEach ($row in $CSVData)
    {
        if($row.State -eq "Active")
        {
            Write-Host "Looking through Workspace : " + $row.Name
            ForEach ($dashboard in (Get-PowerBIDashboard -Scope Organization -WorkspaceId $row.Id))
                {
                    [pscustomobject]@{
                    WorkspaceID = $row.Id
                    WorkspaceName = $row.Name
                    DashboardID = $dashboard.Id
                    DashboardName = $dashboard.Name
                    }
                }
        }
    }

$Dashboards | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"