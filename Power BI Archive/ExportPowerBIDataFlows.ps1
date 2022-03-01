# This script exports dataflows as json files from workspaces.


If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }


# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"
$ExportBase = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$Folder = $ExportBase + "\" + $EDate
	
#If folder doens't exists, folder is created.
If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host -f Green "Folder created in path: " + $ExportBase
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

$DFFolder = $Folder + "\" + "Dataflows"

#If folder doens't exists, folder is created.
If(!(Test-Path $DFFolder))
	{
		New-Item -ItemType Directory -Force -Path $DFFolder
        Write-host -f Green "Folder created in path -->" $Folder
	}


Write-host "Searching through" $Workspaces.Count "Workspaces." -F Green
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
                                try
                                    {
                                        $ExportFile = $WSFolder + "\" + $dataflow.Name + ".json"
                                        Export-PowerBIDataflow -WorkspaceId $workspace.Id -Id $dataflow.Id -OutFile $ExportFile
                                    }
                                catch
                                    {
                                        Write-Host "Getting workspace users failed." -ForeGroundColor Red
                                        $ErrorMessage = $_.Exception.Message
                                        Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
                                    }
                            }
                    }
            }
    }
    
    
    Disconnect-PowerBIServiceAccount