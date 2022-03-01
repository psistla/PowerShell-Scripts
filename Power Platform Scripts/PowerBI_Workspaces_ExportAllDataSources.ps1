<#
  This script generates datsources for all reports across all workspaces.
#>

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
{
Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$headers =  [hashtable]::Synchronized(@{})
$headers.Value = Get-PowerBIAccessToken

$connectionContainerAll = [hashtable]::Synchronized(@{})
$connectionContainerAll.ConnectionDetails = @()

$EDate = Get-Date -Format "MMddyyyy"
$BaseDirectory = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$ExportFolder = $BaseDirectory + "\" + $EDate
	
    #If folder doens't exists, folder is created.
	If(!(Test-Path $ExportFolder ))
	{
		New-Item -ItemType Directory -Force -Path $ExportFolder 
        Write-host -f Green "Folder created in path: " + $BaseDirectory
	}

# --------------------------->>>

# Run this if you want all workspaces
# $Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
#$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"

# Run this if you want only workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

ForEach ($workspace in $Workspaces)
    {

    $logpath = $ExportFolder  + "\" + $workspace.Name +".csv"

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

