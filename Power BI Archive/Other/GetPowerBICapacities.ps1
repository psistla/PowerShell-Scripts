# This script lists all workspaces, reports and dashboards for all active workspaces.


Write-Host "Starting script:" (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')

# connect to PBI service using the service account
# $User = "login ID"
# $PWord = ConvertTo-SecureString -String "Login password" -AsPlainText -Force
# $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
# Connect-PowerBIServiceAccount -Credential $UserCredential

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

$EDate = Get-Date -Format "yyyyMMdd"

$ExportBase = "C:\PowerPlatformGTZ"

# $EDate + "_

$Folder = $ExportBase + "\" + $EDate
	
    #If the folder doens't exists, folder is created.
	If(!(Test-Path $Folder))
	{
		New-Item -ItemType Directory -Force -Path $Folder
	}

################################# Capacities #################################

Write-Host "Getting Capacities information..."
$url = "capacities"
$Capacities = (ConvertFrom-Json (Invoke-PowerBIRestMethod -Url $url -Method Get)).value


# export capacities
$logpath = $Folder + "\" + "capacities.csv"
$Capacities | select id, displayName, sku, state, region | Export-Csv -Path $logpath -NoTypeInformation

# export capacity admins
$logpath = $Folder + "\" + "capacity_admins.csv"
$capacity_admins = 
ForEach ($capacity in $Capacities)
    {
    ForEach ($admin in $capacity.admins)
       {
        [pscustomobject]@{
           CapacityID = $capacity.id
           CapacityName = $capacity.displayName
           AdminUser = $admin
           }
       }    
       }

$capacity_admins | Export-Csv -Path $logpath -NoTypeInformation