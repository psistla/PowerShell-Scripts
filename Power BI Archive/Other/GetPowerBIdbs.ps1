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

# --------------------------->>>

# Run this if you want all workspaces
# $Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
#$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"

# Run this if you want only workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

$logpath = $Folder + "\" + "Dashboards.csv"

$Dashboards =
ForEach ($workspace in $Workspaces)
    {
    Write-Host "Writing dashboards...on workspace: " $workspace.Name
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

Disconnect-PowerBIServiceAccount
