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

Write-host "Connecting Power BI with Service Account." -F Green

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount


$headers =  [hashtable]::Synchronized(@{})
$headers.Value = Get-PowerBIAccessToken

$connectionContainerAll = [hashtable]::Synchronized(@{})
$connectionContainerAll.ConnectionDetails = @()

$EDate = Get-Date -Format "MMddyyyy"

$ExportBase = "C:\PowerPlatform\GTZDatasources"

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

#$logpath = $Folder + "\" + "Datasources.csv"

ForEach ($workspace in $Workspaces)
    {

    $logpath = $Folder + "\" + $workspace.Name +".csv"

    Write-Host "Working on Data Sets in workspace: " $workspace.Name

    $Datasets = 

    ForEach ($Dataset in Get-PowerBIDataset -Scope Organization -WorkspaceId $workspace.Id)
        {

        $reqdataset = $Dataset.Id
        $uri = "https://api.powerbi.com/v1.0/myorg/admin/datasets/$reqdataset/datasources"
        $response = Invoke-RestMethod -Headers $headers.Value -Uri $uri
        
        $datasources = $response.value

        foreach($datasource in $datasources)
            {

                [pscustomobject]@{
                DatasetName = $Dataset.Name
                DatasetID = $reqdataset 
                DataSourceID = $datasource.datasourceId
                DataSourceConnectionDetails = $datasource.connectionDetails
                DataSourceType = $datasource.datasourceType
                WorkspaceID = $workspace.Id
                WorkspaceName = $workspace.Name
                }
            }

        }

    $Datasets | Export-Csv $logpath -NoTypeInformation
       
    }

Write-host "Disconnecting Power BI." -F Green

Disconnect-PowerBIServiceAccount

