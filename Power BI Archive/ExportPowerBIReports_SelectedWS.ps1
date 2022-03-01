# This script exports Reports with datasets (PBIX) files from a selected workspace.


#Install-Module -Name MicrosoftPowerBIMgmt
If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$reqworkspace = Read-Host "Workspace: "

try
    {
        $Workspace = Get-PowerBIWorkspace -Scope Organization -Name $reqworkspace
    }

catch
    {
     Write-Host "Getting workspace information action failed." -ForeGroundColor Red
     $ErrorMessage = $_.Exception.Message
     Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow   
    }

#Date of Export
$EDate = Get-Date -Format "MMddyyyy"
$ExportBase = Read-Host "Location to export (Ex--> C:\PowerPlatform) :"

$Folder = $ExportBase + "\" + $EDate

#If folder doens't exists, folder is created.
If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host -f Green "Folder created in path -->" $ExportBase
	}


#Outputpath
$ReportsFolder = $Folder + "\" + "Reports"

If(!(Test-Path $ReportsFolder))
	{
		New-Item -ItemType Directory -Force -Path $ReportsFolder
        Write-host -f Green "Folder created in path -->" $Folder
	}


	#For all workspaces there is a new Folder destination: Outputpath + Workspacename
	$EachReortFolder = $ReportsFolder + "\" + $Workspace.name 
	
    #If the folder doens't exists, it will be created.
	If(!(Test-Path $EachReortFolder))
	    {
		    New-Item -ItemType Directory -Force -Path $EachReortFolder
	    }
	

    #Get Reports 
	$PBIReports = Get-PowerBIReport -WorkspaceId $Workspace.Id

	#$PBIReports = Get-PowerBIReport -WorkspaceId $Workspace.Id -Name "My Report Name"
		
		#Loop through each report 
		ForEach($Report in $PBIReports)
		{
			#Your PowerShell comandline will say Downloading Workspacename Reportname
			Write-Host $Workspace.name "--> downloading report -->" $Report.name -F Green
			
			#File to be created.
			#$OutputFile = $OutPutPath + "\" + $Workspace.name + "\" + $Report.name + ".pbix"

            $OutputFile = $EachReortFolder + "\" + $Report.name + ".pbix"
			
			# If the file exists, delete it first; otherwise, the Export-PowerBIReport will fail.
			 if (Test-Path $OutputFile)
				{
					Remove-Item $OutputFile
				}
			
			#The pbix is now really getting downloaded

            try
                {
                    Export-PowerBIReport -WorkspaceId $Workspace.ID -Id $Report.ID -OutFile $OutputFile
                }
                
            catch 
                {
				    Write-Host "Exporting Reports action failed." -ForeGroundColor Red
                    $ErrorMessage = $_.Exception.Message
                    Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
                }
			
		}


Disconnect-PowerBIServiceAccount