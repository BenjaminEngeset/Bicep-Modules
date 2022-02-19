$version = get-date -Format yyyy-MM-dd

# get the latest files changed
$files = $(git diff HEAD HEAD~ --name-only modules/) | select-string -Pattern '.bicep$'
if ($files.count -ge 1) {
  # copy files to staging
  foreach ($file in $files) {
    $folderPath = Split-Path -Path $file -Parent
    $null = New-Item -ItemType Directory -Path (Join-Path $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY $folderPath) -Force
    Copy-Item $file -Destination (Join-Path $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY $file) -Force
  }

  # output the variable to be used in the next stage in the pipeline
  Write-Host ("##vso[task.setvariable variable=bicepFiles;isOutput=true]true") 
  # set the variable in this stage for the rest of the tasks
  Write-Host ("##vso[task.setvariable variable=bicepFiles]true")
  # update the build number in DevOps
  write-host ("##vso[build.updatebuildnumber]${version}")
}

else {
  # output the variable to be used in the next stage in the pipeline
  Write-Host ("##vso[task.setvariable variable=bicepFiles;isOutput=true]false")
  # set the variable in this stage for the rest of the tasks
  Write-Host ("##vso[task.setvariable variable=bicepFiles]false")
  # update the build number in DevOps
  write-host ("##vso[build.updatebuildnumber]${version}")
} 