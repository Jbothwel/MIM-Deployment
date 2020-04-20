
################################################################
##
##      1. Enables SQL Always On
##      2. Configures Firewall Exception
##      3. Creates DB Mirror Endpoint
##
################################################################

Param
(
    [Parameter(Mandatory=$True)][string]$NodesIn,
    [string] $EndpointPortIn = 5022,
    [string] $EndpointNameIn = "AlwaysOn_Endpoint",
    [Parameter(Mandatory=$True)][string]$SqlAdminsIn,
    [Parameter(Mandatory=$True)][string]$SqlInstanceIn
)


 ## Import required value 
Import-Module ActiveDirectory,SQLServer,NetSecurity


 ## Create Array for SQL Settings

$SQLConfig=
@{
    Instance      =    $SqlInstanceIn
    SQLAdmins     =    $SqlAdminsIn
    MirrorPort    =    $EndpointPortIn
}


 ## Create Array of Arrays for Firewall Rules 

$Firewall=
@{

    Domain=
    @{
        Name           =    'SQL DB Mirror Endpoint (Domain)'
        Description    =    'Port for database mirroring endpoint used by Always On availability group'
        DisplayName    =    'SQL Server Availability Group Endpoint (Domain)'
        Enabled        =    'TRUE'
        Profile        =    'Domain'
        Direction      =    'Inbound'
        Action         =    'Allow'
        Protocol       =    'TCP'
    }

    Private=
    @{
        Name           =    'SQL DB Mirror Endpoint (Private)'
        Description    =    'Port for database mirroring endpoint used by Always On availability group'
        DisplayName    =    'SQL Server Availability Group Endpoint (Private)'
        Enabled        =    'TRUE'
        Profile        =    'Private'
        Direction      =    'Inbound'
        Action         =    'Allow'
        Protocol       =    'TCP'
    }

}


 ## Create Array for Endpoint Values 

$Endpoint=
@{
    Path          =    "SQLSERVER:\SQL\$($ENV:COMPUTERNAME)\$($SQLConfig.Instance)"
    Name          =    $EndpointNameIn
    Algorithm     =    'AES'
    Encryption    =    'REQUIRED'
    State         =    'STARTED'
}


 ## Validate group membership

if ($ENV:USERNAME -NotIn ((Get-ADGroupMember $SQLConfig.SQLAdmins).SamAccountName))
{
    Write-Host "`n`n  Logged on user is not part of required group; exiting  `n`n" -ForegroundColor Red
}

Set-ExecutionPolicy RemoteSigned -Scope Process

$ServerList = $NodesIn.Split(',')

foreach ($server in $ServerList)
{
    $Session = New-PSSession -ComputerName $server

    Invoke-Command -Session $Session -ScriptBlock 
    {

        ## Enable SQL Always On

        Enable-SqlAlwaysOn -Path "SQLSERVER:\SQL\$($ENV:COMPUTERNAME)\$($SQLConfig.Instance)" -Force

        ## Create Firewall Rules

        foreach ($F in $Firewall.Keys)
        {

            if (Get-NetFirewallRule -Name $Firewall.$F.Name -ErrorAction SilentlyContinue)
            {
                Remove-NetFirewallRule -Name $Firewall.$F.Name
            }

            New-NetFirewallRule `
                -Name $Firewall.$F.Name `
                -Description $Firewall.$F.Description `
                -DisplayName $Firewall.$F.DisplayName `
                -Enabled:$Firewall.$F.Enabled `
                -Profile $Firewall.$F.Profile `
                -Direction $Firewall.$F.Direction `
                -Action $Firewall.$F.Action `
                -Protocol $Firewall.$F.Protocol `
                -LocalPort $SQLConfig.MirrorPort

            if (!(Get-NetFirewallRule -Name $Firewall.$F.Name))
            {
                Write-Host "`n`n  Failed to create firewall rule; exiting  `n`n" -ForegroundColor Red
                Break
            }

        }


         ## Create Endpoint 
        
        $DBEndpoint = New-SqlHADREndpoint `
                        -Path $Endpoint.Path `
                        -Name $Endpoint.Name `
                        -Port $SQLConfig.MirrorPort `
                        -EncryptionAlgorithm $Endpoint.Algorithm `
                        -Encryption $Endpoint.Encryption


        ## Start Endpoint  

        Set-SqlHadrEndpoint -InputObject $DBEndpoint -State $Endpoint.State

    }
 }

#####     Reference Commands     #####
#
#  ## Create Firewall
#
#     New-NetFirewallRule -Name "Custom App Rule (in)" -Description "Our Custom App Rule" -DisplayName "Custom App Rule" -Enabled:True -Profile Public -Direction Inbound -Action Allow -Protocol TCP -LocalPort 4000
#
#
#  ## Create Endpoint
#
#     New-SqlHADREndpoint -Path "SQLSERVER:\Sql\Computer\Instance" -Name "MainEndpoint" -Port 4022 -EncryptionAlgorithm 'Aes' -Encryption Required
#
#
#  ## T-SQL Example
#
#     --Endpoint for initial principal server instance, which  
#     --is the only server instance running on SQLHOST01.  
#     CREATE ENDPOINT endpoint_mirroring  
#         STATE = STARTED  
#         AS TCP ( LISTENER_PORT = 7022 )  
#         FOR DATABASE_MIRRORING (ROLE=PARTNER);  
#     GO  
#     --Endpoint for initial mirror server instance, which  
#     --is the only server instance running on SQLHOST02.  
#     CREATE ENDPOINT endpoint_mirroring  
#         STATE = STARTED  
#         AS TCP ( LISTENER_PORT = 7022 )  
#         FOR DATABASE_MIRRORING (ROLE=PARTNER);  
#     GO  
#     --Endpoint for witness server instance, which  
#     --is the only server instance running on SQLHOST03.  
#     CREATE ENDPOINT endpoint_mirroring  
#         STATE = STARTED  
#         AS TCP ( LISTENER_PORT = 7022 )  
#         FOR DATABASE_MIRRORING (ROLE=WITNESS);  
#     GO  
#
#####     End     #####
