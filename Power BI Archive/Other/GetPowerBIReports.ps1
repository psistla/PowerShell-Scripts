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

Write-Host "******* Exporting Data Sources *****"
$logpath = $Folder + "\" + "datasources.csv"
$Datasources =
ForEach ($dataset in $Datasets)
    {
    $url = "/datasets/" + $dataset.DatasetID + "/datasources"
    $sources = (ConvertFrom-Json (Invoke-PowerBIRestMethod -Url $url -Method Get)).value
    ForEach($datasource in $sources)
        {
        [pscustomobject]@{
            WorkspaceID = $dataset.WorkspaceID
            WorkspaceName = $dataset.WorkspaceName
            DatasetID = $dataset.DatasetID
            DatasetName = $dataset.DatasetName
            DataSourceID = $datasource.datasourceId
            DataSourceType = $datasource.datasourceType
            DataSourceConnection = $datasource.connectionDetails
            DataSourceGatewayID = $datasource.gatewayId
            }
        }
    }
$Datasources | Export-Csv -Path $logpath -NoTypeInformation