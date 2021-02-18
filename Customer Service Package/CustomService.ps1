function ReadKey {
    ### Parameters
    ###############################
    param ($Key)
    ### Function Body
    ###############################
    # Test if the Key if Missing if so return $null
    if ((Test-Path $Key) -eq $false)
    { $null } 
    else {
        Get-ItemProperty $Key | Select-Object * -ExcludeProperty PS*
    }
}

$AgentRegPath = "HKLM:\SOFTWARE\Solarwinds MSP Community\InstallAgent"
$InstallAgentResults = ReadKey $AgentRegPath

# These value is almost always present
$AgentLastDiagnosed = $InstallAgentResults.AgentLastDiagnosed

# This value is present if the script has installed or upgraded at some point
$AgentLastInstalled = $InstallAgentResults.AgentLastInstalled

# These values are always present
$ScriptAction = $InstallAgentResults.ScriptAction
$ScriptExitCode = $InstallAgentResults.ScriptExitCode
$ScriptLastRan = $InstallAgentResults.ScriptLastRan
$ScriptMode = $InstallAgentResults.ScriptMode
$ScriptResult = $InstallAgentResults.ScriptResult
$ScriptSequence = $InstallAgentResults.ScriptSequence
$ScriptVersion = $InstallAgentResults.ScriptVersion