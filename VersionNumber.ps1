Param (
    [string]$build_num = "1",
	[string]$version_file_mask = "AssemblyInfo.cs"
)

 function Get-GitVersion
 { 
     $git_version = (git describe --tags --long --match 'v?.?' | Select-String -pattern '(?<major>[0-9]+)\.(?<minor>[0-9]+)-(?<seq>[0-9]+)-(?<hash>[a-z0-9]+)').Matches[0].Groups
     return $git_version
 }

function Update-AssemblyVersion
{
    Param (
        [string]$version
    )

    foreach ($o in $input) 
    {
        Write-Host "Updating  '$($o.FullName)' -> $version"
    
        $assemblyVersionPattern = 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
        $fileVersionPattern = 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
        $assemblyVersion = 'AssemblyVersion("' + $version + '")';
        $fileVersion = 'AssemblyFileVersion("' + $version + '")';
        
        (Get-Content $o.FullName) | ForEach-Object  { 
           % {$_ -replace $assemblyVersionPattern, $assemblyVersion } |
           % {$_ -replace $fileVersionPattern, $fileVersion }
        } | Out-File $o.FullName -encoding UTF8 -force
    }
}


 # Retrive Git Version Number
Write-Host "Resolving Git Version"
$git_version = Get-GitVersion

$git_describe = $git_version[0].Value 
Write-Host "Git Version is '$git_describe'"

# Get TFS Build Version
$VSTSversion = $env:BUILD_BUILDID
$MajorVersion = $env:MajorVersion
$MinorVersion = $env:MinorVersion
$SprintNumber = $env:SprintNumber
Write-Host "Build ID is: " $VSTSversion

# Prepare version numbers
$version = [string]::Join('.', @($MajorVersion, $MinorVersion, $SprintNumber, $VSTSversion))

# Update AssemblyInfo.cs file
$fileRootFolder = (get-item $PSScriptRoot ).parent.FullName
Write-Host "Searching '$fileRootFolder'"
Get-ChildItem $fileRootFolder -recurse |? {$_.Name -eq $version_file_mask} | Update-AssemblyVersion $version

# TFS - update the running package version
Write-Host ("##vso[task.setvariable variable=BUILD.BUILDNUMBER;]$version")
Write-Host "BUILD_BUILDNUMBER: " $env:BUILD_BUILDNUMBER

Write-Host ("##vso[build.updatebuildnumber]$version")
Write-Host "BUILD_BUILDNUMBER: " $env:BUILD_BUILDNUMBER

Write-Host ("##vso[task.setvariable variable=packageversion;]$version")
Write-Host "PackageVersion: " $env:packageversion