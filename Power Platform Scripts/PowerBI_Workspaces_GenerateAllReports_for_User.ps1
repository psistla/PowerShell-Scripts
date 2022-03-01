If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
{
Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
}

# Log in to Power BI (PBI Administartor)
Connect-PowerBIServiceAccount

#$InputFilePath = Read-host "Input file location of users" 
#$CSVData = Import-CSV -path $InputFilePath

$CSVData = Import-CSV -path "C:\PowerPlatform\Exports\Users.csv"

$headers =  [hashtable]::Synchronized(@{})
$headers.Value = Get-PowerBIAccessToken

$EDate = Get-Date -Format "MMddyyyy"
#$BaseDirectory = Read-host "Enter Export Location (Example: C:\PowerPlatform) "
$ExportFolder = "C:\PowerPlatform\Exports\" + $EDate
	
    #If folder doens't exists, folder is created.
	If(!(Test-Path $ExportFolder ))
	{
		New-Item -ItemType Directory -Force -Path $ExportFolder 
        Write-host -f Green "Folder created in path: " + $BaseDirectory
	}

$logpath = $ExportFolder  + "\" + $(get-date -f MMddyyyy_HH_mm_ss) + "UserArtifacts.csv"

$UserArtifacts =

ForEach ($row in $CSVData)
    {

        $reqUserEmail = $row.UserPrincipalName
        $reqUserAction = $row.Action
        #$reqUserName - $row.Displayname
        
        $uri = "https://api.powerbi.com/v1.0/myorg/admin/users/$reqUserEmail/artifactAccess"
        $response = Invoke-RestMethod -Headers $headers.Value -Uri $uri
        
        $Artifactslist = $response.value

        foreach($Artifact in $Artifactslist)
            {

                [pscustomobject]@{
                SearchedUser = $reqUserName
                SearchedUserEmail = $reqUserEmail
                ActionNeeded = $reqUserAction
                ArtifactID = $Artifact.artifactId
                ArtifactName = $Artifact.displayName
                ArtifactType = $Artifact.artifactType
                ArtifactAccess = $Artifact.accessRight
                }
            }
            
    }
    
    
$UserArtifacts | Export-Csv $logpath -NoTypeInformation
    
Write-host "Disconnecting Power BI." -F Green

Disconnect-PowerBIServiceAccount

