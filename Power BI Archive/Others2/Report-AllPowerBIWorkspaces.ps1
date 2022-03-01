# this script requires user to be Power BI Service administrator or global tenant admin
# Requires Install-Module MicrosoftPowerBIMgmt.Workspaces
Write-Host

Connect-PowerBIServiceAccount | Out-Null
$outputRoot = '.\PowerBIReport'
$outputFile = ".\PBIWorkspaceReport-2.csv"

# adding -Scope Organization is what requires admin permissions
$AllWorkspaces = Get-PowerBIWorkspace -Scope Organization -Filter "state eq 'Active'" -All -Include All 
$AllWorkspaces | Select-Object `
    Id,Name,IsReadOnly,IsOnDedicatedCapacity,CapacityId,Description,Type,State,IsOrphaned,`
    @{Name=“Users”;Expression={($_.Users | select *).UserPrincipalName -join "|"}},`
    @{Name=“Reports”;Expression={($_.Reports | Select *).Name  -join "|"}},`
    @{Name=“Dashboards”;Expression={($_.Dashboards | Select *).Name  -join "|"}}, `
    @{Name=“Datasets”;Expression={($_.Datasets | Select *).Name  -join "|"}}, `
    @{Name=“Dataflows”;Expression={($_.Dataflows | Select *).Name  -join "|"}}, `
    @{Name=“Workbooks”;Expression={($_.Workbooks | Select *).Name -join "|"}}`
    | Export-Csv -Path "$outputRoot-Inventory.csv" -NoTypeInformation




