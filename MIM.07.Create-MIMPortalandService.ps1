
Import-Module .\FormActions.psm1
Import-Module .\Get-FileName.psm1

.\LoadDialog.ps1 -XamlPath ‘.\Forms\Create-MIMServiceandPortal.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtDBAilais.Clear()
    $txtLogFile.Clear()
    $txtMSI.Clear()
    $txtServiceAccountEmail.Clear()
    $txtSPName.Clear()
    $txtSyncServer.Clear()
    $txtSyncServiceAccount.Clear()
    $txtSSPRRegistrationUrl.Clear()
    $txtUrl.Clear()
})

$btnSelectMSI.add_click({
    $txtMSI.Text = Get-FileName "C:\"
})


$btnSelectLogFile.add_click({
    $txtLogFile.Text = Get-FileName "C:\"
})

$btnConfigure.add_click({
     if($rbNo.IsChecked)
     { 
        [int]$existingDatabase = 0
     }
     else
     {
        [int]$existingDatabase = 1
     }

    .\Deployment\Create-MIMPortalandService.ps1 -urlIn $txtUrl.Text `
                                                -serviceAccountEmailIn $txtServiceAccountEmail.Text `
                                                -mailServerIn $txtEmailServer.Text `
                                                -syncserviceAcctIn $txtSyncServiceAccount.Text `
                                                -syncServerIn $txtSyncServer.Text `
                                                -registrationPortalIn $txtSSPRRegistrationUrl.Text `
                                                -LogFileIn $txtLogFile.Text `
                                                -MsiIn $txtMSI.Text `
                                                -DBAliasIn $txtDBAlias.Text `
                                                -existingDatabaseIn $existingDatabase | Out-Host                                      
                                       
})

#Launch the window
$xamGUI.Title = "Create Portal and Service"
$xamGUI.ShowDialog() | out-null