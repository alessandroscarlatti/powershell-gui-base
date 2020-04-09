import-module "../../main/WpfComponent/SimpleComponent.psm1" -force

#Build the GUI
[xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window" Title="Initial Window" WindowStartupLocation = "CenterScreen" 
    Width = "313" Height = "800" ShowInTaskbar = "True" Background = "lightgray"> 
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <StackPanel >
            <TextBox  IsReadOnly="True" TextWrapping="Wrap">
                Type something and click Add
            </TextBox>
            <TextBox x:Name = "inputbox"/>
            <Button x:Name="button1" Content="Add"/>
            <Button x:Name="button2" Content="Remove"/>
            <ListBox x:Name="listbox" SelectionMode="Extended" />
        </StackPanel>
    </ScrollViewer >
</Window>
"@
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader)
 
#Connect to Controls
$inputbox = $Window.FindName('inputbox')
$button1 = $Window.FindName('button1')
$button2 = $Window.FindName('button2')
$listbox = $Window.FindName('listbox')

$Window.Add_Activated({
    #Have to have something initially in the collection
    $Script:observableCollection = New-Object System.Collections.ObjectModel.ObservableCollection[string]
    $listbox.ItemsSource = $observableCollection
    $inputbox.Focus()
})
 
#Events
$button1.Add_Click({
     $observableCollection.Add($inputbox.text)
     $inputbox.Clear()
})
$button2.Add_Click({
    ForEach ($item in @($listbox.SelectedItems)) {
        $observableCollection.Remove($item)
    }
})

$Window.ShowDialog() | Out-Null