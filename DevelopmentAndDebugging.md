# Development and Debugging
## Overview
The PowerShell version of the InstallAgent package is uses highly structured, robust code with validation and logging at every step, these characteristics make it suitable for use in broad rollouts from small to enterprise businesses.

While it has many positive attributes it can be difficult to approach when re-developing or debugging. So let's provide a high level view of how the script would run under normal circumstances and highlighting the important parts:

![](media/debugging-image0.png)

While this doesn't represent all the functions inside of the InstallAgent-Core.psm1, we will explore it more in depth.

## Challenges and starting debugging
There are a number of challenges that you can run into when developing code for the InstallAgent package:
*   The Installagent.ps1 and the folder structure is intended to self delete after running, as it's intended to be run temporarily from C:\Windows\Temp\AGPO after the LaunchInstaller.bat/ps1 copies it there from the Netlogon/Source folder.
*   Functions in InstallAgent-Core.psm1 depend upon variables declared in InstallAgent.ps1 that exist in Script scope, this is opposed to functions that is passed parameters and all variables are private to it's scope
*   Functions will populate a number of variables with hashtables, their fields names and types are not declared anywhere in code.

The latter challanges are necessary artifacts caused by the constraints in PowerShell 2.0, to debug this code efficiently and cross reference variables it is necessary to use an IDE like Visual Studio Code or PowerShell ISE.

A point to set a debug point to see all the variables/tables populated and in a state to install or upgrade, I recommend put a breakpoint on the call to **SelectInstallMethod** function inside of the **InstallAgent** function at around line 3107 at time of writing.

Next either populate the PartnerConfig as outlined in the ReadMe.md and/or run the InstallAgent.ps1 with CustomerID/Token parameters, it's important to run the script with the dot source operator (period) and run it inside the [current session scope](https://devblogs.microsoft.com/powershell/powershell-constrained-language-mode-and-the-dot-source-operator/)

. .\InstallAgent.ps1 -CustomerID *CustomerID* -RegistrationToken *RegistrationToken* -LauncherPath C:\Repos\Agent\

Also make sure the LauncherPath parameter has a trailing \ otherwise it will cause issues. Once done you can explore all the variables in memory, and run some of the built in debug commands that provide a Gridview of useful tables:
*   DebugGetMethods
*   DebugGetAppliance

Another function available is **DebugGetProxyTokens**, this is used to resolve all Customer IDs inside applicable install method data through the **RequestAzWebProxyToken** function.

# <span style="color: red;">TBC in next branch pull</span>

<span >

## Discuss important functions 
## GetInstallMethods function
The GetInstallMethods function is the key method through in which validated installation data from the different sources is checked one last time before it is populated into the $Install.MethodData Hashtable

The first important part of this function is here:

```powershell
$Values = @(
    $Script.ActivationKey,
    $Config.ActivationKey,        
    $Agent.History.ActivationKey,
    $Agent.Appliance.SiteID,
    ($Script.CustomerID),
    "$($Script.CustomerID)|$($Script.RegistrationToken)",
    "$($Agent.History.ScriptSiteID)|$($Agent.History.RegistrationToken)",
    "$($Config.CustomerId)|$($Config.RegistrationToken)",
    $Script.CustomerID,
    $Config.CustomerId
)
```
These values are then piped through the `for ($i = 0; $i -lt $Values.Count; $i++) { ... } ` loop where for each `$i` it generates a hashtable and assigns it through to the `$Install.MethodData` table.

Where this can be confusing is that the assignment is done here `$Install.MethodData.$(AlphaValue $i)` there the `AlphaValue $i` function is called on `$i` to resolve it to the letter, eg. $i==1 is the letter A, $i==2 is B but this is how we populate out $Install.MethodData.(A,B,C,D ... ) keys.

The hashtable assigned after that has a lot of logic in it, but results in the following hashtable being generated, in this case for the typical case of `$Install.Methodata.A`:
```
Name                           Value                                                                                                                                                          
----                           -----                                                                                                                                                          
Parameter                      AGENTACTIVATIONKEY                                                                                                                                             
FailedAttempts                 0                                                                                                                                                              
Type                           Activation Key: Token/AppId                                                                                                                                    
MaxAttempts                    1                                                                                                                                                              
Value                          c2hvcnRlbmVkIGZvciB0aGlzIGRvY3VtZW50                                          
Name                           Activation Key : Token (Current Script) / Appliance ID (Existing Installation)                                                                                 
Attempts                       0                                                                                                                                                              
Failed                         False                                                                                                                                                          
Available                      True                                                                                                                                                           
```
This is then iterated for each loop until all install methods for available sources is populated in A ->J to fill out the whole $Install.MethodData which if you view it with the DebugGetMethods

![](media\debugging-image1.png)

Let's dive into the next section of logic for the value of the `Available` key as it's is extremely specific and pulls from multiple pieces of data from different hashtables
```powershell
"Available"      =
if (
    ($Agent.Health.AgentStatus -eq $SC.ApplianceStatus.E) -and
    ($i -lt 5)
) {
    # Only use Script Customer ID for Takeover Installations
    $false
}
elseif (!$Config.IsAzNableAvailable -and $SC.InstallMethods.UsesAzProxy.(AlphaValue $i)) {
    # If AzNableProxy configuration isn't available and method uses it...
    $false
}
elseif ($Config.IsAzNableAvailable -and $SC.InstallMethods.Type.(AlphaValue $i) -eq $SC.InstallMethods.InstallTypes.B -and $Agent.Health.Installed -eq $false) {
    # If the type is AzNableProxy, it is Activation Type install and the agent is not installed
    $false
}
else { $null -ne $Values[$i] -and "|" -ne $Values[$i] -and $Values[$i] -notlike "*|" }
```
Let's break this down to each if/else statement:
```powershell
if (($Agent.Health.AgentStatus -eq $SC.ApplianceStatus.E) -and ($i -lt 5)) {$false}
```
If the `$Agent.Health.AgentStatus` which is a diangoed to be one of the following values in `$SC.ApplianceStatus` table in the `DiagnoseAgent` function called prior to the GetInstallMethods
```powershell
$SC.ApplianceStatus = @{
  "A" = "Optimal"
  "B" = "Marginal"
  "C" = "Orphaned"
  "D" = "Disabled"
  "E" = "Rogue / Competitor-Controlled"
  "F" = "Corrupt"
  "G" = "Missing"
}
```
Is then determined to be the key value for `E` which is "Rogue / Competitor-Controlled", and the `$i` value is less than 5 which is the cut off point between Activation Key methods and Registration key methods. If all this is true then we assign `$false` to the `Available` key.

Or in short if the agent is Rogue / Competitor-Controlled don't use Activation Key methods, always use Registration key methods; this is because the Activation Key method attempts to register with the N-Central server with a specific Appliance ID, if that Appliance ID is from a competitor N-Central server there would be a chance we'd register a device over the top of an existing device and cause a conflict.

**Next section**
```powershell
elseif (!$Config.IsAzNableAvailable -and $SC.InstallMethods.UsesAzProxy.(AlphaValue $i)) {
    # If AzNableProxy configuration isn't available and method uses it...
    $false
}
```
This checks if the `$Config.IsAzNableAvailable` variable is `$false` and that the `UsesAzProxy` value for that method, which is again looked up through `AlphaValue $i`
```powershell
  "UsesAzProxy"  = @{
    "A" = $false
    "B" = $false
    "C" = $false
    "D" = $true
    "E" = $true
    "F" = $false
    "G" = $false
    "H" = $false
    "I" = $true
    "J" = $true
  }
```

Or in short, if the information for the AzNableProxy is not in the PartnerConfig, and the current Method uses that service, then it sets `Available` as `$false`

**Next section**
```powershell
elseif ($Config.IsAzNableAvailable -and $SC.InstallMethods.Type.(AlphaValue $i) -eq $SC.InstallMethods.InstallTypes.B -and $Agent.Health.Installed -eq $false) {
    # If the type is AzNableProxy, it is Activation Type install and the agent is not installed
    $false
}
```

This should be more familiar to us now, if the AzNableProxy information is in the PartnerConfig, and the current InstallType value that is in the following hashtable
```powershell
"InstallTypes" = @{
"A" = "Activation Key: Token/AppId"
"B" = "Activation Key: AzNableProxy->Token/AppId"
"C" = "Registration Token: CustomerId/Token"
"D" = "Registration Token: CustomerId/AzNableProxy->Token"
}
  ```

Is found to be of type `B` or the "Activation Key: AzNableProxy->Token/AppId" type and the Agent is not installed; then we set `Available` as `$false`

Or in short, don't make the AzNableProxy type Activation Key install types available if there is no agent to upgrade.

**Finally:**
```powershell
else { $null -ne $Values[$i] -and "|" -ne $Values[$i] -and $Values[$i] -notlike "*|" }
```
The first thing we should note here is this is an `else`, not an `elseif` so we're not evaluating this to determine *if* we run a code block, this *is* the code block we are running. This is fairly straight forward:
*   If the value is not null and;
*   the value is not a plain pipe, which is a value that we can get as it's a delimeter when constructing the `CustomerID|Token` string and;
*   the value is not a CustomerID, followed by a pipe, then no token, again an artifact of constructing the `CustomerID|Token` that is later used in the `InstallAgent` function for Registration Key methods

## DiagnoseAgent function
## RequestAzWebProxyToken function
## Discussion of important tables and what they do
## Discussion about Custom Modules
## Debug Commands and what they do
## Appendices: Detail on example tables of importance