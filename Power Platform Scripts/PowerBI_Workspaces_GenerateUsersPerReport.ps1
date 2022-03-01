<#
This script may need a csv file of all reports per workspace with "WorkspaceName", "ReportName", "ReportID", "ReportUrl" fields to read.
#>

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null) {
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "MMddyyyy"

#$BaseDirectory = Read-host "Enter file export location (Example >> C:\PowerPlatform)"
$BaseDirectory = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$ExportFolder = $BaseDirectory + "\" + $EDate
	
#If folder doens't exists, folder is created.
If (!(Test-Path $ExportFolder)) {
    New-Item -ItemType Directory -Force -Path $ExportFolder
    Write-host $EDate Folder created in path: $BaseDirectory -F Green
}

$InputFilePath = Read-host "Enter input file location for Users from source tenant"
$CSVData = Import-CSV -path $InputFilePath
    
$logpath = $ExportFolder + "\" + "Output_AllUsersPerReport.csv"

$headers = [hashtable]::Synchronized(@{})
$headers.Value = Get-PowerBIAccessToken

$Reports =

ForEach ($row in $CSVData) {
    #$WorkspaceName = "Test Workspace name"
    #$ReqWorkspace = Get-PowerBIWorkspace -Name $WorkspaceName
    $ReqWorkspaceName = $row.WorkspaceName

    $ReqReportId = $row.ReportID
    $ReqReportName = $row.ReportName
    $ReqReportURL = $row.ReportURL
    Write-Host Processing report: $ReqReportName -ForegroundColor Gray

    $uri = "https://api.powerbi.com/v1.0/myorg/admin/reports/$ReqReportId/users"

    $response = Invoke-RestMethod -Headers $headers.Value -Uri $uri

    $PBIUsers = $response.value

    ForEach ($PBIUser in $PBIUsers) {
        [pscustomobject]@{
            WorkspaceName    = $ReqWorkspaceName
            ReportID         = $ReqReportId
            ReportName       = $ReqReportName
            ReportURL        = $ReqReportURL
            ReportUser       = $PBIUser.displayName
            ReportUserEmail  = $PBIUser.emailAddress
            ReportUserType   = $PBIUser.userType
            ReportUserAccess = $PBIUser.reportUserAccessRight
        }
    }                  

                    
}

$Reports | Export-Csv -Path $logpath -NoTypeInformation
#Write-Host "Process complete, list of all users per report is created for" $ReqWorkspaceName -F Green


Disconnect-PowerBIServiceAccount