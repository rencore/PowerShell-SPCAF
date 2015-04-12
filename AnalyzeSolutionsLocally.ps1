<#
.SYNOPSIS
    SPCAF SharePoint Code Analysis
	This powershell file analyzes a given set of SharePoint .wsp and .app files and 
	detects critical errors and warnings in the contained code.
.DESCRIPTION    
	All parameters can be configured in the script for ease of use, see more in the configuration section below.
	The product is available under a limited free licence.
	To view a comparison of the features in each version please see this URL
	http://www.spcaf.com/purchase/feature-comparison/
.LINK
	SPCAF Documentation
	http://docs.spcaf.com
.NOTES
    Author: RENCORE AB
    Date:   November 20, 2014    
#>

##################################################################################
# Configurable values
##################################################################################

# Path to directory with .wsp files or a comma-separated list of .wsp files for the analysis
$InputFiles = "D:\FolderWithWSPs";

# Path to output folder for the reports
$OutputDirectory = "D:\SPCAFOutput";

# ReportName - The name of the report to be output
$ReportName = "SPCAFReport";

# TimeStampReportFilename - Whether the date and time should be appended to the report file
# $TRUE or $FALSE
$TimeStampReportFilename = $TRUE;

# Reports - Formats required: HTML,DOCX,PDF,XML,CSV
$Reports = @("HTML","PDF");

# LogFile - The name of the analysis log file, this will be output to the DLL directory
$LogFileName = "SPCAFLog";

# TimeStampLogfileFilename - Whether the date and time should be appended to the log file
# $TRUE or $FALSE
$TimeStampLogfileFilename = $TRUE;

# LicenceFiles Licence path(s) - Comma seperated list of paths, you may need to
# Optional remark out to not use a licence
$LicenseFiles = @();
#$LicenseFiles = @("f:\spcaf\server.lic");
#$LicenseFiles = @("f:\spcaf\server.lic","f:\spcaf\inventory.lic");

# Timeout - Value in seconds, remark out or 0 for no timeout
$Timeout = 20000;

# Verbose - Verbose mode $TRUE or $FALSE
$Verbose = $TRUE;

##################################################################################
# IMPORTAMT: It is recommended that only advanced users edit below this line
##################################################################################

# Other things you might want to do:
# - Load in CSV reports, and produce an comparison over time
# - Auto email reports on schedule

########################################################
# Execute SPCAF Code Analysis on WSPs
########################################################
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module "$ScriptDir\SPCAF.PowerShell.dll"

$params = @{
	InputFiles = @()
	OutputFile = ""
	Reports = @("HTML")
	LicenseFiles = @()
	Timeout = 0
	LogFile = ""
};
if($InputFiles -ne $null)
{
	$params.InputFiles = $InputFiles;
}
if($ReportName -ne $null)
{
	$DateTimeStamp = "";
	if($TimeStampReportFilename)
	{
		$DateTimeStamp = $(get-date -f "yyyyMMdd-HHmmss");
	}	
	$params.OutputFile = "$OutputDirectory\$ReportName$TimeStamp.rep";
}
if($LogFileName -ne $null)
{
	$DateTimeStamp = "";
	if($TimeStampLogfileFilename)
	{
		$DateTimeStamp = $(get-date -f "yyyyMMdd-HHmmss");
	}	
	$params.LogFile = "$OutputDirectory\$LogFileName$TimeStamp.log";
}
if($Reports -ne $null)
{
	$params.Reports = $Reports;
}
# If we are using free version we remove this param
if($LicenseFiles -ne $null)
{
	$params.LicenseFiles = $LicenseFiles;
}
else
{
	$params.LicenseFiles = $null;
}
if($Timeout -ne $null)
{
	$params.Timeout = $Timeout;
}
Invoke-SPCAFCodeAnalysis @params -Verbose:$Verbose;