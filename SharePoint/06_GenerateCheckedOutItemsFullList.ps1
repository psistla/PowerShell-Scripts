# enter your site URL
$spWeb = Get-SPWeb "https://ys/sites/test/"
$CSVFile = "C:\PSExports\JS-CheckedOutItemsFullList.csv"

function GetCheckedItems($spWeb) {
    Write-Host "Scanning Site: $($spWeb.Url)"
    foreach ($list in ($spWeb.Lists | ? { $_ -is [Microsoft.SharePoint.SPDocumentLibrary] })) {
        Write-Host "Scanning List: $($list.RootFolder.ServerRelativeUrl)"
        foreach ($item in $list.CheckedOutFiles) {
            if (!$item.Url.EndsWith(".aspx")) { continue }
            $writeTable = @{
                "URL"               = $spWeb.Site.MakeFullUrl("$($spWeb.ServerRelativeUrl.TrimEnd('/'))/$($item.Url)");
                "Checked Out By"    = $item.CheckedOutBy;
                "Author"            = $item.File.CheckedOutByUser.Name;
                "Checked Out Since" = $item.CheckedOutDate.ToString();
                "File Size (KB)"    = $item.File.Length / 1000;
                "Email"             = $item.File.CheckedOutByUser.Email;
            }
            New-Object PSObject -Property $writeTable
        }
        foreach ($item in $list.Items) {
            if ($item.File.CheckOutStatus -ne "None") {
                if (($list.CheckedOutFiles | where { $_.ListItemId -eq $item.ID }) -ne $null) { continue }
                $writeTable = @{
                    "URL"               = $spWeb.Site.MakeFullUrl("$($spWeb.ServerRelativeUrl.TrimEnd('/'))/$($item.Url)");
                    "Checked Out By"    = $item.File.CheckedOutByUser.LoginName;
                    "Author"            = $item.File.CheckedOutByUser.Name;
                    "Checked Out Since" = $item.File.CheckedOutDate.ToString();
                    "File Size (KB)"    = $item.File.Length / 1000;
                    "Email"             = $item.File.CheckedOutByUser.Email;
                    "Name"              = $item.Name;
                }
                New-Object PSObject -Property $writeTable
            }
        }
    }
    foreach ($subWeb in $spWeb.Webs) {
        GetCheckedItems($subWeb)
    }
    $spWeb.Dispose()
}
 
#GetCheckedItems($spWeb) | Out-GridView
GetCheckedItems($spWeb) -Limit ALL | Export-CSV $CSVFile -NoTypeInformation


# alternative output file
# GetCheckedItems($spWeb) | Out-File c:\CheckedOutItems.txt -width 300