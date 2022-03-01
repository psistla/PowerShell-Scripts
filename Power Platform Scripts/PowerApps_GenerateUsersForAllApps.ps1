# Log in to Power Apps (Power Platform Administartor)

ConnectPowerApps
#Add-PowerAppsAccount

$powerApps = Get-AdminPowerApp 

$powerappusers = @()


ForEach ($powerApp in $powerApps)
{
    ForEach ($powerappuser in (Get-PowerAppRoleAssignment -AppName $powerapp.AppName)) {
        $csvRow = @{
            App             = $powerapp.DisplayName
            AppId           = $powerapp.AppName
            User            = $powerappuser.PrincipalDisplayName
            Email           = $powerappuser.PrincipalEmail
            Role            = $powerappuser.RoleType
            AppLastModified = $powerapp.LastModifiedTime
        }

        $powerappusers += $(new-object psobject -Property $csvRow)
    }
}


$powerappusers | Export-Csv -Path "C:\PowerPlatform\PowerAppsUsers.csv" -NoTypeInformation
