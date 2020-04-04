import-module ./ComponentFactory.psm1
$ErrorActionPreference = "Stop"

Describe "ComponentFactoryWpf" {
    It "ShowDialog" {
        $factory = New-ComponentFactory

        $factory.DefineComponent("Button1", {
            param($this)
            $this.Xaml = ([xml]'<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent1.1</Button>');

            $this.Init = {
                $this.Wfp.AddClick({
                    write-host "SomeComponent1.1 clicked"
                })
            }.GetNewClosure()
        })

        $factory.DefineComponent("Button2", {
            param($this)
            $this.Xaml = ([xml]'<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent2.1</Button>');

            $this.Init = {
                $this.Wfp.AddClick({
                    write-host "SomeComponent2.1 clicked"
                })
            }.GetNewClosure()
        })

        $factory.DefineComponent("Window1", {
            param($this, $Factory, $Id)

            $this.Xaml = [xml]@"
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
                    $($this.NewXamlComponent("Button1"))
                    $($this.NewXamlComponent("Button2"))
                </StackPanel>
            </Window>
"@
            $this.Init = {
                # $this.Children.this.AddClick({
                #     write-host "clicked"
                # })

                # $this.Wfp.someButton1.AddClick({
                #     write-host "clicked"
                # })

                # $this.Wfp.button1.AddClick({
                #     write-host "clicked"
                # })
            }.GetNewClosure()
        })

        $window1 = $factory.NewComponent("Window1")
        $factory._InitWpf($window1)
        write-host "Window WPF: $($window1.Wpf)"
        $window1.Wpf.ShowDialog()

    }
}