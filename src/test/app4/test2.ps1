import-module "../../main/WpfComponent/SimpleComponent.psm1" -force
try { [CustomHashtable] | Out-Null } catch { Add-Type -TypeDefinition (get-content -raw "./CustomHashtable.cs") -Language CSharp }

$ErrorActionPreference = "Stop"

function Create-WPFWindow {
    Param($Hash)
 
    # Create a window object
    $Window = New-Object System.Windows.Window
    $Window.SizeToContent = [System.Windows.SizeToContent]::WidthAndHeight
    $Window.Title = "WPF Window"
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $Window.ResizeMode = [System.Windows.ResizeMode]::NoResize
 
    # Create a textbox object
    $TextBox = New-Object System.Windows.Controls.TextBox
    $TextBox.Height = 85
    $TextBox.HorizontalContentAlignment = "Center"
    $TextBox.VerticalContentAlignment = "Center"
    $TextBox.FontSize = 30
    $Hash.TextBox = $TextBox
 
    # Create a button object
    $Button = New-Object System.Windows.Controls.Button
    $Button.Height = 85
    $Button.HorizontalContentAlignment = "Center"
    $Button.VerticalContentAlignment = "Center"
    $Button.FontSize = 30
    $Button.Content = "Increment Me!"
    $Hash.Button = $Button
 
    # Assemble the window
    $StackPanel = New-Object System.Windows.Controls.StackPanel
    $StackPanel.Margin = "5,5,5,5"
    $StackPanel.AddChild($TextBox)
    $StackPanel.AddChild($Button)
    $Window.AddChild($StackPanel)
    $Hash.Window = $Window
}


# Create a WPF window and add it to a Hash table
$Hash = @{}
Create-WPFWindow $Hash

$DataContext = $null
 
# Create a datacontext for the textbox and set it
[CustomHashtable] $DataContext = New-Object CustomHashtable

# $DataContext = @{}

# $DataContext | Add-Member -Name _MyCount -MemberType NoteProperty -Value 10

# $DataContext | Add-Member -Name MyCount -MemberType ScriptProperty -Value {
#     # This is the getter
#     return $this._MyCount
# } -SecondValue {
#     param($value)
#     # This is the setter
#     $this._MyCount = $value
# }

$DataContext.MyCount = [int] 10
# $DataContext = New-Object PSCustomObject -property @{
#     Count = [int] 10
# }

$hash.TextBox.DataContext = $DataContext
 
# Create and set a binding on the textbox object
$Binding = New-Object System.Windows.Data.Binding # -ArgumentList "[0]"
$Binding.Path = "[MyCount]"
$Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
# $Binding.UpdateSourceTrigger = "PropertyChanged"
[void][System.Windows.Data.BindingOperations]::SetBinding($Hash.TextBox,[System.Windows.Controls.TextBox]::TextProperty, $Binding)
 
# Add an event for the button click
$Hash.Button.Add_Click{
    write-host "count is $($DataContext.MyCount)"
    ([int] $DataContext.MyCount) ++
}
 
# Show the window
[void]$Hash.Window.Dispatcher.InvokeAsync{$Hash.Window.ShowDialog()}.Wait()
