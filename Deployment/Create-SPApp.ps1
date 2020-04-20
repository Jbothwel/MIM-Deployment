param (
        [Parameter(Mandatory=$True)][string]$InstanceIn,
        [Parameter(Mandatory=$True)][string]$SPUrlIn,
        [Parameter(Mandatory=$True)][string]$SPNameIn,
        [Parameter(Mandatory=$True)][string]$SPServiceAccountIn,
        [Parameter(Mandatory=$True)][string]$DatabaseServerIn,
        [Parameter(Mandatory=$True)][string]$InstallAccountIn
     )


$databaseName = "SP_Portal_Content_" + $InstanceIn
$appPool = "PortalAppPool"

#$SPUrlIn = ("https://PrivPortal." + $Domain + ".local")
#$SPNameIn = "Priv Portal"

Add-PSSnapin Microsoft.SharePoint.PowerShell
$dbManagedAccount = Get-SPManagedAccount -Identity $SPServiceAccountIn

New-SPWebApplication -Name ($SPNameIn) -ApplicationPool $appPool -ApplicationPoolAccount $dbManagedAccount -AuthenticationMethod Kerberos -Url $SPUrlIn -SecureSocketsLayer -DatabaseServer $DatabaseServerIn -DatabaseName $databaseName

$t = Get-SPWebTemplate -CompatibilityLevel 15 -Identity "STS#1"
$w = Get-SPWebApplication $SPUrlIn

New-SPSite -Url $w.Url -Template $t -OwnerAlias $SPServiceAccountIn -CompatibilityLevel 15 -Name ($SPNameIn) -SecondaryOwnerAlias $InstallAccountIn -ContentDatabase $databaseName

$s = SPSite($w.Url)
$s.AllowSelfServiceUpgrade = $false
$s.CompatibilityLevel

$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;
$contentService.ViewStateOnServer = $false;
$contentService.Update();

Get-SPTimerJob hourly-all-sptimerservice-health-analysis-job | Disable-SPTimerJob