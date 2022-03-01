If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }


# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential
# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

#$ExportBase = "C:\PowerPlatform"
$ExportBase = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$Folder = $ExportBase + "\" + $EDate
	
#If folder doens't exists, folder is created.
If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host -f Green "Folder created in path: " + $ExportBase
	}


$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

Write-Host "Processing Workspace Users..." -F Yellow

try
    {
        # export workspace users
        $logpath = $Folder + "\" + "WWEX_All_Workspace_Users.csv"
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
                        Type = $workspace.Type
                        }
                    }    
            }

        $workspace_users | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Workspace-users list created!"
    }

catch
    {
        Write-Host "Getting workspace users failed." -ForeGroundColor Red
        $ErrorMessage = $_.Exception.Message
        Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
    }


Disconnect-PowerBIServiceAccount