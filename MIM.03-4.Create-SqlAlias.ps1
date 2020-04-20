Import-Module .\FormActions.psm1
.\LoadDialog.ps1 -XamlPath ‘.\Forms\Create-SqlAlias.xaml’

#EVENT Handlers
 $btnExit.add_Click({
    $xamGUI.Close()
})

$btnClear.add_click({
    $txtDBAlias.Clear()
    $txtDBPort.Clear()
})

$btnConfigure.add_click({
    $lblProcessing.Visibility = [System.Windows.Visibility]::Visible

    .\Deployment\Create-SqlAlias.ps1 -AliasIn $txtDBAlias.Text -SqlPortIn $txtDBPort.Text

    $lblProcessing.Visibility = [System.Windows.Visibility]::Hidden
})

#Launch the window
$xamGUI.Title = "Create SQL Database Alias"
$xamGUI.ShowDialog() | out-null