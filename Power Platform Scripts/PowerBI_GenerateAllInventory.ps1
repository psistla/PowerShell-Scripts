<#
  This script to run on CLient's VM, will list the following as csv files:
    1. Capacities
    2. Workspaces
    3. Users by Workspaces
    4. Datasets by Workspaces
    5. Reports by workspaces
    6. Dashboards by workspaces
#>


If ((Get-Module MicrosoftPowerBIMgmt) -eq $null) {
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}


# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"
$BaseDirectory = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$ExportFolder = $BaseDirectory + "\" + $EDate
	
#If folder doens't exists, folder is created.
If (!(Test-Path $ExportFolder)) {
    New-Item -ItemType Directory -Force -Path $ExportFolder
    Write-host -f Green "Folder created in path: " + $BaseDirectory
}


# --------------------------->>>

# Run this if to get all workspaces
# Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if to get no personal workspaces
#$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -ne "PersonalGroup"

# Run this if you to get Group workspaces
#$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Group"

# Run this if you want only workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

# --------------------------->>>


#----------------------- CAPACITIES ----------------------#

Write-Host "Processing Capacities..." -F Yellow

try {
    $url = "capacities"
    $Capacities = (ConvertFrom-Json (Invoke-PowerBIRestMethod -Url $url -Method Get)).value
    $PSCSVExportPath = $ExportFolder + "\" + "All_Capacities.csv"
    $Capacities | select id, displayName, sku, state, region | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
    Write-Host -f Green "Process complete, Capacities list created!"
}

catch {
    Write-Host "Getting capacities failed." -ForeGroundColor Red
    $ErrorMessage = $_.Exception.Message
    Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
}

#------------------------ WORKSPACES --------------------#

Write-Host "Processing Workspaces..." -F Yellow

try {
    $PSCSVExportPath = $ExportFolder + "\" + "All_Workspaces.csv"
    $WSPath = $PSCSVExportPath
    $Workspaces | select Id, Name, Type, State, IsReadOnly, IsOrphaned, CapacityId | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
    Write-Host -f Green "Process complete, Workspaces list created!"
}

catch {
    Write-Host "Getting workspaces failed." -ForeGroundColor Red
    $ErrorMessage = $_.Exception.Message
    Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
}



#------------------------- WORKSPACE USERS ----------------------------- #

Write-Host "Processing Workspace Users..." -F Yellow

try {
    $PSCSVExportPath = $ExportFolder + "\" + "All_Workspace_Users.csv"
    $workspace_users = 
    ForEach ($workspace in $Workspaces) {
        ForEach ($user in $workspace.Users) {
            [pscustomobject]@{
                WorkspaceID   = $workspace.id
                WorkspaceName = $workspace.Name
                AccessRight   = $user.AccessRight
                User          = $User.UserPrincipalName
                Type          = $workspace.Type
            }
        }    
    }

    $workspace_users | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
    Write-Host -f Green "Process complete, Workspace-users list created!"
}

catch {
    Write-Host "Getting workspace users failed." -ForeGroundColor Red
    $ErrorMessage = $_.Exception.Message
    Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
}




#--------------------------- DATASETS ---------------------------#

$dssconfirm = Read-Host "Are you sure you want to proceed to generate Datasets" -F Yellow

If ($dssconfirm -eq 'y') {
    $ReqWSFilePath = Read-host "Enter Workspaces csv file location (Example: C:\PowerPlatform\All_Workspaces.csv) "
    Write-Host "Processing Datasets..." -F Yellow
    $PSCSVExportPath = $ExportFolder + "\" + "Datasets.csv"

    #Make sure to point to the right csv file
    #$CSVData = Import-CSV -path $WSPath
    $CSVData = Import-CSV -path $ReqWSFilePath

    $Datasets = 

    ForEach ($row in $CSVData) {
        if ($row.Type -eq "Workspace") {
            Write-Host "Looking through Workspace : " $row.Name

            try {
                ForEach ($dataset in (Get-PowerBIDataset -Scope Organization -WorkspaceId $row.Id)) {
                    [pscustomobject]@{
                        WorkspaceID             = $row.Id
                        WorkspaceName           = $row.Name
                        DatasetID               = $dataset.Id
                        DatasetName             = $dataset.Name
                        DatasetAuthor           = $dataset.ConfiguredBy
                        IsRefreshable           = $dataset.IsRefreshable
                        IsOnPremGatewayRequired = $dataset.IsOnPremGatewayRequired
                    }
                }
            }

            catch {
                Write-Host "Getting datasets failed for " $row.Name -ForeGroundColor Red
                $ErrorMessage = $_.Exception.Message
                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
            }
        }
    }

    $Datasets | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
    Write-Host -f Green "Process complete, Datasets list created!"
}



#--------------------------------- REPORTS-------------------------------#

$reportsconfirm = Read-Host "Are you sure you want to proceed to generate Reports" -F Yellow

if ($reportsconfirm -eq 'y') {
    $ReqWSFilePath = Read-host "Enter Workspaces csv file location (Example: C:\PowerPlatform\All_Workspaces.csv) "
    Write-Host "Processing Reports..." -F Yellow
    $PSCSVExportPath = $ExportFolder + "\" + "All_Reports.csv"

    #Make sure to point to the right csv file
    #$CSVData = Import-CSV -path $WSPath
    $CSVData = Import-CSV -path $ReqWSFilePath

    $Reports =

    ForEach ($row in $CSVData) {
        if ($row.State -eq "Active") {
            Write-Host "Looking through Workspace : " $row.Name

            try {
                ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $row.Id)) {
                    [pscustomobject]@{
                        WorkspaceID     = $row.Id
                        WorkspaceName   = $row.Name
                        ReportID        = $report.Id
                        ReportName      = $report.Name
                        ReportURL       = $report.WebUrl
                        ReportDatasetID = $report.DatasetId
                    }
                }
            }

            catch {
                Write-Host "Getting reports failed for " $row.Name -ForeGroundColor Red
                $ErrorMessage = $_.Exception.Message
                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
            }
        }
    }


    $Reports | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
    Write-Host -f Green "Process complete, Reports list created!"

}


#-------------------------------- DASHBOARDS -------------------------------#

$dashconfirm = Read-Host "Are you sure you want to proceed to generate Dashboards" -F Yellow

if ($dashconfirm -eq 'y') {

    $ReqWSFilePath = Read-host "Enter Workspaces csv file location (Example: C:\PowerPlatform\All_Workspaces.csv) "
    Write-Host "Processing Dashboards..." -F Yellow
    $PSCSVExportPath = $ExportFolder + "\" + "Dashboards.csv"

    #Make sure to point to the right csv file
    #$CSVData = Import-CSV -path $WSPath
    $CSVData = Import-CSV -path $ReqWSFilePath

    $Dashboards =

    ForEach ($row in $CSVData) {
        if ($row.State -eq "Active") {
            Write-Host "Looking through Workspace : " $row.Name
            ForEach ($dashboard in (Get-PowerBIDashboard -Scope Organization -WorkspaceId $row.Id)) {
                [pscustomobject]@{
                    WorkspaceID   = $row.Id
                    WorkspaceName = $row.Name
                    DashboardID   = $dashboard.Id
                    DashboardName = $dashboard.Name
                }
            }
        }
    }

    $Dashboards | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
    Write-Host -f Green "Process complete, Dashboards list created!"

}

Disconnect-PowerBIServiceAccount
