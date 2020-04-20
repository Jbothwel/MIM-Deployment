param (
        [Parameter(Mandatory=$True)][string]$InstanceIn,
        [Parameter(Mandatory=$True)][string]$DatabaseServerIn,
        [Parameter(Mandatory=$True)][string]$PassPhraseIn,
        [Parameter(Mandatory=$True)][string]$InstallAccountIn,
        [Parameter(Mandatory=$True)][string]$SPServiceAccountIn
       )       
Add-PSSnapin Microsoft.SharePoint.PowerShell
$ConfigDatabasename = "SP2016_Config" + $InstanceIn
$SQLServer = $DatabaseServerIn
$CADatabaseName = "SP2016_AdminContent" + $InstanceIn
$CAPort = "17001"
$CAAuth = "NTLM"
$PassPhrase = $PassPhraseIn
$sPassphrase = (ConvertTo-SecureString -String $PassPhrase -AsPlainText -force)
$userName = $InstallAccountIn

New-SPConfigurationDatabase -DatabaseName $ConfigDatabasename -DatabaseServer $SQLServer -AdministrationContentDatabaseName $CADatabaseName -Passphrase $sPassphrase -FarmCredentials (Get-Credential -UserName $userName -M "login") -LocalServerRole "SingleServerFarm"

$farm = Get-SPFarm
if(!$farm -or $farm.Status -ne "Online")
{
    Write-Output "Farm was not created or is not running."
    exit
}

Initialize-SPResourceSecurity
Install-SPService
Install-SPFeature -AllExistingFeatures

New-SPCentralAdministration -Port $CAPort -WindowsAuthProvider $CAAuth

Install-SPHelpCollection -All
Install-SPApplicationContent

New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopBackCheck" -value "1" -PropertyType dword
$ServiceConnectionPoint = get-SPTopologyServiceApplication | select URI
$userName = $SPServiceAccountIn
$cred = (Get-Credential -UserName $userName -Message "Log On")
New-SPManagedAccount -Credential $cred
