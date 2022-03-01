<#
.Synopsis
    Imports all the dataflow model.json from a folder into a Power BI workspace.
.Description
    Imports all the dataflow model.json from a folder into a Power BI workspace. The script also chains all the reference models in the same workspace correctly.
    The scripts rely on the format used by ExportWorkspace.ps1 in order to fix the reference model paths correctly.This script will fail if the target workspace does not exist.
    This script uses the Power BI Management module for Windows PowerShell. If this module isn't installed, install it by using the command 'Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser'.
.Parameter Workspace
    [Required] The name of the workspace you'd like to import all the dataflows from
.Parameter Location
    [Required] Folder path where the model files are located.
.Parameter Overwrite
    [Optional]: A flag to indicate whether to overwrite a model with the same name if it exists. Default is false
.Parameter Environment
    [Optional]: A flag to indicate specific Power BI environments to log in to (Public, Germany, USGov, China, USGovHigh, USGovMil). Defailt is Public
.Parameter V
    [Optional]: A flag to indicate whether to produce verbose output. Default is false
.Example
    PS C:\> .\ImportWorkspace.ps1 -Workspace "Workspace1" -Folder C:\dataflows -Overwrite
	Imports all the dataflows from the folder C:\dataflows into the Power BI workspace "Workspace1"
#>

Using module ".\Graph.psm1"

param (
    [Parameter(Mandatory=$true)]
    [string] $Workspace,
    [Parameter(Mandatory=$true)]
    [string] $Location,
    [Parameter(Mandatory=$false)]
    [switch]$Overwrite = $false,
	[Parameter(Mandatory=$false)]
    [string] $Environment,
    [Parameter(Mandatory=$false)]
    [switch]$v = $false
)
Begin
{
#region Initialization
    $ErrorActionPreference="SilentlyContinue"
    Stop-Transcript | out-null
    $ErrorActionPreference = "Continue"

    Import-Module (Join-Path $PSScriptRoot DFUtils.psm1) -Force
    Import-Module (Join-Path $PSScriptRoot Graph.psm1) -Force
    DFLogMessage("SetVerbose : $v")
    SetVerbose($v)
#endregion
}
Process
{
    # Login to PowerBi and fetch the workspace id
    DFLogMessage("Overwrite : $Overwrite")
    DFLogMessage("Location : $Location")
    LoginPowerBi($Environment)
	$workspaceId = GetWorkspaceIdFromName($Workspace)
    $dataflows = GetDataflowsForWorkspace($workspaceId)
    
    # Verifies the output folder
    DFLogMessage("Verifying location : $Location")
    VerifyDirectory($Location)
    
    # Read all files and construct the graph
    $graph = New-Object DFGraph;
    $modelJsonFiles = Get-ChildItem $Location -Filter *.json
    foreach ($modelJsonFile in $modelJsonFiles) 
    {
        $modelId =  $modelJsonFile.Basename
        $modelJson = ReadModelJson($modelJsonFile.FullName)
        $graph.AddNode($modelId, $modelJson)
    }

    # Add the graph edges
    foreach ($modelNode in $graph.Nodes.Values) 
    {
        $modelId = $modelNode.Id
        $referenceModels = GetReferenceModels($modelNode.Data)
        foreach ($referenceModel in $referenceModels) 
        {
            if ($null -eq $graph.Nodes[$referenceModel.DataflowId])
            {
                DFLogWarning("Model $modelId may not import successfully since it has dependency on model " + $referenceModel.DataflowId + "which does not exist in the folder")
            }
            else
            {
                DFLogMessage("Reference: $modelId => " + $referenceModel.DataflowId)
                $graph.AddEdge($referenceModel.DataflowId, $modelId)   
            }
        }
    }

    # Find the topological sort and start import in that order
    $sortedModels = $graph.TopologicalSort()
    $referenceReplacements = @{}
    foreach ($modelNode in $sortedModels) 
    {
        $modelName = $modelNode.Data.Name
        DFLogMessage("Importing: " + $modelNode.Id + " " + $modelName)

        # Fix reference
        $json = $modelNode.Data
        foreach ($replacementModelId in $referenceReplacements.Keys)
        {
            FixReference $json $replacementModelId $workspaceId $referenceReplacements[$replacementModelId].objectId 
        }

        # Import the dataflow
        $overwriteModelId = GetOverrwiteModelId $dataflows  $Overwrite  $modelName
        $importedDataflow = ImportModel $workspaceId  $overwriteModelId  $json $dataflows
        DFLogMessage("Old Id= " + $modelNode.Id + "Imported dataflow id= " + $importedDataflow.objectId + " Name= " + $importedDataflow.name)
        $referenceReplacements[$modelNode.Id] = $importedDataflow
        if ($null -eq $dataflows[$importedDataflow.objectId])
        {
            DFLogMessage("New dataflow id= " + $importedDataflow.objectId + " Name= " + $importedDataflow.name)
            $dataflows[$importedDataflow.objectId] = $importedDataflow
        }
    }
}
End
{
    DFLogMessage("ImportWorkspace completed")
}