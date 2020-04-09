import-module "../../main/WpfComponent/SimpleComponent.psm1" -force

$__WINDOW__ = {
    param($this)
    $this.Init({
        param($this)
        $this.refs.this.DataContext = $this.props.data
        # $this.refs.itemsControl.ItemsSource = $this.props.data.MyItemsListProperty

        $this.refs.changeValues.Add_Click({
            try {
                $script:this.props.data.MyItemsListProperty[0].Completion += 5
                $list = New-Object System.Collections.ObjectModel.ObservableCollection[Object] (45.0)
                $newItem = (New-Object PSObject -Property @{
                        Title='Make KIDS do homework'
                        Completion= 45.0
                    })
                $script:this.props.data.MyItemsListProperty.Add((
                    $newItem
                ))
                $script:this.refs.this.refresh()
            } catch {
                write-host ($_ | out-string)
            }
        }.GetNewClosure())
    })

#        <ItemsControl ItemsSource="{Binding MyItemsListProperty}">
@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:diag="clr-namespace:System.Diagnostics;assembly=WindowsBase"
        Title="ItemsControlDataBindingSample" Height="350" Width="300">
<Grid Margin="10">
    <StackPanel>
        <Button Name=":changeValues">Change Values</Button>
        <ItemsControl Name=":itemsControl" ItemsSource="{Binding MyItemsListProperty}">
            <ItemsControl.ItemTemplate>
                <DataTemplate>
                    <Grid Margin="5">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*" />
                            <ColumnDefinition Width="100" />
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="{Binding Title}" />

                        <ProgressBar Grid.Column="1" Minimum="0" Maximum="100" Value="{Binding Completion}" />
                    </Grid>
                </DataTemplate>
            </ItemsControl.ItemTemplate>
        </ItemsControl>
    </StackPanel>
</Grid>
</Window>
"@
}

[System.Collections.ObjectModel.ObservableCollection[Object]] $list = New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (,@(45.0) )

$data = New-Object PSObject -Property @{
    MyItemsListProperty = [System.Collections.ObjectModel.ObservableCollection[Object]] (New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (,@(   
        (New-Object PSObject -Property @{ 
            Title='Complete this WPF tutorial'
            # Completion=$list
            Completion=45.0
        })
        # ,    
        # (New-Object PSObject -Property @{ 
        #     Title='Learn C#'
        #     Completion=New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 )
        # }),
        # (New-Object PSObject -Property @{ 
        #     Title='Wash the car'
        #     Completion=New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 )
        # }),    
        # (New-Object PSObject -Property @{ 
        #     Title='Make KIDS do homework'
        #     Completion=New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 )
        # })
    )))
};
# $completion = New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 )

# $items = @(    
#     New-Object PSObject -Property @{ 
#         Title='Complete this WPF tutorial'
#         Completion= $completion
#     };    
#     New-Object PSObject -Property @{ 
#         Title='Learn C#'
#         Completion=(New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 ))
#     };
#     New-Object PSObject -Property @{ 
#         Title='Wash the car'
#         Completion=(New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 ))
#     };    
#     New-Object PSObject -Property @{ 
#         Title='Make KIDS do homework'
#         Completion=(New-Object System.Collections.ObjectModel.ObservableCollection[Object] -ArgumentList (45.0 ))
#     };
# )

# foreach ($item in $items) {
#     $data.MyItemsListProperty.Add($item) | out-null
# }



$Window = mount-component $__WINDOW__ @{data = $data}
$window.ShowDialog()