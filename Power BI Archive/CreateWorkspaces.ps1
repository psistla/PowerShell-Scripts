#Install-Module -Name MicrosoftPowerBIMgmt

If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }

# Log in to Power BI (PBI Administartor)
#Connect-PowerBIServiceAccount

$userLogin = Connect-PowerBIServiceAccount
 
$userLoginName = $userLogin.UserName
$userLoginTenant = $userLogin.TenantId
$userLoginEnv = $userLogin.Environment
 
Write-Host "Authenticated as $userLoginName within tenant $userLoginTent (env = $userLoginEnv)"

#Read the CSV file

#Provide a csv file with list of Workspace Names from Source Tenant in 'Name' column

$InputFilePath = Read-host "Enter File Location (Example: C:\Users\WWEX\Downloads\Input_Workspaces.csv) " 
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
                    #New-PowerBIWorkspace -Name $wsname
                    $workspace = New-PowerBIWorkspace -Name $wsname
                    Set-PowerBIWorkspace -Scope Organization -WorkspaceId $workspace.Id -Description 'Created as part of migration effort from GTZ.'
                    #Set-PowerBIWorkspace -Scope Organization -Description 'Created as part of migration effort from GTZ.'
                    $userEmail = "BIPowerBIAdmin@wwex.com"
                    Write-Host "Adding Power BI Admin Account to workspace --> $wsname"
                    Add-PowerBIWorkspaceUser -Id $workspace.Id -UserEmailAddress $userEmail -AccessRight Admin
                    #Write-Host "Workspace Created!" -ForeGroundColor Green
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
