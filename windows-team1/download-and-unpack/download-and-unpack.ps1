Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$URL,

    [Parameter(Mandatory=$True,Position=2)]
    [string]$UnpackTo
)

$ErrorActionPreference = 'Stop' 
Write-Host "##teamcity[blockOpened name='Download']"

$tmp = $env:TEMP

$url_extension = $URL.Split('.')[-1]
if ($url_extension -eq "zip"){
    # Prepare
    $zip_name = $URL.Split('/')[-1]
    $zip_fullname = "$tmp\$zip_name"

    # Download
    Write-Host "Download $URL to $zip_fullname"
    $wc = New-Object net.webclient
    $wc.Downloadfile($URL, $zip_fullname)

    # Unpack
    Write-Host "Unpack $zip_fullname to $UnpackTo"
    Expand-Archive $zip_fullname $UnpackTo
}

Write-Host "##teamcity[blockOpened name='Clean']"
Remove-Item $env:temp\* -Force -Verbose -Recurse
Write-Host "##teamcity[blockClosed name='Clean']"

Write-Host "##teamcity[blockClosed name='Download']"
