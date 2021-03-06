# This script exports Reports with datasets; PBIX or RDL files from workspaces.

#Install-Module -Name MicrosoftPowerBIMgmt

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null) {
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

#Date of Export
$EDate = Get-Date -Format "MMddyyyy"
$ExportBase = "C:\PowerPlatform"
$Folder = $ExportBase + "\" + $EDate

#If folder doens't exists, folder is created.
If (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Force -Path $Folder
    Write-host -f Green "Folder created in path -->" $ExportBase
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

$ReportsFolder = $Folder + "\" + "Reports"

If (!(Test-Path $ReportsFolder)) {
    New-Item -ItemType Directory -Force -Path $ReportsFolder
    Write-host -f Green "Folder created in path -->" $Folder
}


#Loop through each workspace
ForEach ($Workspace in $Workspaces) {
    #For all workspaces there is a new Folder destination: Outputpath + Workspacename
    $EachReortFolder = $ReportsFolder + "\" + $Workspace.name 
	
    #If the folder doens't exists, it will be created.
    If (!(Test-Path $EachReortFolder)) {
        New-Item -ItemType Directory -Force -Path $EachReortFolder
    }

    #Get Reports 
    $PBIReports = Get-PowerBIReport -WorkspaceId $Workspace.Id
	
    #Loop through each report 
    ForEach ($Report in $PBIReports) {
			
        if ($Report.WebUrl -contains "rdlreports") {
            #File to be created.
            $OutputFile = $EachReortFolder + "\" + $Report.name + ".rdl"
            
            # If the file exists, delete it first; otherwise, the Export-PowerBIReport will fail.
            if (Test-Path $OutputFile) {
                Remove-Item $OutputFile
            }
		
            try {
                #Your PowerShell comandline will say Downloading Workspacename Reportname
                Write-Host $Workspace.name "--> downloading report -->" $Report.name -F Green
                Export-PowerBIReport -WorkspaceId $Workspace.ID -Id $Report.ID -OutFile $OutputFile
            }
                    
            catch {
                Write-Host "Export Report action failed for -->" $Report.name -ForeGroundColor Red
                $ErrorMessage = $_.Exception.Message
                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
            }
        }
        
        else {
            #File to be created.
            $OutputFile = $EachReortFolder + "\" + $Report.name + ".pbix"
            
            # If the file exists, delete it first; otherwise, the Export-PowerBIReport will fail.
            if (Test-Path $OutputFile) {
                Remove-Item $OutputFile
            }
		
            try {
                #Your PowerShell comandline will say Downloading Workspacename Reportname
                Write-Host $Workspace.name "--> downloading report -->" $Report.name -F Green
                Export-PowerBIReport -WorkspaceId $Workspace.ID -Id $Report.ID -OutFile $OutputFile
            }
                    
            catch {
                Write-Host "Export Report action failed for -->" $Report.name -ForeGroundColor Red
                $ErrorMessage = $_.Exception.Message
                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
            }
        }        
					
    }
}

Disconnect-PowerBIServiceAccount