###########################################################
# SCRIPT Parameters
###########################################################

Param
(
    [Parameter(Mandatory=$True)][string]$NodesIn,
    # The default port used by the endpoints, if we need to create them
    [string] $EndpointPortIn = 5022,

    # The name of the endpoint created on each server, if we need to create one
    [string] $EndpointNameIn = "AlwaysOn_Endpoint"
)

###########################################################
# SCRIPT BODY
###########################################################

Set-ExecutionPolicy RemoteSigned -Scope Process

$ServerList = $NodesIn.Split(',')
 
foreach ($server in $ServerList)
{
    $Session = New-PSSession -ComputerName $server

    Invoke-Command -Session $Session -ScriptBlock {
        

     # Connection to the server instance, using Windows authentication
     #Write-Verbose "Creating SMO Server object for server: $server"
     #$serverObject = New-Object Microsoft.SQLServer.Management.SMO.Server($server)

     # Enable AlwaysOn. We use the -Force option to force a server restart without confirmation.
     # This WILL result in your SQL Server instance restarting.
     Write-Verbose "Enabling AlwaysOn on server instance: $server"
     Enable-SqlAlwaysOn -InputObject $serverObject -Force

     # Check if the server already has a mirroring endpoint (note: a server can only have one)
     $endpointObject = $serverObject.Endpoints |
        Where-Object { $_.EndpointType -eq "DatabaseMirroring" } |
        Select-Object -First 1

     # Create an endpoint if one doesn't exist
     if($endpointObject -eq $null)
     {
        Write-Verbose "Creating endpoint '$EndpointName' on server instance: $server"
        $endpointObject = New-SqlHadrEndpoint -InputObject $serverObject -Name $EndpointNameIn -Port $EndpointPortIn
     }
     else
     {
        Write-Verbose "An endpoint already exists on '$server', skipping endpoint creation."
     }

     # Start the endpoint
     Write-Verbose "Starting endpoint on server instance: $server"
     Set-SqlHadrEndpoint -InputObject $endpointObject -State "Started" | Out-Null
  }
}

