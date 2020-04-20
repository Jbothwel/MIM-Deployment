Import-Module .\FormActions.psm1
.\LoadDialog.ps1 -XamlPath ‘.\Forms\Create-Cluster.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtClusterName.Text = ""
    $txtIP.Text = ""
    $txtShare.Text = ""
    $txtServiceAccount.Text = ""
    $txtNodes.Clear()
    $cmbAction.SelectedIndex = 0
    $cmbVerbose.SelectedIndex = 0
})

$btnConfigure.add_click({
    $lblProcessing.Visibility = [System.Windows.Visibility]::Visible

    $nodes = ""
    for($i = 0; $i -lt $txtNodes.LineCount; $i++)
    {
        $nodes = ($nodes + $txtNodes.GetLineText($i)) -replace "`r", "," -replace "`n", ""
    }

    .\Deployment\Configure_Cluster.ps1 -NameIn $txtClusterName.Text `
                                       -NodesIn $nodes `
                                       -IPIn $txtIP.Text `
                                       -FileShareIn $txtShare.Text `
                                       -ActionIn $cmbAction.SelectedItem.Content `
                                       -ServiceAcctIn $txtServiceAccount.Text `
                                       -VerbosePreferenceIn $cmbVerbosePreference.SelectedItem.Content
})

#Launch the window
$xamGUI.Title = "Create Cluster"
$xamGUI.ShowDialog() | out-null