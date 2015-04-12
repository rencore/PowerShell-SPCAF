<#
.SYNOPSIS
	SPCAF Integration with Team City build server.
	This powershell file is designed to be run from Jetbrains TeamCity build server in order to add SPCAF integration. 
	Please use this script as a guidance for configuring your own builds with TeamCity. Alternations and customizations to your 
	organizational needs may be required in order to fit your environments.
.NOTES
	Author:		TOBIAS ZIMMERGREN (@zimmergren)
	Date:		March 31, 2015.
	Updated:	--
	Updated by: --
#>

param 
(
	[Parameter(Mandatory=$true)] [string] $CheckoutDirectory = $null,		# This should be the Root of the TeamCity working directory
	[Parameter(Mandatory=$true)] [string] $SPCAFLocation = $null,			# Relative to the CheckoutDirectory root: The location of the SPCAF.powershell.dll file
	[Parameter(Mandatory=$true)] [string] $LicenseFileLocation  = $null,	# Relative to the CheckoutDirectory root: The path and filename of the license file
	[Parameter(Mandatory=$true)] [string] $SourceFileInput  = $null,		# Relative to the CheckoutDirectory root: The location of the source files to analyze (.wsp, .app, etc)
	[Parameter(Mandatory=$true)] [string] $ReportOutput  = $null,			# Absolute path for Reports (UNC for network share, a dropbox folder, a local filesystem folder etc).
	[Parameter(Mandatory=$true)] [String] $ReportFormats  = $null,			# The Report Formats (One or more of these HTML, PDF, DOCX, XML, CSV, DGML)
	[Parameter(Mandatory=$true)] [string] $CustomRulesetFile  = $null		# Relative to the CheckoutDirectory root: If you want to use a custom ruleset, this parameter needs to be configured
)

$ErrorActionPreference = "Stop"

Try
{
	# CheckoutDirectory must contain the checkout directory from TeamCity build server. 
	if (![string]::IsNullOrEmpty($CheckoutDirectory))
	{
		# # # # # # # # # # # # # # # # # # # # # # # #
		# SPCAF PARAMETER CONFIGURATION STARTS HERE   #
		# # # # # # # # # # # # # # # # # # # # # # # #

		# SPCAF PowerShell Cmdlet takes an array of parameters matching this design. Let's initiate the array with empty values and populate it further down in the script.
		$params = @{
			InputFiles = @()
			OutputFile = ""
			Reports = @()
			LicenseFiles = @()
			Timeout = 0
			LogFile = ""
			SettingsFile = ""
		};

		# Add input files to the parameter array. This value comes from the TeamCity build agent when running the build, and should contain the path (relative to the root) of the files to analyze
		if(![string]::IsNullOrEmpty($SourceFileInput))
		{
			$InputFiles = "$($CheckoutDirectory)\$($SourceFileInput)"
			$params.InputFiles = $InputFiles;
		}

		# Add the path (relative to the root) to your License file.
		if(![string]::IsNullOrEmpty($LicenseFileLocation))
		{
			$LicenseFiles = "$($CheckoutDirectory)\$($LicenseFileLocation)"
			$params.LicenseFiles = $LicenseFiles;
		}
		else
		{
			$params.LicenseFiles = $null;
		}

		# Configure the parameters to include the reports you've specified in the TeamCity build configuration
		if(![string]::IsNullOrEmpty($ReportFormats))
		{
			[string[]]$reportArray = $ReportFormats.Split(',',[System.StringSplitOptions]::RemoveEmptyEntries)
			$params.Reports = $reportArray
		}

		# Add the settings file location. This is the path (relative to the root) of your .spruleset file.
		if(![string]::IsNullOrEmpty($CustomRulesetFile))
		{
			$SettingsFile = "$($CheckoutDirectory)\$($CustomRulesetFile)"
			$params.SettingsFile = $SettingsFile;
		}

		# Format and add the OutputFile location. 
		# In this example, I'm using a fixed location (C:\Reports) which is passed in from the build server.
		# You can, and should, adjust this according to your own requirements.
		if(![string]::IsNullOrEmpty($ReportOutput))
		{
			$DateStamp = $(get-date -f "yyyyMMdd-HHmmss");
			$reportFolder = "$($ReportOutput)\$($DateStamp)_SPCAFReports"
			New-Item -ItemType directory -Path "$($reportFolder)"

			# This will create a new folder (named for example 20150401-170631_SPCAFReports) inside the specified report folder, and all output files will land in that folder.
			$params.OutputFile = "$reportFolder";
		}

		# Specify the path to the SPCAF PowerShell binary file, relative to the root. 
		if(![string]::IsNullOrEmpty($SPCAFLocation))
		{
			$binaryLocation = "$($CheckoutDirectory)\$($SPCAFLocation)"
		}

		# # # # # # # # # # # # # # # # #
		# SPCAF INVOCATION STARTS HERE  #
		# # # # # # # # # # # # # # # # #

		# The path to the SPCAF PowerShell Binaries.
		Import-Module "$binaryLocation\SPCAF.PowerShell.dll"		
		
		# Invoke SPCAF Code Analysis PowerShell cmdlet using the arguments configured previously in this script.
		Invoke-SPCAFCodeAnalysis @params -Verbose:$true;			

		# # # # # # # # # # # # # # # # # # # # # # # # # # # #
		# POST-PROCESSING AND TEAM CITY BUILD FAILURE OUTPUT  #
		# # # # # # # # # # # # # # # # # # # # # # # # # # # #

		# The path to the file containing the summary, including the count of errors (these files are now in the SPCAF output directory). 
		$rulesOutputXmlFile = "$($reportFolder)\SPCAFResult_Rules.xml"
		[xml]$ruleXmlOutFile = Get-Content $rulesOutputXmlFile

		# Fetch the amount of Errors from the analysis
		$totalErrors = $ruleXmlOutFile.RulesReport.Summary.Errors;

		# Fetch the amount of Critical Errors from the analysis
		$totalCriticalErrors = $ruleXmlOutFile.RulesReport.Summary.CriticalErrors;

		# Let TeamCity know how many occurances of errors we found during analysis.
		Write-Host "SPCAF CRITICAL ERRORS FOUND: $totalCriticalErrors"
		Write-Host "SPCAF ERRORS FOUND: $totalErrors"
	}
	else
	{
		Write-Host "Checkout Directory is null...." -ForegroundColor Red
	}
}
Catch 
{
	Write-Host $_.Exception.Message
	Break
}