<#
.Synopsis
    Exports all the dataflow model.json from a Power BI workspace into a folder
.Description
    Exports all the dataflow model.json from a Power BI workspace into a folder. The format of the model files are
        <MODELID>.json
    The script will overwrite the file with the same name in the folder. It's important to keep the same name since ImportWorkspace.ps1 depends on the naming convention.
    This script will fail if the target workspace does not exist.
    This script uses the Power BI Management module for Windows PowerShell. If this module isn't installed, install it by using the command 'Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser'.
.Parameter Workspace
    [Required] The name of the workspace you'd like to export the dataflows from.
.Parameter Location
    [Required] Folder path where the model files will be saved.
.Parameter Environment
    [Optional]: A flag to indicate specific Power BI environments to log in to (Public, Germany, USGov, China, USGovHigh, USGovMil). Defailt is Public
.Parameter V
    [Optional]: A flag to indicate whether to produce verbose output. Default is false
.Example
    PS C:\> .\ExportWorkspace.ps1 -Workspace "Workspace1" -Folder C:\dataflows
	Exports all the dataflows from the Power BI workspace "Workspace1" in to the folder C:\dataflows in the model.json format.
#>

Using module ".\Graph.psm1"

param (
    [Parameter(Mandatory=$true)]
    [string] $Workspace,
    [Parameter(Mandatory=$true)]
    [string] $Location,
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
    DFLogMessage("Workspace : $Workspace")
    DFLogMessage("Location : $Location")

    # Login to PowerBi and fetch the workspace id
    LoginPowerBi($Environment)
	$workspaceId = GetWorkspaceIdFromName($Workspace)
    $dataflows = GetDataflowsForWorkspace($workspaceId)

    # Create the output folder
    DFLogMessage("Verifying location : $Location")
    CreateDirectoryIfNotExists($Location)
    
    # Downloading all files
    foreach ($dataflow in $dataflows.Values) 
    {
        $modelJson = GetDataflow $workspaceId $dataflow.objectId $dataflow.name
        $outFile = Join-Path -Path $Location -ChildPath ($dataflow.objectId + ".json")
        DeleteFileIfExists($outFile)
        DFLogMessage("Copying dataflow [" + $dataflow.name + "] to file '$outFile'")
        $modelJson | ConvertTo-Json -Depth 100 | Out-File $outFile
        
        # Verify that all reference models are in the same workspace
        $referenceModels = GetReferenceModels($modelJson)
        foreach ($referenceModel in $referenceModels) 
        {
            DFLogMessage("Dataflow [" + $dataflow.name + "] references dataflow: [" + $referenceModel.WorkspaceId + "/" + $referenceModel.DataflowId + "]")
            if ($referenceModel.WorkspaceId -ne $workspaceId)
            {
                DFLogWarning("Dataflow [" + $dataflow.name + "] has dependency on another workspace id=" + $referenceModel.WorkspaceId + ".Import to a new workspace may not work ex expected")
            }
        }
    }
}
End
{
    DFLogMessage("ExportWorkspace completed")
}