Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue

#Where to Download the files to. Sub-folders will be created for the documents and lists, respectively.
$destination = "C:\PSExports\folder\"

#The site to extract from. Make sure there is no trailing slash.
$site = "https://ys/sites/test"

$web1 = Get-SPWeb "https://ys/sites/test/test2/"

$Libraries = $web1.Lists



# $DownloadPath: The destination to download to

function HTTPDownloadFile($ServerFileLocation, $DownloadPath) {
	$webclient = New-Object System.Net.WebClient
	$webClient.UseDefaultCredentials = $true
	$webclient.DownloadFile($ServerFileLocation, $DownloadPath)
}

function DownloadMetadata($sourceweb, $metadatadestination) {
	Write-Host "Creating Lists and Metadata"
	$sourceSPweb = Get-SPWeb -Identity $sourceweb
	$metadataFolder = $destination + "\" + $sourceSPweb.Title + " Lists and Metadata"
	$createMetaDataFolder = New-Item $metadataFolder -type directory 
	$metadatadestination = $metadataFolder

	foreach ($list in $sourceSPweb.Lists) {
		Write-Host "Exporting List MetaData: " $list.Title
		$ListItems = $list.Items 
		$Listlocation = $metadatadestination + "\" + $list.Title + ".csv"
		$ListItems | Select * | Export-Csv $Listlocation  -Force
	}
}

# Function: GetFileVersions
# Description: Downloads all versions of every file in a document library
# Variables
# $WebURL: The URL of the website that contains the document library
# $DocLibURL: The location of the document Library in the site
# $DownloadLocation: The path to download the files to

function GetFileVersions($file) {
	foreach ($version in $file.Versions) {
		#Add version label to file in format: [Filename]_v[version#].[extension]
		$filesplit = $file.Name.split(".") 
		$fullname = $filesplit[0] 
		$fileext = $filesplit[1] 
		$FullFileName = $fullname + "_v" + $version.VersionLabel + "." + $fileext			

		#Can't create an SPFile object from historical versions, but CAN download via HTTP
		#Create the full File URL using the Website URL and version's URL
		$fileURL = $webUrl + "/" + $version.Url

		#Full Download path including filename
		$DownloadPath = $destinationfolder + "\" + $FullFileName

		#Download the file from the version's URL, download to the $DownloadPath location
		HTTPDownloadFile "$fileURL" "$DownloadPath"
	}
}

# Function: DownloadDocLib
# Description: Downloads a document library's files; called GetGileVersions to download versions.
# Variables
# $folderUrl: The Document Library to Download
# $DownloadPath: The destination to download to
function DownloadDocLib($folderUrl) {
	$folder = $web.GetFolder($folderUrl)
	foreach ($file in $folder.Files) {
		#Ensure destination directory
		$destinationfolder = $destination + "\" + $folder.Url 
		if (!(Test-Path -path $destinationfolder)) {
			$dest = New-Item $destinationfolder -type directory 
		}

		#Download file
		$binary = $file.OpenBinary()
		$stream = New-Object System.IO.FileStream($destinationfolder + "\" + $file.Name), Create
		$writer = New-Object System.IO.BinaryWriter($stream)
		$writer.write($binary)
		$writer.Close()

		#Download file versions. If you don't need versions, comment the line below.
		GetFileVersions $file
	}
}

# Function: DownloadSite
# Description: Calls DownloadDocLib recursiveley to download all document libraries in a site.
# Variables
# $webUrl: The URL of the site to download all document libraries
function DownloadSite($webUrl) {
	$web = Get-SPWeb -Identity $webUrl

	#Create a folder using the site's name
	$siteFolder = $destination + "\" + $web.Title + " Documents"
	$createSiteFolder = New-Item $siteFolder -type directory 
	$destination = $siteFolder



	foreach ($list in $web.Lists) {
		if ($list.BaseType -eq "DocumentLibrary") {
			Write-Host "Downloading Document Library: " $list.Title
			$listUrl = $web.Url + "/" + $list.RootFolder.Url
			#Download root files
			DownloadDocLib $list.RootFolder.Url
			#Download files in folders
			foreach ($folder in $list.Folders) {
				DownloadDocLib $folder.Url
			}
		}
	}

	#=======================================================================



	#=========================================================================

}

#Download Site Documents + Versions
#DownloadSite "$site"

#Download Site Lists and Document Library Metadata
DownloadMetadata $site $destination