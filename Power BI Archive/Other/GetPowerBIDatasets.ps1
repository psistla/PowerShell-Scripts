# This script lists all workspaces, reports and dashboards for all active workspaces.


Write-Host "Starting script:" (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')

# connect to PBI service using the service account
# $User = "login ID"
# $PWord = ConvertTo-SecureString -String "Login password" -AsPlainText -Force
# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

$ExportBase = "C:\PowerPlatform"

# $EDate + "_

$Folder = $ExportBase + "\" + $EDate
	
    #If the folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
	}

################################# Datasets #################################

Write-Host "Getting Datasets..."
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

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