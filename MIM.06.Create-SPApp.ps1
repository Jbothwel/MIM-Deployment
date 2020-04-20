Import-Module .\FormActions.psm1
Import-Module .\Get-FileName.psm1

.\LoadDialog.ps1 -XamlPath ‘.\Forms\Create-SPApp.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtInstance.Clear()
    $txtDatabaseServer.Clear()
    $txtSPUrl.Clear()
    $txtSPName.Clear()
    $txtSPServiceAccount.Clear()
    $txtInstallAccount.Clear()
})

$btnConfigure.add_click({

    .\Deployment\Create-SPApp.ps1 -InstanceIn $txtInstance.Text `
                                  -DatabaseServerIn $txtDatabaseServer.Text `
                                  -SPUrlIn $txtSPUrl.Text `
                                  -SPNameIn $txtSPName.Text `
                                  -InstallAccountIn $txtInstallAccount.Text `
                                  -SPServiceAccountIn $txtSPServiceAccount.Text | Out-Host
})

#Launch the window
$xamGUI.Title = "Create SharePoint Application"
$xamGUI.ShowDialog() | out-null