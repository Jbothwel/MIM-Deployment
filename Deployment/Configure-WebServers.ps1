param (
        [Parameter(Mandatory=$True)][string]$NodesIn,
        [Parameter(Mandatory=$True)][string]$SxSPathIn
        )

$SPServers = $NodesIn.split(',')

foreach ($S in $SPServers)
{

    $Session = New-PSSession -ComputerName $S

    Invoke-Command -Session $Session -ScriptBlock {
        
        $Features=
        @(
            'Web-WebServer',
            'Net-Framework-Features',
            'rsat-ad-powershell',
            'Web-Mgmt-Tools',
            'Windows-Identity-Foundation',
            'Server-Media-Foundation',
            'Xps-Viewer'
        )
        #,'Application-Server'  #  deprecated role

        $SxS = $SxsPathIn
        
        if ((Test-Path $SxS) -eq $FALSE)
        {

            Write-Host "`n`n  Unable to locate SxS folder; skipping server config for $($env:COMPUTERNAME)  `n`n" -ForegroundColor Red

        }
        else
        {

            foreach ($F in $Features)
            {
                if ((Get-WindowsFeature -Name $F).InstallState -ne 'Installed')
                {
                    Install-WindowsFeature -Name $F -IncludeManagementTools -IncludeAllSubFeature -Restart -Source $SxS
                }
            }

            iisreset /STOP
            C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:windowsAuthentication -commit:apphost
            iisreset /START

        }

    }

}




#foreach ($F in $Features)
#{
#    if (!(Get-WindowsFeature $F))
#    {
#        Write-Host "`n`n    Failed to find feature $($F), Exiting    `n`n" -ForegroundColor Red -BackgroundColor Black
#    }
#}
