param(
[Parameter(Mandatory=$True)][string]$AliasIn,
[Parameter(Mandatory=$True)][string]$SqlPortIn
)

#Name of your SQL Server Alias
$AliasName = $AliasIn
  
#These are the two Registry locations for the SQL Alias 
$x86 = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
$x64 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
 
#if the ConnectTo key doesn't exists, create it.
if ((test-path -path $x86) -ne $True)
{
    New-Item $x86
}
 
if ((test-path -path $x64) -ne $True)
{
    New-Item $x64
}
 
#Define SQL Alias 
$TCPAliasName = ("DBMSSOCN," + $env:COMPUTERNAME + "," + $SqlPortIn)
 
#Create TCP/IP Aliases
New-ItemProperty -Path $x86 -Name $AliasIn -PropertyType String -Value $TCPAliasName
New-ItemProperty -Path $x64 -Name $AliasIn -PropertyType String -Value $TCPAliasName
 