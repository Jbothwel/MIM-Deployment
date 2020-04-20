Import-Module .\FormActions.psm1
.\LoadDialog.ps1 -XamlPath ‘.\Forms\Configure-SQLAlwaysOn.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtNodes.Clear()
    $txtEndPointPort.Clear()
    $txtEndPointName.Clear()
})

$btnConfigure.add_click({
    $lblProcessing.Visibility = [System.Windows.Visibility]::Visible
    $nodes = ""
    for($i = 0; $i -lt $txtNodes.LineCount; $i++)
    {
        $nodes = ($nodes + $txtNodes.GetLineText($i)) -replace "`r", "," -replace "`n", ""
    }

    .\Deployment\Configure-SQLAlwaysOn.ps1 -NodesIn $nodes -EndpointPortIn $txtEndPointPort.Text -EndpointNameIn $txtEndPointName.Text
})

#Launch the window
$xamGUI.Title = "Create Cluster"
$xamGUI.ShowDialog() | out-null