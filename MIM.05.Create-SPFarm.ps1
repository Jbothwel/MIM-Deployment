﻿Import-Module .\FormActions.psm1
Import-Module .\Get-FileName.psm1

.\LoadDialog.ps1 -XamlPath ‘.\Forms\Create-SPFarm.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtInstance.Clear()
    $txtDatabaseServer.Clear()
    $passPassPrase.clear()
    $txtSPServiceAccount.Clear()
    $txtInstallAccount.Clear()
})

$btnConfigure.add_click({

    .\Deployment\Create-SPFarm.ps1 -InstanceIn $txtInstance.Text `
                                   -DatabaseServerIn $txtDatabaseServer.Text `
                                   -PassPhraseIn $passPassPhrase.Password.ToString() `
                                   -InstallAccountIn $txtInstallAccount.Text `
                                   -SPServiceAccountIn $txtSPServiceAccount.Text | Out-Host
})

#Launch the window
$xamGUI.Title = "Create SharePoint Farm"
$xamGUI.ShowDialog() | out-null