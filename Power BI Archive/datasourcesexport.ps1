﻿If ((Get-Module MicrosoftPowerBIMgmt) -eq $null)
    {
        Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
    }


#Import-Module MicrosoftPowerBIMgmt.Profile

function Split-array ($inArray,[int]$parts,[int]$size) {
    if ($parts) {
    $PartSize = [Math]::Ceiling($inArray.count / $parts)
    }
    if ($size) {
    $PartSize = $size
    $parts = [Math]::Ceiling($inArray.count / $size)
    }

    $outArray = @()
    for ($i=1; $i -le $parts; $i++) {
    $start = (($i-1)*$PartSize)
    $end = (($i)*$PartSize) - 1
    if ($end -ge $inArray.count) {$end = $inArray.count}
    $outArray+=,@($inArray[$start..$end])
    }
    return ,$outArray

}

Clear-Host
Write-Output 'Connecting to PowerBI API'
#$deploymentUser = "prasanth.sistla@globaltranz.com"
#$deploymentPwd = 'xxxxxxxxx'
#$password = ConvertTo-SecureString $deploymentPwd -AsPlainText -Force -Verbose
#$credential = New-Object System.Management.Automation.PSCredential ($deploymentUser, $password)  -Verbose
Connect-PowerBIServiceAccount
$headers =  [hashtable]::Synchronized(@{})
$headers.Value = Get-PowerBIAccessToken

<#
# get reports ----------------------------------------------------------------------
 Write-Output "Getting reports"
    $uri = "https://api.powerbi.com/v1.0/myorg/admin/reports"
    Write-Output "Running: $uri"
    Try
    {
        $response = Invoke-RestMethod -Headers $headers -Uri $uri
    }
    Catch
    {
        $PSItem.Exception.Message
        $PSItem.Exception.InnerExceptionMessage
        $PSItem.InvocationInfo | Format-List *
        throw
    }
    $reports = $response.value
 #  $reports| Export-Csv -Path "C:\Temp\reportobjects.csv"

 #>
     # get datasets ----------------------------------------------------------------------
Write-Output "Getting datasets"

$uri = "https://api.powerbi.com/v1.0/myorg/admin/groups/5f4e7d5b-3703-44ee-bef1-21ecf808e78d/datasets"
#$uri = "https://api.powerbi.com/v1.0/myorg/admin/datasets"
Write-Output "Running: $uri"
Try
{
    $response = Invoke-RestMethod -Headers $headers.Value -Uri $uri
}
Catch
{
    $PSItem.Exception.Message
    $PSItem.Exception.InnerExceptionMessage
    $PSItem.InvocationInfo | Format-List *
    throw
}
$datasets = $response.value
$statusCounter = [hashtable]::Synchronized(@{})
$statusCounter.datasetCount = $datasets.Count
$statusCounter.runningCount = 0
$startTime = Get-Date -Format "hh:mm:ss"
$threadCount = 20

  # $datasets| Export-Csv -Path "C:\Temp\datasetobjects.csv"
  #$datasets| Export-Csv -Path "C:\PowerPlatform\Inventory\ds\datasetobjects.csv"

$connectionContainerAll = [hashtable]::Synchronized(@{})
$connectionContainerAll.ConnectionDetails = @()

#$connectionContainerExt = [hashtable]::Synchronized(@{})
#$connectionContainerExt.ConnectionDetails = @()

$datasetProcessGroups = Split-array -inArray $datasets -parts $threadCount

#$datasetProcessGroups | ForEach-Object -Parallel  { 
$datasetProcessGroups | ForEach-Object { 
    foreach ($dataset in $_) {
        $datasetId = $dataset.id
        Write-Host  "Processing datasetID $datasetId"
        $statusCounter = $using:statusCounter
        $statusCounter.runningCount++
        $uri = "https://api.powerbi.com/v1.0/myorg/admin/datasets/$datasetId/datasources" 
        $currentTime = Get-Date -Format "hh:mm:ss"
        $locRunningCount = $statusCounter.runningCount
        $locDatasetCount =  $statusCounter.datasetCount 
        Write-Output "Dataset $locRunningCount of $locDatasetCount at $currentTime"
        $headers = $using:headers
        $response = Invoke-RestMethod -Headers $headers.Value -Uri $uri
        $datasources = $response.value
        foreach($datasource in $datasources){
            $datasourceType = $datasource.datasourceType
            $datasourceId = $datasource.datasourceId
            $datasourceConnectionDetails = $datasource.connectionDetails
            $datasourceConnectionDetails |Add-Member -NotePropertyName datasetId -NotePropertyValue $datasetId
            $datasourceConnectionDetails |Add-Member -NotePropertyName datasourceId -NotePropertyValue $datasourceId  
            $datasourceConnectionDetails |Add-Member -NotePropertyName datasourceType -NotePropertyValue $datasourceType 
        } 
  
        
            $connectionContainerAll = $using:connectionContainerAll
            $connectionContainerAll.ConnectionDetails +=  $datasourceConnectionDetails
        
   
        if ($locRunningCount%100) {
            $headers.Value = Get-PowerBIAccessToken
        }
    }      
        
} -ThrottleLimit $threadCount
$endTime = Get-Date -Format "hh:mm:ss"
Write-Host "Start: $startTime     End: $endTime"
$connectionDetailsCount = $connectionContainer.ConnectionDetails.Count
Write-Host "Connections Found: $connectionDetailsCount"    

$connectionContainerAll.ConnectionDetails| Export-Csv -Path "C:\PowerPlatform\Inventory\ds\datasourcesObjects.csv"
#$connectionContainerExt.ConnectionDetails| Export-Csv -Path "C:\PowerPlatform\Inventory\ds\datasourcesObjectsExt.csv"

Disconnect-PowerBIServiceAccount