# 2020-02-xx
*   Registration token install method:
    *   Activation Key methods for upgrades
    *   Registration Key methods for new installs/repairs
*   Sources for the registration token can include:
    *   Script input parameters
    *   A configuration file located in the root of the script folder
    *   Kelvin Tegelaar's AzNableProxy via an Azure Cloud function also on GitHub under [KelvinTegelaar/AzNableProxy](https://github.com/KelvinTegelaar/AzNableProxy)
    *   Last successful install configuration saved to a local file
*   Functioning N-Central AMP scripts that support 2 methods for updating the configuration file used for installation
    *   Direct update of Customer ID/Registration Token and other values from N-Central Custom Property (CP) injected via N-Central API See: [How to N-Central API Automation](https://github.com/AngryProgrammerInside/NC-API-Documentation) for examples
    *   Automatic update of Customer ID/Registration token from values pulled from local Agent/Maintenance XML along with provided JWT (see above documentation)
*   Functioning N-Central AMP script to update/renew expired/expiring tokens
*   Legacy Support: If you still have old values within your GPO, you can use a flag within the LaunchInstaller.bat to ignore provided parameters and rely upon the configuration file
*   Custom installation method data
    *   Through additional modules you can use your own source for CustomerID/Registration Token enumeration
    *   A sample module is provided
*   Added a new LaunchInstaller.ps1 while still providing LaunchInstaller.bat, either can be used but those wanting to move away from batch files can.
*   Optional upload of installation telemetry to Azure Cloud, giving insight into success/failure to help track checkins against N-Central
    *   Example modules provided
*   Quality of Life for development and debugging:
    *   Added debugmode to the InstallAgent.ps1 to avoid self destruct and reload of modules
    *   Added debug function to provide Gridviews of common tables
    *   For more details on development debugging of this script, check out this page on GitHub

# 2019-08-26

## Fixes and Bug Control
* Fixed an issue with the Agent Version comparator, partly due to the bizarre Windows Version numbering method for the Agent Installer - e.g. Version 12.1.2008.0 (12.1 HF1) is "greater than" Version 12.1.10241.0 (12.1 SP1 HF1)
* Fixed an issue during Diagnosis phase where incorrect Service Startup Behavior was ALWAYS detected, even after Repairs complete successfully
* The following issues were identified, explored and reported by **Harvey** via N-Able MSP Slack (thank you!):
    * Removed references to the PowerShell 3.0 function **Get-CIMInstance** (from a previous optimization) to maintain PowerShell 2.0 Compatibility
    * Fixed a premature stop error in the Launcher when a Device has .NET 2.0 SP1 installed, but needs to install PowerShell 2.0

## New Features

* Added Script Instance Awareness:
    * The Agent Setup Script will first check to see if another Instance is already in progress, and if so, terminate the Script with an Event Log entry indicating so, in order to preserve Registry results of the pre-existing Instance
    * If the pre-existing Instance has been active for more than 30 minutes, the Script will proceed anyway, thus overwriting results

## Housekeeping and Nuance

* Added Detection Support for .NET Framework 4.8
* Updated some Messages written to the Event Log for clarity

## Tweaks and Optimizations

* None this time!