Add-PSSnapin Microsoft.SharePoint.PowerShell –ErrorAction SilentlyContinue

#Location to download all files
$Location = "D:\SP13_Archival\folder"

#Read CSV file
$CSVData = Import-CSV -path "D:\SP13_Archival\folder\ArchiveList.csv"

foreach ($row in $CSVData) {
    
    #Variables
    $SiteUrl = $row.SiteURL
    $ListName = $row.ListLibraryName
    $FolderPrefix = $row.Prefix
    $DownloadLocation = $Location + "\" + $FolderPrefix + "_" + $ListName
    $OutPutFile = $DownloadLocation + "\" + $ListName + ".csv"

    if (!(Test-Path -path $DownloadLocation)) {
        $dest = New-Item $DownloadLocation -type directory 
    }

 
    #Get the web
    $Web = Get-SPWeb $SiteUrl
    $List = $Web.Lists[$ListName]

    If ($List.BaseType -eq "DocumentLibrary")  
    #If($row.Type -eq "Library")
    {
        Download-SPDocumentLibrary $SiteURL $ListName $DownloadLocation
    }
    
    else {
        #ExportList $SiteURL $ListName $DownloadLocation $OutPutFile

        Write-host "Total Number of Items Found:"$List.Itemcount
 
        #Array to Hold Result - PSObjects
        $ListItemCollection = @()
   
        #Get All List items 
        $List.Items | ForEach {
            write-host "Processing Item ID:"$_["ID"]
  
            $ExportItem = New-Object PSObject 
            #Get Each field
            foreach ($Field in $_.Fields) {
                $ExportItem | Add-Member -MemberType NoteProperty -name $Field.InternalName -value $_[$Field.InternalName]  
            }
            #Add the object with property to an Array
            $ListItemCollection += $ExportItem
 
        }    

        #Export the result Array to CSV file
        $ListItemCollection | Export-CSV $OutPutFile -NoTypeInformation
        Write-host -f Green "List '$ListName' Exported to $($OutputFile) for site $($SiteURL)"
    }

}



Function Download-SPFolder($SPFolderURL, $DownloadPath) {
    Try {
        #Get the Source SharePoint Folder
        $SPFolder = $web.GetFolder($SPFolderURL)
  
        $DownloadLocation = Join-Path $DownloadLocation $SPFolder.Name 
        #Ensure the destination local folder exists! 
        If (!(Test-Path -path $DownloadLocation)) {    
            #If it doesn't exists, Create
            $LocalFolder = New-Item $DownloadLocation -type directory 
        }
  
        #Loop through each file in the folder and download it to Destination
        ForEach ($File in $SPFolder.Files) {
            #Download the file
            $Data = $File.OpenBinary()
            $FilePath = Join-Path $DownloadLocation $File.Name
            [System.IO.File]::WriteAllBytes($FilePath, $data)
            Write-host -f Green "`tDownloaded the File:"$File.ServerRelativeURL         
        }
  
        #Process the Sub Folders & Recursively call the function
        ForEach ($SubFolder in $SPFolder.SubFolders) {
            
            #Leave "Forms" Folder
            If ($SubFolder.Name -ne "Forms") {
                #Call the function Recursively
                Download-SPFolder $SubFolder $DownloadLocation
            }
        }
    }
    
    Catch {
        Write-host -f Red "Error Downloading Document Library:" $_.Exception.Message
    }  
}
 
#Main Function
Function Download-SPDocumentLibrary($SiteURL, $ListName, $DownloadLocation) {
    Try {
       
        #Get the document Library to Download
        $Library = $Web.Lists[$ListName]
        Write-host -f magenta "Downloading Document Library:" $Library.Title
 
        #Call the function to download the document library
        Download-SPFolder -SPFolderURL $Library.RootFolder.Url -DownloadPath $DownloadLocation
 
        Write-host -f Green "*** Download Completed  ***"
    }

    Catch {
        Write-host -f Red "Error Downloading Document Library:" $_.Exception.Message
    }  
}