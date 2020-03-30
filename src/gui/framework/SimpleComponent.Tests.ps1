import-module ./SimpleComponent.psm1
import-module ./Test.Module1.psm1

Describe "SimpleComponent" {
    It "Creates only top level component" {

        #create a blank component from a def and some props
        $window = Render {
            param($this)

            $this.Xaml({
                [xml]@"
                <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
                    <StackPanel>
                        <Button Name="button1">Button1 $(Get-String)</Button>
                        <Button Name="button2">Button2 $(Get-String)</Button>
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

        write-host ($window | out-string)

        $window.ShowDialog()
    }
}