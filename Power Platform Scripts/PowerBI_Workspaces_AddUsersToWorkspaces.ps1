<#
This script requires list of all users per workspace from old tenant to read and add to new tenant converting domains.

Fields required:
User --> User email address
WorkspaceName --> Workspace Name
AccessRight --> Admin, Member, Contributor, Viewer
PSRun --> Yes, No (to control batch run)

#>

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


<#
This script needs CSV file with all new users and roles for each workspace.
#>

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null) {
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (as PBI Administartor)
Connect-PowerBIServiceAccount

write-host "Connected to service account." -F Green

$InputFilePath = Read-host "Input file location of users" 
$CSVData = Import-CSV -path $InputFilePath

foreach ($row in $CSVData) {

    if ($row.PSRun -eq "Yes") {


        $ReqWorkspace = Get-PowerBIWorkspace -Name $row.WorkspaceName
        $gtzuseremail = $row.User
        $ReqUser = $gtzuseremail.replace("old domain", "new domain")
        $ReqAccessRight = $row.AccessRight
        try {
            Write-host Processing User: $ReqUser on Workspace: $ReqWorkspace.Name -F Green
            Add-PowerBIWorkspaceUser -Scope Organization -Id $ReqWorkspace.Id -UserEmailAddress $ReqUser -AccessRight $ReqAccessRight
        }

        catch {
            Write-Host "[ERROR] Adding Report Failed." -ForeGroundColor Red
            $ErrorMessage = $_.Exception.Message
            Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
        }
    }
}
    
Disconnect-PowerBIServiceAccount