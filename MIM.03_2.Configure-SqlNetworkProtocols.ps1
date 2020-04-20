Import-Module .\FormActions.psm1
.\LoadDialog.ps1 -XamlPath ‘.\Forms\Configure-SqlNetworkProtocols.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtSqlInstance.Text = ""
})

$btnConfigure.add_click({
    $lblProcessing.Visibility = [System.Windows.Visibility]::Visible

    .\Deployment\Configure-SqlNetworkProtocols.ps1 -SqlInstance $txtSqlInstance.Text

    $lblProcessing.Visibility = [System.Windows.Visibility]::Hidden
})

#Launch the window
$xamGUI.Title = "Configure SQL Network Protocols"
$xamGUI.ShowDialog() | out-null