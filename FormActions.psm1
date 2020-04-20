function Populate-DomainDropDown ([ref]$cfg)
{
    $cbxDomain.Items.Clear()

    for($i=0;$i -lt $cfg.Value.Environments.Environment.Count;$i++)
    {
       if($cbxEnvironment.SelectedValue -eq $cfg.Value.Environments.Environment[$i].name)
       {
            $index = $i
       }
    }

    for($i=0; $i -lt $cfg.Value.Environments.Environment[$index].Domains.Domain.Count; $i++)
    {
        $cbxDomain.Items.Add($cfg.Value.Environments.Environment[$index].Domains.Domain[$i])
    }
}

function Populate-EnvironmentDropDown ([ref]$cfg)
{
    for($i=0;$i -lt $cfg.Value.Environments.Environment.Count;$i++)
    {
        $cbxEnvironment.Items.Add($cfg.Value.Environments.Environment[$i].name)
    }

}

function Populate-InstanceDropdown
{
    $cbxInstance.Items.Add("01")
    $cbxInstance.Items.Add("02")
}

function Show-Label ([ref][System.Windows.Forms.Label]$label)
{
    $label.Value.Visibility = [System.Windows.Visibility]::Visible
}

function Show-Combobox ([ref][System.Windows.Forms.ComboBox]$comboBox)
{
    $comboBox.Value.Visibility = [System.Windows.Visibility]::Visible
}

function Disable-ComboBox ([ref][System.Windows.Forms.ComboBox]$comboBox)
{
    $comboBox.Value.IsEnabled = $false
}

function Enable-Button ([ref][System.Windows.Forms.Button]$button)
{
    $button.Value.IsEnabled = $True
}
