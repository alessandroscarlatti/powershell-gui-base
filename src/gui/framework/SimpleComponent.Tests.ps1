import-module ./SimpleComponent.psm1

Describe "SimpleComponent" {
    It "Creates only top level component" {

        $Component1Def = {
            param($this)
            $this.Xaml({
                write-host "Xaml is running with props $($this.props | out-string)."
                [xml]'<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"></Window>'
            })

            $this.Init({
                param($this)
                write-host "Init is running with props $($this.props | out-string)"
            })
        }

        #create a blank component from a def and some props
        $component1 = New-SimpleComponent $Component1Def @{ var1 = "val1" }

        #realize the xaml
        $component1._RealizeXaml()

        #realize the wpf
        $component1._RealizeWpf()

        write-host ($component1 | out-string)
    }
}