[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
 
#Using Get-SPSite in MOSS 2007
function global:Get-SPSite($url) {
    return new-Object Microsoft.SharePoint.SPSite($url)
}
 
function global:Get-SPWeb($url) {
    $site = New-Object Microsoft.SharePoint.SPSite($url)
    if ($site -ne $null) {
        $web = $site.OpenWeb();       
    }
    return $web
}
 
$URL = "https://yoursite/sites/Site1/"
  
$site = Get-SPSite $URL
    
#Write the Header to "Tab Separated Text File"
"Site Name`t  URL `t Group Name `t User Account `t User Name `t E-Mail" | out-file "C:\PSExports\JS_Users.csv"
         
#Iterate through all Webs
foreach ($web in $site.AllWebs) {
    #Write the Header to "Tab Separated Text File"
    "$($web.title) `t $($web.URL) `t  `t  `t `t " | out-file "C:\PSExports\JS_Users.csv" -append
    #Get all Groups and Iterate through    
    foreach ($group in $Web.groups) {
        "`t  `t $($Group.Name) `t   `t `t " | out-file "C:\PSExports\JS_Users.csv" -append
        #Iterate through Each User in the group
        foreach ($user in $group.users) {
            #Exclude Built-in User Accounts
            if (($User.LoginName.ToLower() -ne "nt authority\authenticated users") -and ($User.LoginName.ToLower() -ne "sharepoint\system") -and ($User.LoginName.ToLower() -ne "nt authority\local service")) {
                "`t  `t  `t  $($user.LoginName)  `t  $($user.name) `t  $($user.Email)" | out-file "C:\PSExports\JSOX_Users.csv" -append
            }
        } 
    }
}
