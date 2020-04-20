param (
        [Parameter(Mandatory=$True)][string]$NameIn,
        [Parameter(Mandatory=$True)][string]$NodesIn,
        [Parameter(Mandatory=$True)][string]$IPIn,
        [Parameter(Mandatory=$True)][string]$FileShareIn,
        [Parameter(Mandatory=$True)][string]$ActionIn,
        [Parameter(Mandatory=$True)][string]$ServiceAcctIn,
        [Parameter(Mandatory=$True)][string]$VerbosePreferenceIn
        )
##  Administrator configured values

$MIMClusters = @{

    SQL=
    @{
        Name             =    $NameIn
        Nodes            =    $NodesIn
        ClusterIP        =    $IPIn
        QuorumFileShare  =    $FileShareIn
        ServiceAcct      =    $ServiceAcctIn
    }
}

$Action = $ActionIn    #  Cluster configuration Actions: Install, Test, Remove

$VerbosePreference = $VerbosePreferenceIn

$Features = "Data-Center-Bridging","Failover-Clustering","RSAT-Clustering-PowerShell"


##  Validate successful import of required modules

Import-Module Storage,ActiveDirectory

if (!(Get-Module Storage))
{
    Write-Warning 'Failed to import storage module; exiting'
    break
}

if (!(Get-Module ActiveDirectory))
{
    Write-Warning 'Failed to import ActiveDirectory module; exiting'
    break
}


##  Start processing loop to configure individual clusters

foreach ($M in $MIMClusters.Keys)
{
    $Cluster = $MIMClusters.$M

    Write-Host "`n`n   Starting cluster configuration for $($Cluster.Name)  `n`n" -ForegroundColor Green -BackgroundColor Black

    if (!(Get-ADUser $Cluster.ServiceAcct -ErrorAction SilentlyContinue))
    {
        Write-Warning "Service account lookup in AD failed for $($Cluster.ServiceAcct); halting cluster deployment" -Verbose
    }

    if ((Test-Path $Cluster.QuorumFileShare) -ne $TRUE)
    {
        Write-Warning "Path check for Quorom file share $($Cluster.QuorumFileShare) failed; halting cluster deployment" -Verbose
    }


    ##  Configure cluster

    Function Install-ServerRoles ($Features,$Nodes)
    {

        foreach ($N in $Nodes)
        {
            foreach ($F in $Features)
            {
                if ((Get-WindowsFeature $F -ComputerName $N).Installed -ne $TRUE)
                {
                    Install-WindowsFeature -Name $F -ComputerName $N -IncludeAllSubFeature -IncludeManagementTools -Verbose
                }
            }
        }

    }

    Install-ServerRoles -Features $Features -Nodes $Cluster.Nodes

    if ($Action -eq 'Install')
    {

        <#  Create cluster  #>
    
        New-Cluster -Name $Cluster.Name.ToString() -Node $Cluster.Nodes -StaticAddress $Cluster.ClusterIP -Verbose

        $Quorum = Get-ClusterQuorum -Cluster $Cluster.Name.ToString() | Select *

        if ( ($Quorum.QuorumResource -ne 'File Share Witness') -OR ($Quorum.QuorumType -ne 'Majority')  )
        {
            Set-ClusterQuorum -Cluster $Cluster.Name.ToString() -FileShareWitness "$($Cluster.QuorumFileShare)" -AccountName "$($Cluster.ServiceAcct)" -Verbose
        }

        $ValidateQuorum = Get-ClusterQuorum -Cluster $Cluster.Name.ToString() | Select *

        if ( ($ValidateQuorum.QuorumResource -ne 'File Share Witness') -OR ($ValidateQuorum.QuorumType -ne 'Majority')  )
        {
            Write-Warning "Failed to set file share quorum for cluster ($($Cluster.Name))" -Verbose
        }

    }
    elseif ($Action -eq 'Test')
    {

        <#  Test Cluster  #>
        Test-Cluster -Node $Cluster.Nodes -Include Inventory,Network,"System Configuration" -Verbose

    }
    elseif ($Action -eq 'Remove')
    {

        <#  Purge Cluster  #>
        Get-Cluster -Name $Cluster.Name.ToString() | Remove-Cluster -Verbose

    }
    else
    {

        <#  Unexpected Action Value  #>
        Write-Host "`n`n Unexected Action value provided ($($Action)); no cluster action taken `n`n" -ForegroundColor Red -BackgroundColor Black

    }

    Write-Host "`n`n   Configuration activities complete for cluster $($Cluster.Name)  `n`n" -ForegroundColor Green -BackgroundColor Black

}
