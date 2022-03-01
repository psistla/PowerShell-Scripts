<#

This script expects a csv file of all reports per workspace with "WorkspaceName", "ReportName", "ReportID", "ReportUrl" fields to read.

#>




If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

#$InputFilePath = Read-host "Enter Input File Location for Users from GTZ"
$InputFilePath = "C:\PowerPlatform\AllReports.csv"
$CSVData = Import-CSV -path $InputFilePath

#$ExportBase = Read-host "Enter file export location (Example >> C:\PowerPlatform)"
$ExportBase = "C:\PowerPlatform"
    $Folder = $ExportBase + "\" + $EDate
	
    #If folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
        Write-host $EDate Folder created in path: $ExportBase -F Green
	}
    
    $logpath = $Folder + "\" + "Output_AllUsersPerReport.csv"

        $headers =  [hashtable]::Synchronized(@{})
    $headers.Value = Get-PowerBIAccessToken

     $Reports =

ForEach($row in $CSVData)

{


#$WorkspaceName = 
#$ReqWorkspace = Get-PowerBIWorkspace -Name $WorkspaceName
$ReqWorkspaceName = $row.WorkspaceName



                    $ReqReportId = $row.ReportID
                    $ReqReportName = $row.ReportName
                    $ReqReportURL = $row.ReportURL
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
                            ReportURL = $ReqReportURL
                            ReportUser = $PBIUser.displayName
                            ReportUserEmail = $PBIUser.emailAddress
                            ReportUserType = $PBIUser.userType
                            ReportUserAccess = $PBIUser.reportUserAccessRight
                            }
                        }                  

                    
}

        $Reports | Export-Csv -Path $logpath -NoTypeInformation
        Write-Host "Process complete, list of all users per report is created for" $ReqWorkspaceName -F Green




Disconnect-PowerBIServiceAccount