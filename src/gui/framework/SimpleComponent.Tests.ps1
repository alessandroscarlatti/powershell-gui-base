import-module ./SimpleComponent.psm1

Describe "SimpleComponent" {
    It "Creates only top level component" {

        $Component1Def = {
            param($this)
            $this._ComponentId = "Component1"

            $this.Xaml({
                write-host "Xaml is running with props $($this.props | out-string)."
                [xml]@"
                <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
                    <StackPanel>
                        <Button Name="button1">Button1</Button>
                        <Button Name="button3">Button2</Button>
                    </StackPanel>
                </Window>
"@
            })

            $this.Init({
                param($this)

                $this.refs.Button1.Add_Click({
                    write-host "clicked button 1"
                })

                $this.refs.Button2.Add_Click({
                    write-host "clicked button 2"
                })

                write-host "Init is running with props $($this.props | out-string)"
            })
        }

        #create a blank component from a def and some props
        $component1 = New-SimpleComponent $Component1Def @{ var1 = "val1" }

        #realize the xaml
        $component1._RealizeXaml()

        #realize the wpf
        $component1._RealizeWpf()

        $component1._InitRefs()

        $component1._Init()

        write-host ($component1 | out-string)

        $component1.refs.this.ShowDialog()
    }
}