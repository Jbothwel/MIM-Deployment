param(
       [Parameter(Mandatory=$True)][string]$SyncAdminsIn,
       [Parameter(Mandatory=$True)][string]$SyncOperatorsIn,
       [Parameter(Mandatory=$True)][string]$SyncJoinersIn,
       [Parameter(Mandatory=$True)][string]$SyncBrowserIn,
       [Parameter(Mandatory=$True)][string]$SyncPasswordResetIn,
       [Parameter(Mandatory=$True)][string]$DBAliasIn,
       [Parameter(Mandatory=$True)][string]$LogFileIn,
       [Parameter(Mandatory=$True)][string]$MsiIn
)

$Domain = $env:USERDOMAIN
Install-WindowsFeature Net-Framework-Core, RSAT-AD-TOOLS -source c:\WIndows\WINSxS

$cred = Get-Credential -Message "Enter credentials for MSYNC service account"
$serviceAccount = $cred.GetNetworkCredential().UserName
$password = $cred.GetNetworkCredential().Password

$groupAdmins = $SyncAdminsIn
$groupOperators = $SyncOperatorsIn
$groupJoiners = $SyncJoinersIn
$groupBrowse = $SyncBrowserIn
$groupPasswordSet = $SyncPasswordResetIn

msiexec /q /i $MsiIn `
STORESERVER=$DBAliasIn SQLDB=MIMSync SERVICEACCOUNT=$serviceAccount SERVICEPASSWORD=$password `
SERVICEDOMAIN=$Domain GROUPADMINS=$groupAdmins GROUPOPERATORS=$groupOperators `
GROUPACCOUNTJOINERS=$groupJoiners GROUPBROWSE=$groupBrowse `
GROUPPASSWORDSET=$groupPasswordSet FIREWALL_CONF=1 /L*v $LogFileIn