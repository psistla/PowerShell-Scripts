<#

This script will ask for a Workspace Name.

#>

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"



$WorkspaceName = Read-host "Enter Workspace Name"
$ReqWorkspace = Get-PowerBIWorkspace -Name $WorkspaceName
$ReqWorkspaceName = $ReqWorkspace.Name



If($ReqWorkspaceName)
    {

    $ExportBase = Read-host "Enter file export location (Example >> C:\PowerPlatform)"
    $Folder = $ExportBase + "\" + $EDate
	
    #If folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host $EDate Folder created in path: $ExportBase -F Green
	}
    
    $logpath = $Folder + "\" + "AllUsersPerReportForAWorkspace.csv"

    $headers =  [hashtable]::Synchronized(@{})
    $headers.Value = Get-PowerBIAccessToken

        Write-Host Processing all reports in $ReqWorkspaceName -F Yellow

        $Reports =
        
            ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $ReqWorkspace.Id))
                {

                    $ReqReportId = $report.Id
                    $ReqReportName = $report.Name
                    Write-Host Processing report: $ReqReportName -ForegroundColor Gray

                    $uri = "https://api.powerbi.com/v1.0/myorg/admin/reports/$ReqReportId/users"

                    $response = Invoke-RestMethod -Headers $headers.Value -Uri $uri

                    $PBIUsers = $response.value

                    ForEach($PBIUser in $PBIUsers)
                        {
                            [pscustomobject]@{
                            WorkspaceName = $ReqWorkspaceName
                            ReportID = $ReqReportId
                            ReportName = $ReqReportName
                            ReportURL = $report.WebUrl
                            ReportUser = $PBIUser.displayName
                            ReportUserEmail = $PBIUser.emailAddress
                            ReportUserType = $PBIUser.userType
                            ReportUserAccess = $PBIUser.reportUserAccessRight
                            }
                        }                  

                    
                }

        $Reports | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host "Process complete, list of all users per report is created for" $ReqWorkspaceName -F Green

    }


Disconnect-PowerBIServiceAccount