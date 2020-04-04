import-module ./SimpleComponent.psm1
import-module ./Test.Module1.psm1

#Set-PSDebug -trace 1

Describe "SimpleComponent" {
    It "Creates top level component" {
        $window = Render {
            Init({
                $this.refs.Button1.Add_Click({
                    write-host "clicked button 1"
                })

                $this.refs.Button2.Add_Click({
                    write-host "clicked button 2"
                })

                write-host "Init is running with props $($this.props | out-string)"
            })

@"
            <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
                <StackPanel>
                    <Button Name="button1">Button1 $(Get-String)</Button>
                    <Button Name="button2">Button2 $(Get-String)</Button>
                </StackPanel>
            </Window>
"@
        }

        $window.ShowDialog()
    }
}

Describe "NestedComponent" {
    It "Creates nested component" {
        $Button1 = {
            Init({
                $this.refs.this.Add_Click($this.props.Click)
            })

            "<Button $($this.xmlns)>Add another button $(Get-String)</Button>"
        }

        $global:Button2 = {
            Init({
                $this.refs.this.Add_Click({
                    write-host "clicked button $($script:this.props.id)"
                }.GetNewClosure())
            })
@"
            <Button $($this.xmlns)>Another button $($this.props.id)</Button>
"@
        }

        $window = Render {
            $this.vars.id = 23
            $this.vars.AddButton = {
                write-host "add another button."
                write-host "stack panel: $($script:this.refs.stackPanel)"

                $newButton = Render $global:Button2 @{ id = $script:this.vars.id++}
                $script:this.refs.stackPanel.Children.Add($newButton)
            }.GetNewClosure()

@"
            <Window $($this.xmlns)>
                <StackPanel Name="stackPanel">
                    $($this.RenderChild($Button1, @{Click = $this.vars.AddButton}))
                    <Button Name="button2">Button2 $(Get-String)</Button>
                </StackPanel>
            </Window>
"@
        }

        write-host ($window | out-string)

        $window.ShowDialog()
    }
}

Describe "ScriptBlock" {
    It "Adds automatic variable" {
        $sb = {
            return "Hello ${world}"
        }

        $sb.world = "World"
        $result = &$sb
        $result | should be "Hello World"
    }
}