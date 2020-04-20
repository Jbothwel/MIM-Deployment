
################################################################
##
##  Script needs to be run 2 times
##
##      1. Install SQL Server
##      2. Install Optional SQL components
##
##      Note. SSMS install takes about 15 minutes to complete
##
################################################################

#
#   Grant SQL Server service account “perform volume maintenance tasks” user right in Local Security Policy (secpol.msc | Security Settings >> Local Policies >> User Rights Assignment)
#   Provides Instant File Initialization (files created w/o spending time zeroing entire file size)
#
param (
        [Parameter(Mandatory=$True)][string]$SQLExtrasIn,
        [Parameter(Mandatory=$True)][string]$SxSPathIn,
        [Parameter(Mandatory=$True)][string]$SQLSetupPathIn,
        [Parameter(Mandatory=$True)][string]$ActionIn,
        [Parameter(Mandatory=$True)][string]$FeaturesIn,
        [Parameter(Mandatory=$True)][string]$SSMSPathIn,
        [Parameter(Mandatory=$True)][string]$MIMAdminAccountIn,
        [Parameter(Mandatory=$True)][string]$SQLInstallDirIn,
        [Parameter(Mandatory=$True)][string]$SQLServiceAccountIn,
        [Parameter(Mandatory=$True)][string]$SQLServiceAccountPasswordIn,
        [Parameter(Mandatory=$True)][string]$MIMAdminGroupIn,
        [Parameter(Mandatory=$True)][string]$SQLAdminGroupIn,
        [Parameter(Mandatory=$True)][string]$SqlInstanceIn,
        [Parameter(Mandatory=$True)][string]$PowerShellPathIn
        )

$Domain = (Get-ADDomain).Name
$Features = "RSAT-AD-Tools"

$Timeout=55

foreach ($F in $Features)
{
    if ((Get-WindowsFeature -Name $F).InstallState -ne 'Installed')
    {
        Install-WindowsFeature -Name $F -IncludeManagementTools -IncludeAllSubFeature -Restart -Source $SxSPathIn
    }
}

if($rbGroup.IsChecked)
{
    if (!(Get-ADGroup $MIMAdminAccountIn -ErrorAction SilentlyContinue))
    {
        Write-Host  "`n`n    Unable to validate Active Directory group "($MIMAdminAccountIn)"  `n`n" -ForegroundColor Red
        Break
    }
}
else
{
    if (!(Get-ADUser $MIMAdminAccountIn -ErrorAction SilentlyContinue))
    {
        Write-Host  "`n`n    Unable to validate Active Directory user "($MIMAdminAccountIn)"  `n`n" -ForegroundColor Red
        Break
    }
}

if (
    !(Get-ADUser $SQLServiceAccountIn -ErrorAction SilentlyContinue) -OR 
    !(Get-ADGroup $SQLAdminGroupIn -ErrorAction SilentlyContinue) -OR 
    !(Get-ADGroup $MIMAdminGroupIn -ErrorAction SilentlyContinue)
)
{
    Write-Host  "`n`n    Unable to validate one or more Active Directory users/groups; exiting    `n`n" -ForegroundColor Red
    Break
}

if ((Test-Path -Path $SxSPathIn) -ne $TRUE)
{
    Write-Host "`n`n    Unable to find/access SxS folder at $($SxSPathIn); exiting    `n`n" -ForegroundColor Red
    Break
}

$paths = $SQLExtrasIn.Split(',')
foreach($path in $paths)
{
    $result = (Test-Path -Path (Split-Path $path))
    if(!($result))
    {
        Write-Host "`n`n    Unable to find/access SQL Addon at $($path); exiting    `n`n" -ForegroundColor Red
        Break
    }
}

Import-Module ServerManager

if (!(Get-Service -Name *SQL*))
{

    $SQL = @{
        Action    =  $ActionIn
        Features  =  $FeaturesIn
        Instance  =  $SqlInstanceIn
        Source    =  $SQLSetupPathIn
        Target    =  $SQLInstallDirIn
        Account   =  $SQLServiceAccountIn
        Group     =  $SQLAdminGroupIn
        Sync      =  $SQLServiceAccountIn
        PW        =  $SQLServiceAccountPasswordIn
    }

    if ((Test-Path $SQL.Source) -ne $TRUE)
    {
        Write-Host "`n`n   Unable to find/access SQL Source files ($($SQL.Source)); exiting    `n`n" -ForegroundColor Red
        Break
    }

    if ((Test-Path $SQL.Target) -ne $TRUE)
    {
        Write-Host "`n`n    Unable to find SQL target directory ($($SQL.Target)); attempting to create    `n`n" -ForegroundColor Yellow
        New-Item -Path $SQL.Target -ItemType Directory -Force
        if ((Test-path $SQL.Target) -eq $TRUE)
        {
            Write-Host "    ...successfully created directory    `n`n" -ForegroundColor Green
        }
        else
        {
            Write-Host "    ...directory creation failed; exiting    `n`n" -ForegroundColor Red
        }
    }

}

$UsersToAdd = @(
    $SQLServiceAccountIn,
    $MIMAdminGroupIn,
    $SQLAdminGroupIn
)

$System = [ADSI]("WinNT://$env:COMPUTERNAME,computer") 
$LADM = $System.psbase.children.find('Administrators','Group')
$LADM_Members = $LADM.psbase.invoke("members")  | ForEach {
  $_.GetType().InvokeMember("Name",  'GetProperty',  $null,  $_, $null)
}

foreach ($U in $UsersToAdd)
{
    if (($U -Split '\,')[0] -NotIn $LADM_Members)
    {
        Add-LocalGroupMember -Group "Administrators" -Member ($Domain + "\" + $U)
    }
}

#$password = ConvertTo-SecureString -String $SQL.PW -AsPlainText -Force
$password = $SQL.PW

if (!(Get-Service -Name *SQL*)) 
{
    & $SQL.Source `
        /Q `
        /IACCEPTSQLSERVERLICENSETERMS `
        /ACTION=$($SQL.Action) `
        /FEATURES=$($SQL.Features) `
        /INSTANCEDIR=$($SQL.Target) `
        /INSTANCENAME=$($SQL.Instance) `
        /SQLSVCACCOUNT="$($Domain)\$($SQL.Account)" `
        /SQLSVCPASSWORD=$password `
        /AGTSVCSTARTUPTYPE=Automatic `
        /AGTSVCACCOUNT="NT AUTHORITY\Network Service" `
        /SQLSYSADMINACCOUNTS="$($Domain)\$($SQL.Group)" `
        /INDICATEPROGRESS | Out-Host

}
else
{

    $paths = $SQLExtrasIn.Split(',')
    foreach ($S in $paths)
    {

        $Installer = Get-Item $S

        $Log = "C:\Temp\$($Installer.BaseName)_InstallLog.txt"
        
        if ((Test-Path $Log) -eq $TRUE)
        {
            Remove-Item -Path $Log -Force
            New-Item -Path $Log -ItemType File -Force
        }
        else
        {
            New-Item -Path $Log -ItemType File -Force
        }

        Write-Host "`n`nInstalling $($Installer.BaseName)`n`n" -ForegroundColor Yellow -NoNewline
        
        if (Get-Variable -Name MSI_Job* -ErrorAction SilentlyContinue)
        {
            Remove-Variable MSI_Job*
        }
        
        $MSI_Job = Start-Job -ScriptBlock {  MSIEXEC /q /i $Args[0] IACCEPTSQLNCLILICENSETERMS=YES ACTION=Install /L*v $Args[1]  } -ArgumentList $S,$Log
        Wait-Job $MSI_Job -Timeout $Timeout 
        
        if ($MSI_Job.State -like "Running")
        {

            Stop-Job $MSI_Job
            Remove-Job -Name $MSI_Job.Name
            Write-Host "...job timed out; exiting" -ForegroundColor Red
            Break 

        }
        else
        {

            Start-Sleep -Seconds 60

            $Status = Get-Content $Log

            if ($Status | Select-String 'Installed Failed')
            {
                Write-Host "Installation failed; exiting" -ForegroundColor Red
                Break
            }
            elseif (($Status | Select-String 'Installation completed successfully') -or ($Status | Select-String 'Configuration completed successfully'))
            {
                Write-Host "Successfully installed" -ForegroundColor Green
            }
            else
            {
                Write-Host "Installation encountered an error; exiting" -ForegroundColor Red
                Break
            }

            Remove-Job -Name $MSI_Job.Name

        }

    }

    $SSMSInstaller = Get-Item $SSMSPathIn
    $Log = "C:\Temp\$($SSMSInstaller.BaseName)_InstallLog.txt"

    if ((Test-Path $Log) -eq $TRUE)
    {
        Remove-Item -Path $Log -Force
        New-Item -Path $Log -ItemType File -Force
    }
    else
    {
        New-Item -Path $Log -ItemType File -Force
    }

    & $SSMSInstaller.FullName /install /quiet /norestart /Log $Log
    write-host "`n`n    SSMS installation takes approx. 15 minutes to complete`n    ~40 log entries are created and can found in $((Get-Item $log).DirectoryName)`n    The last log usually has `"36_SsmsPostInstall`" in the name`n    Please monitor logs for installation status    `n`n" -ForegroundColor Yellow
    Write-Host ((Get-Item $log).DirectoryName)


    Write-Host ("`n`n    Installing SQLSERVER Powershell Module 'nn'") -ForegroundColor Yellow

    copy -Path $PowerShellPathIn -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force

    Write-Host ("`n`n    Installation Complete ") -ForegroundColor Green 
}
