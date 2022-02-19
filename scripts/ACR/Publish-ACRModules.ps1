[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $ContainerRegistry
)
$errors = @()
# set version tag in container registry
$version = Get-Date -Format yyyy-MM-dd

# get all the bicep files in the bicep artifact folder
$modules = Get-ChildItem -Path .\bicep -Filter *.bicep -Recurse

foreach ($module in $modules) {
    if ($IsLinux) {
        $name = $module.FullName -replace '.+(/bicep/)'
    } 
    if ($IsWindows) {
        $name = $module.FullName -replace '.+(\\bicep\\)' 
        $name = $name -replace '\\', '/' 
    } 
    if ($IsMacOS) {
        Write-Output "The script is only tested for Linux and Windows. Exiting..."
        throw
    }

    # set it to lowercase, remove the file extension
    $name = $name -replace '.bicep$'
    $target = "br:${ContainerRegistry}/modules/${name}:${version}"
    $target = $target.ToLower()

    # publish to container registry with a retry loop in case of error
    $stopLoop = $false
    $retries = 5
    $retryCount = 0
    
    do {
        bicep publish $module.FullName --target $target

        if ($LastExitCode -eq 0) {
            Write-Output "Publised ($retryCount): $target"
            $stopLoop = $true
        }
        else {
            if ($retryCount -eq $retries) {
                $stopLoop = $true
                $errors += "Unable to publish: $target"
            }
            else {
                Write-Output "Could publish $target, retrying in 30 seconds..."
                Start-Sleep -Seconds 30
                $retryCount++
            }
        }
    
    } While ($stopLoop -eq $false)

}

# terminate the script to fail the pipeline if one or more files was not uploaded to container registry
if ($errors.count -ne 0) {
    $errors
    throw
}
 