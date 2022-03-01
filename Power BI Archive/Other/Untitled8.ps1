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


Write-Host "Getting Workspaces..."

# Run this if you want all workspaces
# $Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"

$datasources = 
ForEach ($workspace in $Workspaces)
    {
    ForEach ($datasource in $workspace.Users)
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