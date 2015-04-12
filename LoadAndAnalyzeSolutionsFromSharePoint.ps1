<#
.SYNOPSIS
    SPCAF SharePoint Code Analysis
	This powershell file connects to a local SharePoint Farm, downloads the full trust solutions,
	then scans each wsp.
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

# LicenceFiles Licence path(s) - Comma seperated list of additional paths
$LicenseFiles = @();
#$LicenseFiles = @("f:\spcaf\server.lic");

# Timeout - Value in seconds, remark out or 0 for no timeout
$Timeout = 20000;

# Verbose - Verbose mode $TRUE or $FALSE
$Verbose = $TRUE;

##################################################################################
# IMPORTAMT: It is recommended that only advanced users edit below this line
##################################################################################

# Other things you might want to do:
# - Include more solution types (Example download scripts here: http://www.spcaf.com/blog/sharepoint-health-check-2-extracting-customizations/ )
# - Remote powershell download of Farm Solutions
# - Load in CSV reports, and produce an comparison over time
# - Auto email reports on schedule

##############################################################
# Create a temporary folder to save the downloaded wsp files #
##############################################################

$TempFolder = [system.guid]::newguid().tostring()
$InputFiles = "$env:temp\$TempFolder"
New-Item -Force -ItemType directory -Path $InputFiles

########################################################
# Download all Full-Trust solutions from the local farm
########################################################
$ver = $host | select version
if ($ver.Version.Major -gt 1) {$host.Runspace.ThreadOptions = "ReuseThread"} 
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
(Get-SPFarm).Solutions | % {
	$_.SolutionFile.SaveAs($InputFiles + "\" + $_.Name)
	Write-Host $InputFiles + "\" + $_.Name + " downloaded"
}

########################################################
# Execute SPCAF Code Analysis on downloaded WSPs
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

##########################################################
# Finally delete the temp directory with downloaded wsps #
##########################################################

Remove-Item -Recurse -Force $InputFiles