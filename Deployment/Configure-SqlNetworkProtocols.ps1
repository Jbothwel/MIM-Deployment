param([string]$SqlInstance="MSSQLSERVER")

function ChangeSQLProtocolStatus # Function to Enable or Disable a SQL Server Network Protocol
{
	Param (
		    [Parameter(Mandatory=$True)][string]$protocol,
		    [Parameter(Mandatory=$True)][bool]$enable
	)
	try
	{
		Add-Type -AssemblyName "Microsoft.SqlServer.Smo"
		Add-Type -AssemblyName "Microsoft.SqlServer.SqlWmiManagement"
	}
	catch { throw "Exception occurred when we refer smo and SqlWmiManagement assembly, and its $($_.Exception)" }
	
	try
	{
		Write-Host "Initializing WMI object"		
		$wmi = new-object Microsoft.SqlServer.Management.Smo.WMI.ManagedComputer
		
		Write-Host "Generation URI"		
		$uri = "ManagedComputer[@Name='" + $env:COMPUTERNAME + "']/ServerInstance[@Name='" + $SqlInstance + "']/ServerProtocol"
		
		Write-Host "Creating protocol settings"
		$prtocolSettings = $wmi.getsmoobject($uri + "[@Name='$protocol']")
		
		Write-Host "Created Protocol smo  object"
		$prtocolSettings.IsEnabled = $enable
		$prtocolSettings.Alter()
		
	}
	
	catch
	{
		$_
	}
}

Import-Module "sqlps" -DisableNamechecking

ChangeSQLProtocolStatus -protocol TCP -enable $true
ChangeSQLProtocolStatus -protocol Np -enable $false

# Restart SQL Server
try { Get-Service -Name $SqlInstance -ErrorAction 'Stop' | Restart-Service -Force -ErrorAction 'Stop' }
catch { "Starting Sql server service failed in server $($_.Exception)" }
