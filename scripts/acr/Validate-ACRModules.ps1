$modules = Get-ChildItem $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY -Include *.bicep -Recurse # only include the files with type of .bicep
foreach ($module in $modules) {
    bicep build $module.FullName
}