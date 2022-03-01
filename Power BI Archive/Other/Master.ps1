If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
{
Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# This script lists all workspaces, reports and dashboards for all active workspaces.

# connect to PBI service using the service account
# $User = "login ID"
# $PWord = ConvertTo-SecureString -String "Login password" -AsPlainText -Force
# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

$ExportBase = "C:\PowerPlatform"

$Folder = $ExportBase + "\" + $EDate
	
    #If folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host -f Green "Folder created in path: " + $ExportBase
	}

################################# Capacities #################################

Write-Host "Processing Capacities..."
$url = "capacities"
$Capacities = (ConvertFrom-Json (Invoke-PowerBIRestMethod -Url $url -Method Get)).value


# export capacities
$logpath = $Folder + "\" + "Capacities.csv"
$Capacities | select id, displayName, sku, state, region | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"

################################# Workspaces #################################

Write-Host "Processing Workspaces..."

# Run this if you want all workspaces
# $Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"



# export workspaces
$logpath = $Folder + "\" + "Workspaces.csv"
$WSPath = $logpath

$Workspaces | select Id, Name, Type, State, IsReadOnly, IsOrphaned, CapacityId | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"

################################# Workspace Users #################################

Write-Host "Processing Workspace Users..."

# export workspace users
$logpath = $Folder + "\" + "Workspace_users.csv"
$workspace_users = 
ForEach ($workspace in $Workspaces)
    {
    ForEach ($user in $workspace.Users)
        {
        [pscustomobject]@{
            WorkspaceID = $workspace.id
            WorkspaceName = $workspace.Name
            AccessRight = $user.AccessRight
            User = $User.UserPrincipalName
            }
        }    
    }

$workspace_users | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"


################################# Datasets #################################

Write-Host "Processing Datasets..."
$logpath = $Folder + "\" + "Datasets.csv"

#Make sure to point to the right csv file
$CSVData = Import-CSV -path $WSPath

$Datasets = 

ForEach ($row in $CSVData)
    {
        if($row.State -eq "Active")
        {
            Write-Host "Looking through Workspace : " + $row.Name
            ForEach ($dataset in (Get-PowerBIDataset -Scope Organization -WorkspaceId $row.Id))
                {
                    [pscustomobject]@{
                    WorkspaceID = $row.Id
                    WorkspaceName = $row.Name
                    DatasetID = $dataset.Id
                    DatasetName = $dataset.Name
                    DatasetAuthor = $dataset.ConfiguredBy
                    IsRefreshable = $dataset.IsRefreshable
                    IsOnPremGatewayRequired = $dataset.IsOnPremGatewayRequired
                    }
                }
        }
    }

$Datasets | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"

################################# Reports #################################

Write-Host "Processing Reports..."
$logpath = $Folder + "\" + "Reports.csv"

#Make sure to point to the right csv file
$CSVData = Import-CSV -path $WSPath

$Reports =

ForEach ($row in $CSVData)
    {
        if($row.State -eq "Active")
        {
            Write-Host "Looking through Workspace : " + $row.Name
            ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $row.Id))
                {
                    [pscustomobject]@{
                    WorkspaceID = $row.Id
                    WorkspaceName = $row.Name
                    ReportID = $report.Id
                    ReportName = $report.Name
                    ReportURL = $report.WebUrl
                    ReportDatasetID = $report.DatasetId
                    }
                }
        }
    }


$Reports | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"

################################# Dashboards #################################

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


Disconnect-PowerBIServiceAccount
