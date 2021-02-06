$TempFolder = "$env:windir\Temp\AGPO"
if (!(Test-Path $TempFolder)) {
    New-Item $TempFolder -ItemType Directory -Force
    if (!$?) {
        Write-Host "Unable to create temp folder" -ForegroundColor Red
        Exit 2
    }
}

$DeployFolder = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)"
Write-Host "Copying $DeployFolder to local cache in $TempFolder"
Copy-Item "$DeployFolder\*" "$TempFolder\" -Recurse -Force
Write-Host "Number of Arguments $($args.Count)"
switch ($args.Count) {
    0 {
        # Only PartnerConfig.xml values will be used
        & "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File $TempFolder\InstallAgent.ps1 -LauncherPath $DeployFolder"
        break
    }
    1 {
        # CustomerID from script parameter has preference over PartnerConfig.xml, will failback to PartnerConfig.xml
        & "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File $TempFolder\InstallAgent.ps1 -CustomerID $($args[0]) -LauncherPath $DeployFolder"
        break
    }
    2 {
        # Partner token from script parameter has preference over PartnerConfig.xml, will failback to partnerconfig.xml
        & "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File $TempFolder\InstallAgent.ps1 -CustomerID $($args[0]) -RegistrationToken $($args[1]) -LauncherPath $DeployFolder"
        break
    }
}
# Successfully launched...
if (!$?) {
    Write-Host "Successfully launched InstallAgent script"
}
else {
    Write-Host "Error launching InstallAgent" -ForegroundColor Red
}
