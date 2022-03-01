<#################################################################
Topology - reports with only live connections to on-prem SSAS
                    this solution also deploys to a V1 workspace to maintain backwards
                    compatability with current Salesforce embedded solution
##################################################################>
Param
(
    [Parameter(Mandatory=$true)][String]$deploymentPwd, 
    [Parameter(Mandatory=$true)][String]$environment,   
    [Parameter(Mandatory=$true)][String]$reportFolder,
    [Parameter(Mandatory=$true)][String]$datasourceObjectId,
    [Parameter(Mandatory=$true)][String]$deploymentUser,
    [Parameter(Mandatory=$true)][String]$gatewayId,
    [Parameter(Mandatory=$true)][String]$groupIdV1Workspace,
    [Parameter(Mandatory=$false)][String]$groupIdV2Workspace,
    [Parameter(Mandatory=$true)][String]$pipelineId,
    [Parameter(Mandatory=$true)][String]$targetDataSourceServerName,
    [Parameter(Mandatory=$true)][String]$stageOrder
)
Install-Module MicrosoftPowerBIMgmt.Profile -Force
Install-Module MicrosoftPowerBIMgmt.Reports -Force
Import-Module MicrosoftPowerBIMgmt.Profile
Import-Module MicrosoftPowerBIMgmt.Reports

 $targetDatasourceServer =  @{SlalomBITabular = $targetDataSourceServerName};
 $datasourceObjectIds = @($datasourceObjectId);



function New-DITPowerBIReport($outfile, $workspaceId, $filename) 
{
 
    Try
    {
        $reportDetail = New-PowerBIReport -Path "$outfile" -WorkspaceId $workspaceId -Name "$filename" -ConflictAction CreateOrOverwrite
    }   
    Catch
    {
        $PSItem.Exception.Message
        $PSItem.Exception.InnerExceptionMessage
        $PSItem.InvocationInfo | Format-List *
         throw       
    } 
        
    Write-Output "$filename deployed"           
    return $reportDetail

}


function Get-DITReportInGroup($workspaceId, $reportId) 
{
    Write-Output "Getting reportDetails for ID $reportId"
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/reports/$reportId"
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
    return $response

}


function Get-DITDatasetsInGroup($groupId) 
{
    Write-Output "Getting dataset list"
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets"
    Write-Output "Running: $uri"
    Try
    {
        $response = Invoke-RestMethod -Headers $headers -Uri $uri
        $datesets = $response.value
    }
    Catch
    {
        $PSItem.Exception.Message
        $PSItem.Exception.InnerExceptionMessage
        $PSItem.InvocationInfo | Format-List *
        throw
    }
    return $datesets

}


function Set-DITDatasetTakeOverInGroup($groupId, $datasetId) 
{
    Write-Output "Taking over dataset $datasetId"
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets/$datasetId/Default.TakeOver"
    Write-Output "Running: $uri"
    try
    {
        $response = Invoke-RestMethod -Headers $headers -Uri $uri -Method 'Post'
    }
    Catch
    {
        $PSItem.Exception.Message
        $PSItem.Exception.InnerExceptionMessage
        $PSItem.InvocationInfo | Format-List *
        throw
    }

    Write-Output "Dataset $datasetId taken over"
    return $response
}


function Update-DITDatasourcesInDataset ($groupId, $datasetId, $targetDatasourceServer) 
{
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets/$datasetId/datasources" 
    Write-Output "Running: $uri"
    $response = Invoke-RestMethod -Headers $headers -Uri $uri
    $response.value

 
    $datasources = $response.value
    Write-Output "Found $($datasources.Count) Datasource Connection(s) for dataset"

    $updateDetails = @()
    $needUpdate = $false

    foreach($datasource in $datasources) {
        $currentDatasource = $datasource
        $currentDatasourceConnectionDetails = $currentDatasource.connectionDetails
        Write-Output "Current Datasource Connection Server: $($currentDatasourceConnectionDetails.server)"
        Write-Output "Current Datasource Connection Database: $($currentDatasourceConnectionDetails.database)"

        $newDatasourceConnectionDetails = $currentDatasourceConnectionDetails.PsObject.Copy()

        # Lookup key matching current database name to return target server to override with
        if( $targetDatasourceServer.ContainsKey($currentDatasourceConnectionDetails.database) ){
            $newDatasourceConnectionDetails.server = $targetDatasourceServer[$currentDatasourceConnectionDetails.database]
            Write-Output "New Datasource Connection Server: $($newDatasourceConnectionDetails.server)"
            Write-Output "New Datasource Connection Database: $($newDatasourceConnectionDetails.database)"
        }
        else {
            Write-Output "No Entry in Replacement Lookup table for '$($newDatasourceConnectionDetails.database)'"
            Write-Output "Leaving Current Datasource Connection As-Is"
        }

        $updateDetail = @{ datasourceSelector = $currentDatasource; connectionDetails = $newDatasourceConnectionDetails }

        #$updateDetail | ConvertTo-Json -Depth 10

        $updateDetails += $updateDetail

        # Check if DatasourceConnectionDetails changed and update is needed
        if ($(Compare-Object $currentDatasourceConnectionDetails $newDatasourceConnectionDetails -Property database, server, url).Length -ne 0) {
            $needUpdate = $true
        }

    }

    if ($needUpdate) {
        Write-Output 'DatasourceConnectionDetails changed and update is needed'
    
        $requestBody = @{updateDetails=$updateDetails} | ConvertTo-Json -Depth 10
        #$requestBody | ConvertTo-Json -Depth 10
    
        # Update Datasources In Group

        $uri = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets/$datasetId/Default.UpdateDatasources"
        Write-Output "Running: $uri"
        Try
        {
            $response = Invoke-RestMethod -Headers $headers -Uri $uri -Body $requestBody -Method 'Post' -ContentType 'application/json' 
            Write-Output 'DatasourceConnectionDetails updated'
        }
        Catch
        {
            Write-Error $_
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $responseBody = $reader.ReadToEnd();
            $responseBody
            throw
        }

    }
    else {
        Write-Output 'DatasourceConnectionDetails did not change, no update is needed'
    }


}


function Set-DITBindToGateway($groupId, $bodyParmsJson, $datasetId) 
{
            
    
   
    Write-Output "Binding dataset $datasetId to gateway"
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets/$datasetId/Default.BindToGateway"
    Write-Output "Running: $uri"
    try
    {
        $response = Invoke-RestMethod -Headers $headers -Uri $uri -Method 'Post' -Body $bodyParmsJson -ContentType 'application/json' 
    }
    Catch
    {
                
       
       
        $PSItem.Exception.Message
        $PSItem.Exception.InnerExceptionMessage
        $PSItem.InvocationInfo | Format-List *
        throw
    }

    Write-Output "Bind to Gateway successful"           
    return $response

}



function Set-DITPipelineDeployAll($pipelineId, $stageOrder) 
{
               
   
    Write-Output "Deploying pipeline stage artifacts"
    $requestBody = @"
{
  "sourceStageOrder": $stageOrder,
  "updateAppSettings":{
  "updateAppInTargetWorkspace": true
  },
  "options": {
    "allowOverwriteArtifact": true,
    "allowCreateArtifact": true
  }
}
"@

    $uri = "https://api.powerbi.com/v1.0/myorg/pipelines/$pipelineId/deployAll"
    Write-Output "Running: $uri"
    try
    {
        $response =   Invoke-RestMethod  -Headers $headers -Uri $uri -Method 'Post'    -Body $requestBody  -ContentType 'application/json' 
    }
    Catch
    {
        $PSItem.Exception.Message
        $PSItem.Exception.InnerExceptionMessage
        $PSItem.InvocationInfo | Format-List *
        throw
    }

    Write-Output "Pipeline stage deployed"           
    return $response

}


Write-Output 'Connecting to PowerBI API'
$password = ConvertTo-SecureString $deploymentPwd -AsPlainText -Force -Verbose
$credential = New-Object System.Management.Automation.PSCredential ($deploymentUser, $password)  -Verbose
Connect-PowerBIServiceAccount -Credential $credential
$headers = Get-PowerBIAccessToken


Write-Output "Deploying and configuring to V1 Workspace"
$files = Get-ChildItem $reportFolder
foreach ($f in $files) 
{
    Write-Output "Deploying $f.Name"
    $report = New-DITPowerBIReport $f.FullName $groupIdV1Workspace  $f.Name
    $reportId = $report.Id  

    Write-Output "Getting datasetID"
    $reportFullDetail = Get-DITReportInGroup $groupIdV1Workspace  $reportId
    $datasetId = $reportFullDetail.datasetId

    Write-Output "Take over dataset $datasetId"
    Set-DITDatasetTakeOverInGroup $groupIdV1Workspace $datasetId $headers

    Write-Output "Updatingdatasources as appropriate"
    Update-DITDatasourcesInDataset $groupIdV1Workspace $datasetId $targetDatasourceServer

    Write-Output "Binding datasources to gateway"
    $bodyParms = @{ "gatewayObjectId" = "$gatewayId"} 
    $bodyParms += @{"datasourceObjectIds" = $datasourceObjectIds}
    $bodyParmsJson = $bodyParms|ConvertTo-Json
    Set-DITBindToGateway $groupIdV1Workspace $bodyParmsJson $datasetId
        
}


if ($environment -eq  "Development")
{
    Write-Output "Deploying and configuring to V2 Workspace"
    $files = Get-ChildItem $reportFolder
    foreach ($f in $files) 
    {
        Write-Output "Deploying $f.Name"
        $report = New-DITPowerBIReport $f.FullName $groupIdV2Workspace  $f.Name
        $reportId = $report.Id  

        Write-Output "Getting datasetID"
        $reportFullDetail = Get-DITReportInGroup $groupIdV2Workspace  $reportId
        $datasetId = $reportFullDetail.datasetId

        Write-Output "Take over dataset $datasetId"
        Set-DITDatasetTakeOverInGroup $groupIdV2Workspace $datasetId $headers

        Write-Output "Updatingdatasources as appropriate"
        Update-DITDatasourcesInDataset $groupIdV2Workspace $datasetId $targetDatasourceServer

        Write-Output "Binding datasources to gateway"
        $bodyParms = @{ "gatewayObjectId" = "$gatewayId"} 
        $bodyParms += @{"datasourceObjectIds" = $datasourceObjectIds}
        $bodyParmsJson = $bodyParms|ConvertTo-Json
        Set-DITBindToGateway $groupIdV2Workspace $bodyParmsJson $datasetId
       
    }
}
Write-Output "Deploy to next stage in pipeline"
$response =  Set-DITPipelineDeployAll $pipelineId  $stageOrder 

Write-Output "Publish Reports complete!"




