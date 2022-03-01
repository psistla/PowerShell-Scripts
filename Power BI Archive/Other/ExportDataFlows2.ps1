﻿If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

write-host "Connected to service account." -F Green

$EDate = Get-Date -Format "MMddyyyy"

$ExportBase = "C:\PowerPlatform"

$Folder = $ExportBase + "\" + $EDate


	
#If folder doens't exists, folder is created.
If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host -f Green "Folder created in path -->" $ExportBase
	}

$DFFolder = $Folder + "\" + "Dataflows"



#If folder doens't exists, folder is created.
If(!(Test-Path $DFFolder))
	{
		New-Item -ItemType Directory -Force -Path $DFFolder
        Write-host -f Green "Folder created in path -->" $Folder
	}

#$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All | where state -eq "Active" | where type -eq "Workspace"
write-host "Searching through" $Workspaces.Count "Workspaces." -F Green

ForEach ($workspace in $Workspaces)
    {
        $dataflows = Get-PowerBIDataflow -WorkspaceId $workspace.Id
                
        If($dataflows.Count -eq 0)

        {
        write-host "Dataflows not found in" $workspace.Name -F Yellow
        }

        else

        {

        $WSFolder = $DFFolder + "\" + $workspace.Name

        #If folder doens't exists, folder is created.
        If(!(Test-Path $WSFolder))
	        {
		        New-Item -ItemType Directory -Force -Path $WSFolder
	        }

        write-host $dataflows.Count "Dataflows found in" $workspace.Name -F Green

        ForEach ($dataflow in $dataflows) 
            {

                If ($dataflow.Name -ne "")
                    {
                        $ExportFile = $WSFolder + "\" + $dataflow.Name + ".json"
                        Export-PowerBIDataflow -WorkspaceId $workspace.Id -Id $dataflow.Id -OutFile $ExportFile
                    }
            }
        }

    }
    
    
    Disconnect-PowerBIServiceAccount