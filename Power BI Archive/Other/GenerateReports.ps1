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

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

$ExportBase = Read-host "Enter Export Location (Example >> C:\PowerPlatform) "


$Folder = $ExportBase + "\" + $EDate
	
    #If folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host -f Green "Folder created in path: " + $ExportBase
	}

# --------------------------->>>

# Run this if you want all workspaces
# Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active"

# Run this if you want no personal workspaces
$Workspaces = Get-PowerBIWorkspace -Scope Organization -Skip 10 | where state -eq "Active" | where type -eq "Workspace"

# Run this if you want only workspaces
Write-Host "Processing Reports..."
$logpath = $Folder + "\" + "11_Reports.csv"

#Make sure to point to the right csv file
#$CSVData = Import-CSV -path $WSPath

$Reports =

ForEach($workspace in $Workspaces)
{
            Write-Host "Looking through Workspace :" $workspace.Name
            ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id))
                {
                    [pscustomobject]@{
                    WorkspaceID = $workspace.Id
                    WorkspaceName = $workspace.Name
                    ReportID = $report.Id
                    ReportName = $report.Name
                    ReportURL = $report.WebUrl
                    ReportDatasetID = $report.DatasetId
                    }
                }
}
        
    


$Reports | Export-Csv -Path $logpath -NoTypeInformation
Write-Host -f Green "Process complete, list created!"


Disconnect-PowerBIServiceAccount