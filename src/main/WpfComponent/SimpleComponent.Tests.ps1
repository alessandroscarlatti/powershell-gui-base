import-module ./SimpleComponent.psm1
import-module ./Test.Module1.psm1

#Set-PSDebug -trace 1

Describe "SimpleComponent" {
    It "Creates top level component" {
        $window = mount-component { param($this)
            $this.Init({ param($this)
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
        $Button1 = { param($this)
            $this.Init({ param($this)
                $this.refs.this.Add_Click($this.props.Click)
            })

            "<Button $($this.xmlns)>Add another button $(Get-String)</Button>"
        }

        $global:Button2 = { param($this)
            $this.Init({ param($this)
                $this.refs.this.Add_Click({
                    write-host "clicked button $($script:this.props.id)"
                }.GetNewClosure())
            })
@"
            <Button $($this.xmlns)>Another button $($this.props.id)</Button>
"@
        }

        $window = mount-component { param($this)
            $this.vars.id = 23
            $this.vars.AddButton = {
                write-host "add another button."
                write-host "stack panel: $($script:this.refs.stackPanel)"

                $newButton = Mount-Component $global:Button2 @{ id = $script:this.vars.id++}
                $script:this.refs.stackPanel.Children.Add($newButton)
            }.GetNewClosure()

@"
            <Window $($this.xmlns)>
                <StackPanel Name="stackPanel">
                    $(mount-child $Button1 $this @{Click = $this.vars.AddButton})
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
        #this does not work!
        # $sb = {
        #     return "Hello ${world}"
        # }

        # $sb.world = "World"
        # $result = &$sb
        # $result | should be "Hello World"
    }
}

Describe "SimpleComponentRefs" {

    It "Can create component with named root element" {
        $__WINDOW__ = { param($this)
            $this.Init({ param($this)
                $this.refs.window1 | should not be $null
                $this.refs.this | should not be $null
            })
            "<Window $($this.xmlns) Name=':window1'></Window>"
        }

        $Window = mount-component $__WINDOW__
    }

    It "Can access a named component within refs" {
        $__WINDOW__ = { param($this)
            $this.Init({ param($this)
                $this.refs.stackPanel | should not be $null
                $this.refs.asdf | should not be $null
            })
            "<Window $($this.xmlns)><StackPanel Name=':stackPanel'><Button Name=':asdf'>asdf</Button></StackPanel></Window>"
        }

        $Window = mount-component $__WINDOW__
    }

    It "Can access a named component outside of refs" {
        $__WINDOW__ = { param($this)
            "<Window $($this.xmlns)><StackPanel Name='stackPanel'><Button>asdf</Button></StackPanel></Window>"
        }

        $Window = mount-component $__WINDOW__
        $Window.FindName("stackPanel") | should not be $null
    }
}

Describe "WpfComponent" {
    It "Adds member to Wpf component" {
        $__WINDOW__ = { param($this)
            "<Window $($this.xmlns)><StackPanel Name='stackPanel'></StackPanel></Window>"
        }

        $__BUTTON__ = { param($this)
            "<Button $($this.xmlns) Name='button1'>asdf</Button>"
        }

        $Window = Mount-Component $__WINDOW__
        $Button = Mount-Component $__BUTTON__

        $SomeProperty = @{
            var1 = "val1"
        }

        #add a custom property "SomeProperty" to the wpf button object
        $Button.Tag = $SomeProperty

        #assert that the property exists.
        $Button.Tag.var1 | should be "val1"

        #add the button to the window
        $button2 = $Window.FindName("stackPanel").Children.Add($Button)

        #edit the button content, even after it has been mounted in the stack panel
        $Button.Content = "qwer"

        #property still exists after we traverse the tree?
        $Window.FindName("stackPanel").Children[0].Content | should be "qwer"
        $Window.FindName("stackPanel").Children[0].Tag.var1 | should be "val1"
    }
}