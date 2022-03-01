<#

1. Admin – This role is granted to special users who have the permissions to deal with the administrative tasks
    within the workspace like adding or removing other people or admins, or allowing any contributor to update an app in the workspace, etc.
2. Member – The member role is usually granted to those who have almost similar privileges as an admin, except the fact that they cannot operate on the admin users.
    Users with the member role can add other members in the workspace with a member or lower permission like contributor or a viewer.
    Apart from this, they can also publish new apps within the workspace and also update the apps
3. Contributor – The contributor role has fewer privileges as compared to the member role.
    As a contributor, the users can add, modify, or delete content in the workspace, publish and edit new reports, copy reports from one workspace to another etc.
    These users can also schedule data refreshes and modify data gateway connection strings.
4. Viewer – These users have the least permissions within a workspace.
    They are only allowed to view and interact with certain reports without being able to modify those.

#>

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

write-host "Connected to service account." -F Green

$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"
#Loop through each workspace
ForEach($Workspace in $Workspaces)
{
    Add-PowerBIWorkspaceUser -Scope Organization -Id $workspace.Id -UserEmailAddress prasanth.sistla@globaltranz.com -AccessRight Admin
    Write-host Added user to $Workspace.Name -F Green

}


Disconnect-PowerBIServiceAccount