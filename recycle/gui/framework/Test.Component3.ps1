param($this)

$this.Xaml({
    param($this)

    $Button1 = ./Test.SomeButton1.ps1

    [xml]@"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Name="Window1"
    Title="Available Actions"
    SizeToContent="WidthAndHeight"
    ResizeMode="CanMinimize"
    WindowStartupLocation="CenterScreen"
    MaxHeight="600">
    <StackPanel>
        <Button Name="someButton0">Stuff and Things</Button>
        $($this.AddChild($Button1, @{ SomeProp = 1; }))
    </StackPanel>
</Window>
"@
})

$this.Init({
    param($this)

    $this.children.someButton0.AddClick({
        
    })
})