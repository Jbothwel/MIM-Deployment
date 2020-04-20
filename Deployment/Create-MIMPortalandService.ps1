param (
        [Parameter(Mandatory=$True)][string]$urlIn,
        [Parameter(Mandatory=$True)][string]$serviceAccountEmailIn,
        [Parameter(Mandatory=$True)][string]$mailServerIn,
        [Parameter(Mandatory=$True)][string]$syncserviceAcctIn,
        [Parameter(Mandatory=$True)][string]$syncServerIn,
        [Parameter(Mandatory=$True)][string]$registrationPortalIn,
        [Parameter(Mandatory=$True)][string]$LogFileIn,
        [Parameter(Mandatory=$True)][string]$MsiIn,
        [Parameter(Mandatory=$True)][string]$DBAliasIn,
        [Parameter(Mandatory=$True)][int]$existingDatabaseIn
      )

$Domain = $env:USERDOMAIN
$Server = $env:COMPUTERNAME
#$url = ("https://" + $prefix[0] + "portal." + $Domain + ".contoso.com")
#$serviceAcctEmail = ("msvc@" + $location+ ".contoso.com")
#$syncServiceAcct = ($Domain + "\mma")
#$serviceAcctDomain = ($Domain + ".contoso.com")
#$syncServer = $location + "-msync-01"

#$mailServer = "mail.contoso.com"
#$registrationPortal = "https://passwordregistration.contoso.com"


$msvc = Get-Credential -Message "Enter credentials for MSVC service account"
$msvcUser = $msvc.GetNetworkCredential().UserName
$msvcPassword = $msvc.GetNetworkCredential().Password

$mssrp = Get-Credential -Message "Enter credentials for MSSPR service account"
$mssrpUser = $mssrp.GetNetworkCredential().UserName
$mssrpPassword = $mssrp.GetNetworkCredential().Password

msiexec /q /i $MsiIn `
ADDLOCAL="CommonServices,WebPortals" SQMOPTINSETTING=0 `
SQLSERVER_SERVER=$DBAliasIn SQLSERVER_DATABASE=MIMService EXISTINGDATABASE=$existingDatabaseIn `
MAIL_SERVER=$mailServerIn MAIL_SERVER_USE_SSL=1 MAIL_SERVER_IS_EXCHANGE=1 `
POLL_EXCHANGE_ENABLED=1 SERVICE_ACCOUNT_NAME=$msvcUser `
SERVICE_ACCOUNT_PASSWORD=$msvcPassword SERVICE_ACCOUNT_DOMAIN=$Domain `
SERVICE_ACCOUNT_EMAIL=$serviceAccountEmailIn SYNCHRONIZATION_SERVER=$syncServerIn `
SYNCHRONIZATION_SERVER_ACCOUNT=$syncServiceAcctIn SERVICEADDRESS=$Server `
SHAREPOINT_URL=$urlIn REGISTRATION_PORTAL_URL=$registrationPortalIn FIREWALL_CONF=1 SHAREPOINTUSERS_CONF=1 `
REQUIRE_REGISTRATION_INFO=1 REGISTRATION_ACCOUNT_NAME=$mssprUser REGISTRATION_ACCOUNT_DOMAIN=$Domain `
REQUIRE_RESET_INFO=1 RESET_ACCOUNT_NAME=$mssrpUser RESET_ACCOUNT_DOMAIN=$Domain `
/L*v $LogFileIn
