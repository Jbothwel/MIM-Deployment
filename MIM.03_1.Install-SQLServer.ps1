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
Import-Module .\FormActions.psm1
Import-Module .\Get-FileName.psm1

.\LoadDialog.ps1 -XamlPath ‘.\Forms\Install-SQLServer.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtFeatures.Clear()
    $txtSqlExtras.Clear()
    $txtSqlInstance.Clear()
    $txtSqlAdminGroup.Clear()
    $txtSxSPath.Clear()
    $txtSqlSetupPath.Clear()
    $txtSSMSPath.Clear()
    $txtAdminAccount.Clear()
    $txtInstallDir.Clear()
    $txtMimAdminGroup.Clear()
    $txtServiceAccount.Clear()
    $txtServiceAccountPassword.Clear()
    $txtSQLPowershellPath.Clear()
})

$btnAddExtra.add_click({
    if($txtSqlExtras.GetLineText(0) -eq "")
    {
        $txtSqlExtras.AddText((Get-FileName "C:\"))
    }
    else
    {
        $txtSqlExtras.AddText(("`n" + (Get-FileName "C:\")))
    }
})

$btnSelectSqlSetupPath.add_click({
    $txtSqlSetupPath.Text = Get-FileName "C:\"
})

$btnSelectSxSPath.add_click({
    $txtSxSPath.Text = Get-Folder
})

$btnSelectSSMSPath.add_click({
    $txtSSMSPath.Text = Get-FileName "C:\"
})
$btnSelectInstallDir.add_click({
    $txtInstallDir.Text = Get-Folder
})
$btnSQLPSPath.add_click({
    $txtSQLPowershellPath.Text = Get-Folder
})
$btnConfigure.add_click({
    $lblProcessing.Visibility = [System.Windows.Visibility]::Visible
    $SQL_Extras = ""
    for($i = 0; $i -lt $txtSqlExtras.LineCount; $i++)
    {
        $SQL_Extras = ($SQL_Extras + $txtSqlExtras.GetLineText($i)) -replace "`r", "" -replace "`n", ","
    }

    .\Deployment\Install-SQLServer.ps1 -SQLExtrasIn $SQL_Extras `
                                       -ActionIn $cmbAction.SelectedValue.Content `
                                       -SQLSetupPathIn $txtSqlSetupPath.Text `
                                       -FeaturesIn $txtFeatures.Text `
                                       -SxSPathIn $txtSxSPath.Text `
                                       -SSMSPathIn $txtSSMSPath.Text `
                                       -MIMAdminGroupIn $txtMIMAdminGroup.Text `
                                       -SQLAdminGroupIn $txtSqlAdminGroup.Text `
                                       -SqlInstanceIn $txtSqlInstance.Text `
                                       -MIMAdminAccountIn $txtAdminAccount.Text `
                                       -SQLServiceAccountIn $txtServiceAccount.Text `
                                       -SQLServiceAccountPasswordIn $txtServiceAccountPassword.Password.ToString() `
                                       -SQLInstallDirIn $txtInstallDir.Text `
                                       -PowerShellPathIn $txtSQLPowershellPath.Text | Out-Host
})

#Launch the window
$xamGUI.Title = "Install SQL Server"
$xamGUI.ShowDialog() | out-null