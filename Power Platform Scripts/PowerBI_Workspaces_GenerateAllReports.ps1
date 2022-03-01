# This script lists all reports inventory for all workspaces.

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null) {
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"
$BaseDirectory = Read-host "Enter Export Location (Example >> C:\PowerPlatform) "
$ExportFolder = $BaseDirectory + "\" + $EDate
	
#If folder doens't exists, folder is created.
If (!(Test-Path $ExportFolder)) {
    New-Item -ItemType Directory -Force -Path $ExportFolder
    Write-host -f Green "Folder created in path: " + $BaseDirectory
}

$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

Write-Host "Processing Reports..."
$PSCSVExportPath = $ExportFolder + "\" + "All_Reports.csv"

$Reports =

ForEach ($workspace in $Workspaces) {
    Write-Host "Looking through Workspace :" $workspace.Name
    ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id)) {
        [pscustomobject]@{
            WorkspaceID     = $workspace.Id
            WorkspaceName   = $workspace.Name
            ReportID        = $report.Id
            ReportName      = $report.Name
            ReportURL       = $report.WebUrl
            ReportDatasetID = $report.DatasetId
        }
    }
}

$Reports | Export-Csv -Path $PSCSVExportPath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"

Disconnect-PowerBIServiceAccount