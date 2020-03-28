import-module ./ComponentFactory.psm1
$ErrorActionPreference = "Stop"

Describe "ScriptBlockBehavior" {
    It "calls script block with param" {
        $scriptBlock1 = {
            param($someVar)
            "Received $someVar"
        }

        $scriptBlock2 = { param($someVar) &$scriptBlock1 $someVar}

        $var1 = "SomeVal"

        $returnVal = &$scriptBlock2($var1)
        $returnVal | should be "Received SomeVal"
    }
}

Describe "ComponentFactory" {
    It "creates factory" {

        $factoryDefault = New-ComponentFactory
        $factoryDefault.ToString() | should be "Framework.ComponentFactory[default]"

        $factory1 = New-ComponentFactory 1
        $factory1.ToString() | should be "Framework.ComponentFactory[1]"

        $factory2 = New-ComponentFactory 2
        $factory2.ToString() | should be "Framework.ComponentFactory[2]"
    }

    It "define component with script block" {

        $componentDef1 = {
            param($Component)
            write-host "Defining component in script block"
            $Component.Xaml = "<SomeXamlFromFunction/>"
        }

        $factory = New-ComponentFactory
        $factory.DefineComponent("Component1", {param($Component) &$componentDef1 $Component })
        write-host $factory.ToString($true)

        $component1 = $factory.NewComponent("Component1", @{
            prop1 = "val1";
            prop2 = "val2";
        })

        $component1.Xaml | should be "<SomeXamlFromFunction/>"
    }

    It "define component with script file" {

        $factory = New-ComponentFactory
        $factory.DefineComponent("Component1", "./Test.Component.ps1")
        write-host $factory.ToString($true)

        $component1 = $factory.NewComponent("Component1", @{
            prop1 = "val1";
            prop2 = "val2";
        })

        $component1.Xaml | should be "<SomeXamlFromScriptFile/>"
    }
}