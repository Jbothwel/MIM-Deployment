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

.\LoadDialog.ps1 -XamlPath ‘.\Forms\Install-SyncService.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtDBAlias.Clear()
    $txtLogFile.Clear()
    $txtMSI.clear()
    $txtSyncAdmins.Clear()
    $txtSyncBrowse.Clear()
    $txtSyncJoiners.Clear()
    $txtSyncOperators.Clear()
    $txtSyncPasswordReset.Clear() 
})

$btnMSI.add_click({
    $txtMSI.Text = Get-FileName "C:\"
})


$btnSelectLogFile.add_click({
    $txtLogFile.Text = Get-FileName "C:\"
})

$btnConfigure.add_click({

    .\Deployment\Install-SyncService.ps1 -SyncAdminsIn $txtSyncAdmins.Text `
                                       -SyncOperatorsIn $txtSyncOperators.Text `
                                       -SyncJoinersIn $txtSyncJoiners.Text `
                                       -SyncBrowserIn $txtSyncBrowse.Text `
                                       -SyncPasswordResetIn $txtSyncPasswordReset.Text `
                                       -MsiIn $txtMSI.Text`
                                       -DBAliasIn $txtDBAlias.Text `
                                       -LogFileIn $txtLogFile.Text | Out-Host
})

#Launch the window
$xamGUI.Title = "Install SQL Server"
$xamGUI.ShowDialog() | out-null