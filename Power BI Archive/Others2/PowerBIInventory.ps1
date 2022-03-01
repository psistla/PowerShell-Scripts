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
	
    #If the folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
	}

################################# Capacities #################################

Write-Host "Getting Capacities information..."
$url = "capacities"
$Capacities = (ConvertFrom-Json (Invoke-PowerBIRestMethod -Url $url -Method Get)).value


# export capacities
$logpath = $Folder + "\" + "Capacities.csv"
$Capacities | select id, displayName, sku, state, region | Export-Csv -Path $logpath -NoTypeInformation

# export capacity admins
# $logpath = $Folder + "\" + "capacity_admins.csv"
# $capacity_admins = 
ForEach ($capacity in $Capacities)
    {
    ForEach ($admin in $capacity.admins)
       {
        [pscustomobject]@{
           CapacityID = $capacity.id
           CapacityName = $capacity.displayName
           AdminUser = $admin
           }
       }    
       }

$capacity_admins | Export-Csv -Path $logpath -NoTypeInformation


################################# Workspaces #################################

Write-Host "Getting Workspaces..."

# Run this if you want all workspaces
# $Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"



# export workspaces
$logpath = $Folder + "\" + "Workspaces.csv"
$Workspaces | select Id, Name, Type, State, IsReadOnly, IsOrphaned, CapacityId | Export-Csv -Path $logpath -NoTypeInformation



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


################################# Datasets #################################

Write-Host "Getting Datasets..."

$logpath = $Folder + "\" + "Datasets.csv"
$Datasets =
ForEach ($workspace in $Workspaces)
    {
    ForEach ($dataset in (Get-PowerBIDataset -Scope Organization -WorkspaceId $workspace.Id))
        {
        [pscustomobject]@{
            WorkspaceID = $workspace.Id
            WorkspaceName = $workspace.Name
            DatasetID = $dataset.Id
            DatasetName = $dataset.Name
            DatasetAuthor = $dataset.ConfiguredBy
            IsRefreshable = $dataset.IsRefreshable
            IsOnPremGatewayRequired = $dataset.IsOnPremGatewayRequired
            }
        }
    }
$Datasets | Export-Csv -Path $logpath -NoTypeInformation

################################# Dashboards #################################

Write-Host "Getting Dashboards..."

$logpath = $Folder + "\" + "dashboards.csv"
$Dashboards =
ForEach ($workspace in $Workspaces)
    {
    Write-Host "Reading dashboards from workspace: " $workspace.Name
    ForEach ($dashboard in (Get-PowerBIDashboard -Scope Organization -WorkspaceId $workspace.Id))
        {
        [pscustomobject]@{
            WorkspaceID = $workspace.Id
            WorkspaceName = $workspace.Name
            DashboardID = $dashboard.Id
            DashboardName = $dashboard.Name
            }
        }
    }

$Dashboards | Export-Csv -Path $logpath -NoTypeInformation


################################# Reports #################################

$logpath = $Folder + "\" + "Reports.csv"

$Reports =
ForEach ($workspace in $Workspaces)
    {
    Write-Host "Reading reports from workspace: " $workspace.Name
    ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id))
        {
        [pscustomobject]@{
            WorkspaceID = $workspace.Id
            WorkspaceName = $workspace.Name
            ReportID = $report.Id
            ReportName = $report.Name
            ReportURL = $report.WebUrl
            ReportDatasetID = $report.DatasetId
            }
        }
    }
$Reports | Export-Csv -Path $logpath -NoTypeInformation


Disconnect-PowerBIServiceAccount
