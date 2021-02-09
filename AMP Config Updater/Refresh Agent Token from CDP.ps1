# RefreshToken
# $PartnerConfigFile = "C:\Windows\SYSVOL\domain\scripts\InstallAgent\PartnerConfig.xml"
if (Test-Path $PartnerConfigFile) {
    [xml]$xmlDocument = Get-Content -Path $PartnerConfigFile

    # Branding
    $xmlDocument.Config.Branding.ErrorContactInfo = $Branding

    # Server
    $xmlDocument.Config.Server.NCServerAddress = $NCServerAddress

    ### Deployment
    # LocalFolder, NetworkFolder
    $xmlDocument.Config.Deployment.LocalFolder = $LocalFolder
    $xmlDocument.Config.Deployment.NetworkFolder = $NetworkFolder

    # Typical
    $xmlDocument.Config.Deployment.Typical.SOAgentFileName = $SOAgentFileName
    $xmlDocument.Config.Deployment.Typical.SOAgentVersion = $SOAgentVersion
    $xmlDocument.Config.Deployment.Typical.SOAgentFileVersion = $SOAgentFileVersion
    # (Customer ID and Token)
    $xmlDocument.Config.Deployment.Typical.CustomerId = $CustomerId
    $xmlDocument.Config.Deployment.Typical.RegistrationToken = $RegistrationToken

    # AzNableProxy service by Kelvin Tegelaar
    # Azure is the more secure way to pass the Registration token. Check Kelvin's AzNableProxy https://github.com/KelvinTegelaar/AzNableProxy 
    $xmlDocument.Config.Deployment.Typical.AzNableProxyUri = $AzNableProxyUri
    $xmlDocument.Config.Deployment.Typical.AzNableAuthCode = $AzNableAuthCode

    $xmlDocument.Save($PartnerConfigFile)
    Write-Host "Saving Config to $PartnerConfigFile"
}
else {
    Write-Host "Unable to find PartnerConfig file!"
}
