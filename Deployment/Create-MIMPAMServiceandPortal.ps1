param (
        [Parameter(Mandatory=$True)][string]$Domain,
        [Parameter(Mandatory=$True)][int]$existingDatabase)

$Server = $env:COMPUTERNAME

$mailServer = $Server
$url = ("https://Privportal.priv.local")
$serviceAcctEmail = ("msvc@priv.local")
$syncServer = "Priv-MIM-01"

$mmaUser = $Domain + "\mma"

$msvc = Get-Credential -Message "Enter credentials for MSVC service account" -UserName ($Domain + "\MSVC")
$msvcUser = $msvc.GetNetworkCredential().UserName
$msvcPassword = $msvc.GetNetworkCredential().Password

$msp = Get-Credential -Message "Enter credentials for MSP service account" -UserName ($Domain + "\MSP")
$mspUser = $msp.GetNetworkCredential().UserName
$mspPassword = $msp.GetNetworkCredential().Password

$mcmtp = Get-Credential -Message "Enter credentials for MCMTP service account" -UserName ($Domain + "\MCMTP")
$mcmtpUser = $mcmtp.GetNetworkCredential().UserName
$mcmtpPassword = $mcmtp.GetNetworkCredential().Password

$mmntr = Get-Credential -Message "Enter credentials for MMNTR service account" -UserName ($Domain + "\MMNTR")
$mmntrUser = $mmntr.GetNetworkCredential().UserName
$mmntrPassword = $mmntr.GetNetworkCredential().Password

$mssrp = Get-Credential -Message "Enter credentials for MSSRP service account" -UserName ($Domain + "\MSSRP")
$mssrpUser = $mssrp.GetNetworkCredential().UserName
$mssrpPassword = $mssrp.GetNetworkCredential().Password

msiexec /q /i "E:\Service and Portal\Service and Portal.msi" `
ADDLOCAL="ConfigurationBackup,CommonServices,WebPortals,SQMFeatureOptinRegistrySetting,PAMServices,ServerComponents" SQMOPTINSETTING=0 `
SQLSERVER_SERVER=FIMDB SQLSERVER_DATABASE=MIMService EXISTINGDATABASE=$existingDatabase `
MAIL_SERVER=$mailServer MAIL_SERVER_USE_SSL=0 MAIL_SERVER_IS_EXCHANGE=0 `
POLL_EXCHANGE_ENABLED=0 SERVICE_ACCOUNT_NAME=$msvcUser `
SERVICE_ACCOUNT_PASSWORD=$msvcPassword SERVICE_ACCOUNT_DOMAIN=$Domain `
SERVICE_ACCOUNT_EMAIL=$serviceAcctEmail SYNCHRONIZATION_SERVER=$syncServer `
SYNCHRONIZATION_SERVER_ACCOUNT=$mmaUser SERVICEADDRESS=$Server `
SHAREPOINT_URL=$url MIMPAM_REST_API_PORT=8086 `
PAM_REST_API_APPPOOL_ACCOUNT_NAME=$mspUser `
PAM_REST_API_APPPOOL_ACCOUNT_PASSWORD=$mspPassword `
PAM_REST_API_APPPOOL_ACCOUNT_DOMAIN=$Domain `
PAM_COMPONENT_SERVICE_ACCOUNT_NAME=$mcmtpUser `
PAM_COMPONENT_SERVICE_ACCOUNT_PASSWORD=$mcmtpPassword `
PAM_COMPONENT_SERVICE_ACCOUNT_DOMAIN=$Domain `
PAM_MONITORING_SERVICE_ACCOUNT_NAME=$mmntrUser `
PAM_MONITORING_SERVICE_ACCOUNT_PASSWORD=$mmntrPassword `
PAM_MONITORING_SERVICE_ACCOUNT_DOMAIN=$Domain FIREWALL_CONF=1 SHAREPOINTUSERS_CONF=1 `
REQUIRE_REGISTRATION_INFO=1 REGISTRATION_ACCOUNT_NAME=$mssrpUser REGISTRATION_ACCOUNT_DOMAIN=$Domain `
REQUIRE_RESET_INFO=1 `
/L*v C:\mim\Install-MIM2016PamPortalandService.txt
