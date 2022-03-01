Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Configuration parameters
$SiteURL = "https://yoursite/sites/test/"
$ReportOutput = "C:\PSExports\WebPartsInUse.csv"
 
$ResultCollection = @()
 
#Get All Subsites in a site collection and iterate through each
$Site = Get-SPSite $SiteURL
ForEach ($Web in $Site.AllWebs) {
    write-host Processing $Web.URL
    # If the Current Web is Publishing Web
    if ([Microsoft.SharePoint.Publishing.PublishingWeb]::IsPublishingWeb($Web)) {
        #Get the Publishing Web 
        $PubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($Web)
                   
        #Get the Pages Library
        $PagesLib = $PubWeb.PagesList
    }
    else {
        $PagesLib = $Web.Lists["Site Pages"]
    }             
    #Iterate through all Pages  
    foreach ($Page in $PagesLib.Items | Where-Object { $_.Name -match ".aspx" }) {
        $PageURL = $web.site.Url + "/" + $Page.File.URL
        $WebPartManager = $Page.File.GetLimitedWebPartManager([System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
                 
        #Get All Web Parts data
        foreach ($WebPart in $WebPartManager.WebParts) {
            $Result = New-Object PSObject
            $Result | Add-Member -type NoteProperty -name "Site URL" -value $web.Url
            $Result | Add-Member -type NoteProperty -name "Page URL" -value $PageURL
            $Result | Add-Member -type NoteProperty -name "Web Part Title" -value $WebPart.Title
            $Result | Add-Member -type NoteProperty -name "Web Part Type" -value $WebPart.GetType().ToString()
 
            $ResultCollection += $Result
        }
    }
}
#Export results to CSV
$ResultCollection | Export-csv $ReportOutput -notypeinformation
