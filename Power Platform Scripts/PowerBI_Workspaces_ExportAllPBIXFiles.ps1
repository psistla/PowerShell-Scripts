# This script exports Reports with datasets (PBIX) files from workspaces.
# Look for REST API to export paginated reports. https://docs.microsoft.com/en-us/rest/api/power-bi/reports/get-reports-in-group


If ((Get-Module MicrosoftPowerBIMgmt) -eq $null) {
	Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

#Date of Export
$EDate = Get-Date -Format "MMddyyyy"
$BaseDirectory = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$ExportFolder = $BaseDirectory + "\" + $EDate

#If folder doens't exists, folder is created.
If (!(Test-Path $ExportFolder)) {
	New-Item -ItemType Directory -Force -Path $ExportFolder
	Write-host -f Green "Folder created in path -->" $BaseDirectory
}

$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"

$AllReportsFolder = $ExportFolder + "\" + "Reports"

If (!(Test-Path $AllReportsFolder)) {
	New-Item -ItemType Directory -Force -Path $AllReportsFolder
	Write-host -f Green "Folder created in path -->" $ExportFolder
}


#Loop through each workspace
ForEach ($Workspace in $Workspaces) {
	$EachReportFolder = $AllReportsFolder + "\" + $Workspace.name 
	
	If (!(Test-Path $EachReportFolder)) {
		New-Item -ItemType Directory -Force -Path $EachReportFolder
	}	

	#Get Reports 
	$PBIReports = Get-PowerBIReport -WorkspaceId $Workspace.Id
		
	#Loop through each report 
	ForEach ($Report in $PBIReports) {
		Write-Host $Workspace.name "--> downloading report -->" $Report.name -F Green
			
		$OutputFile = $EachReportFolder + "\" + $Report.name + ".pbix"
			
		if (Test-Path $OutputFile) {
			Remove-Item $OutputFile
		}		
			
		try {
			Export-PowerBIReport -WorkspaceId $Workspace.ID -Id $Report.ID -OutFile $OutputFile
		}
                
		catch {
			Write-Host "Export failed for -->" $Report.name -ForeGroundColor Red
			$ErrorMessage = $_.Exception.Message
			Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
		}
			
	}
}

Disconnect-PowerBIServiceAccount