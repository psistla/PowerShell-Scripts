# This script lists all workspaces, reports and dashboards for all active workspaces.


If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }


# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential
# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

#$ExportBase = "C:\PowerPlatform"
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


################################# Capacities #################################

Write-Host "Processing Capacities..." -F Yellow

try
    {
        $url = "capacities"
        $Capacities = (ConvertFrom-Json (Invoke-PowerBIRestMethod -Url $url -Method Get)).value


        # export capacities
        $logpath = $Folder + "\" + "Capacities.csv"
        $Capacities | select id, displayName, sku, state, region | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Capacities list created!"
    }

catch
    {
        Write-Host "Getting capacities failed." -ForeGroundColor Red
        $ErrorMessage = $_.Exception.Message
        Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
    }

################################# Workspaces #################################

Write-Host "Processing Workspaces..." -F Yellow

try
    {
        # export workspaces
        $logpath = $Folder + "\" + "AllWorkspaces.csv"
        $WSPath = $logpath

        $Workspaces | select Id, Name, Type, State, IsReadOnly, IsOrphaned, CapacityId | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Workspaces list created!"
    }

catch
    {
        Write-Host "Getting workspaces failed." -ForeGroundColor Red
        $ErrorMessage = $_.Exception.Message
        Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
    }



################################# Workspace Users #################################

Write-Host "Processing Workspace Users..." -F Yellow

try
    {
        # export workspace users
        $logpath = $Folder + "\" + "All_Workspace_Users.csv"
        $workspace_users = 
        ForEach ($workspace in $Workspaces)
            {
                ForEach ($user in $workspace.Users)
                    {
                        [pscustomobject]@{
                        WorkspaceID = $workspace.id
                        WorkspaceName = $workspace.Name
                        AccessRight = $user.AccessRight
                        User = $User.UserPrincipalName
                        Type = $workspace.Type
                        }
                    }    
            }

        $workspace_users | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Workspace-users list created!"
    }

catch
    {
        Write-Host "Getting workspace users failed." -ForeGroundColor Red
        $ErrorMessage = $_.Exception.Message
        Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
    }




################################# Datasets #################################

$dssconfirm = Read-Host "Are you sure you want to proceed to generate Datasets" -F Yellow

If ($dssconfirm -eq 'y')
    {
        Write-Host "Processing Datasets..." -F Yellow
        $logpath = $Folder + "\" + "Datasets.csv"

        #Make sure to point to the right csv file
        $CSVData = Import-CSV -path $WSPath

        $Datasets = 

        ForEach ($row in $CSVData)
            {
                #if($row.State -eq "Active")
                If($row.Type -eq "Workspace")
                    {
                        Write-Host "Looking through Workspace : " $row.Name

                        try
                            {
                                ForEach ($dataset in (Get-PowerBIDataset -Scope Organization -WorkspaceId $row.Id))
                                    {
                                        [pscustomobject]@{
                                        WorkspaceID = $row.Id
                                        WorkspaceName = $row.Name
                                        DatasetID = $dataset.Id
                                        DatasetName = $dataset.Name
                                        DatasetAuthor = $dataset.ConfiguredBy
                                        IsRefreshable = $dataset.IsRefreshable
                                        IsOnPremGatewayRequired = $dataset.IsOnPremGatewayRequired
                                        }
                                    }
                            }

                        catch
                            {
                                Write-Host "Getting datasets failed for " $row.Name -ForeGroundColor Red
                                $ErrorMessage = $_.Exception.Message
                                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
                            }
                    }
            }

        $Datasets | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Datasets list created!"
    }



################################# Reports #################################

$reportsconfirm = Read-Host "Are you sure you want to proceed to generate Reports" -F Yellow

if ($reportsconfirm -eq 'y')
    {
        Write-Host "Processing Reports..." -F Yellow
        $logpath = $Folder + "\" + "All_Reports.csv"

        #Make sure to point to the right csv file
        $CSVData = Import-CSV -path $WSPath

        $Reports =

        ForEach ($row in $CSVData)
            {
                if($row.State -eq "Active")
                    {
                        Write-Host "Looking through Workspace : " $row.Name

                        try
                            {
                                ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $row.Id))
                                    {
                                        [pscustomobject]@{
                                        WorkspaceID = $row.Id
                                        WorkspaceName = $row.Name
                                        ReportID = $report.Id
                                        ReportName = $report.Name
                                        ReportURL = $report.WebUrl
                                        ReportDatasetID = $report.DatasetId
                                        }
                                    }
                            }

                        catch
                            {
                                Write-Host "Getting reports failed for " $row.Name -ForeGroundColor Red
                                $ErrorMessage = $_.Exception.Message
                                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
                            }
                    }
            }


        $Reports | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Reports list created!"

    }


################################# Dashboards #################################

$dashconfirm = Read-Host "Are you sure you want to proceed to generate Dashboards" -F Yellow

if ($dashconfirm -eq 'y')
    {

        Write-Host "Processing Dashboards..." -F Yellow
        $logpath = $Folder + "\" + "Dashboards.csv"

        #Make sure to point to the right csv file
        $CSVData = Import-CSV -path $WSPath

        $Dashboards =

        ForEach ($row in $CSVData)
            {
                if($row.State -eq "Active")
                    {
                        Write-Host "Looking through Workspace : " $row.Name
                        ForEach ($dashboard in (Get-PowerBIDashboard -Scope Organization -WorkspaceId $row.Id))
                            {
                                [pscustomobject]@{
                                WorkspaceID = $row.Id
                                WorkspaceName = $row.Name
                                DashboardID = $dashboard.Id
                                DashboardName = $dashboard.Name
                                }
                            }
                    }
            }

        $Dashboards | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host -f Green "Process complete, Dashboards list created!"

    }



Disconnect-PowerBIServiceAccount
