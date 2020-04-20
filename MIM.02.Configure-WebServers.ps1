Import-Module .\FormActions.psm1
.\LoadDialog.ps1 -XamlPath ‘.\Forms\Configure-WebServers.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtNodes.Clear()
    $txtSxSPath.Text = ""
})

$btnConfigure.add_click({
    $lblProcessing.Visibility = [System.Windows.Visibility]::Visible
    $nodes = ""
    for($i = 0; $i -lt $txtNodes.LineCount; $i++)
    {
        $nodes = ($nodes + $txtNodes.GetLineText($i)) -replace "`r", "," -replace "`n", ""
    }

    .\Deployment\Configure-WebServers.ps1 -NodesIn $nodes -SxSPathIn $txtSxSPath.Text
})

#Launch the window
$xamGUI.Title = "Configure-WebServers"
$xamGUI.ShowDialog() | out-null