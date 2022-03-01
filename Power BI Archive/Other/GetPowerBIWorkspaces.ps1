# This script lists all workspaces, reports and dashboards for all active workspaces.


Write-Host "Starting script:" (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')

# connect to PBI service using the service account
# $User = "login ID"
# $PWord = ConvertTo-SecureString -String "Login password" -AsPlainText -Force
# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "yyyyMMdd"

$ExportBase = "C:\PowerPlatformGTZ"

# $EDate + "_

$Folder = $ExportBase + "\" + $EDate
	
    #If the folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
	}

################################# Workspaces #################################

Write-Host "Getting Workspaces..."

# Run this if you want all workspaces
# $Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"



# export workspaces
$logpath = $Folder + "\" + "workspaces.csv"
$Workspaces | select Id, Name, Type, State, IsReadOnly, IsOrphaned, CapacityId | Export-Csv -Path $logpath -NoTypeInformation



# export workspace users
$logpath = $Folder + "\" + "workspace_users.csv"
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