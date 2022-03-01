<#
  This script will create workspaces based on input file and adds a user as admin.
#>


If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$InputFilePath = Read-host "Enter file location (Example: C:\Input_Workspaces.csv) " 
$CSVData = Import-CSV -path $InputFilePath
$listcount = 0

foreach ($row in $CSVData) 
    {
        $wsname = $row.Name
        Write-Host "Looking for Workspace -->" $wsname -ForeGroundColor Yellow
        $workspace = Get-PowerBIWorkspace -Name $wsname
        if($workspace)
            {
            Write-Host "The workspace already exists!" -ForeGroundColor Yellow
            }

        else
            {
            Write-Host "Creating workspace..." -ForeGroundColor Yellow
            try
                    {
                    $workspace = New-PowerBIWorkspace -Name $wsname
                    Set-PowerBIWorkspace -Scope Organization -WorkspaceId $workspace.Id -Description 'some description'
                    $userEmail = "test@test.com"
                    Write-Host Adding $userEmail to workspace
                    Add-PowerBIWorkspaceUser -Id $workspace.Id -UserEmailAddress $userEmail -AccessRight Admin
                    }

                catch
                    {
                    Write-Host "Creating workspace failed." -ForeGroundColor Red
                    $ErrorMessage = $_.Exception.Message
                    Write-Host "ERROR MESSAGE: " $ErrorMessage -ForeGroundColor Yellow
                    }             
            }   
    }
    

Disconnect-PowerBIServiceAccount
