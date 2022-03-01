#Install-Module -Name MicrosoftPowerBIMgmt

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

<#

This script expects an input file of all listed reports for each workspace, along with file path to their pbix files.
This script also expects all pbix files for the reports being migrated are exported from source environment.

#>

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$InputFilePath = Read-host "Enter File Location (Example: C:\Users\WWEX\Desktop\PowerPlatform\Input\ReportsPath.csv) " 
$CSVData = Import-CSV -path $InputFilePath


foreach ($row in $CSVData) 
    {

    if($row.Cycle -eq "0")
        {

        try
            {
                New-PowerBIReport -Path "$row.ReportPath" -Name "$row.ReportName" -Workspace ( Get-PowerBIWorkspace -Name "$row.WorkspaceName" ) -ConflictAction CreateOrOverwrite
                Write-Host "[SUCCESS] Adding Report file $row.ReportName to $row.WorkspaceName." -ForeGroundColor Green
            }

        catch
            {
                Write-Host "[ERROR] Adding Report $row.ReportName to $row.WorkspaceName failed." -ForeGroundColor Red
                $ErrorMessage = $_.Exception.Message
                Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
            }
        }

    }

Disconnect-PowerBIServiceAccount

