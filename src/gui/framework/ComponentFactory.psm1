$ErrorActionPreference = "Stop"
# import-module ./XmlUtils.psm1

Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

Function New-ComponentFactory($Id = "default") {

    New-Module -AsCustomObject -ArgumentList @($Id) -ScriptBlock {
        param($Id)
        $_ComponentsScriptMap = @{}

        function ToString($verbose = $false) {
            if ($verbose) {
                return "Framework.ComponentFactory[$Id]" + " Components: `n" +
                ($_ComponentsScriptMap | out-string)
            } else {
                return "Framework.ComponentFactory[$Id]"
            }
        }

        Function _Log($msg) {
            if ($env:DEBUG -ne $null) {
                write-host $msg
                $msg >> stuff.txt
            }
        }

        function DefineComponent([string] $Name, $Script) {
            if ($Script -is [ScriptBlock]) {
                _Log "Defining component with $Name using given script block: $Script"
                $_ComponentsScriptMap[$Name] = $Script
            }

            if ($Script -is [string]) {
                _Log "Defining component with $Name using given string: $Script"
                $_ComponentsScriptMap[$Name] = {param($Component) &$Script $Component }.GetNewClosure()
            }
        }

        function NewComponent([string] $Name, $Props) {
            _Log "Creating component with $Name and props: $($Props | out-string)"

            $Component = @{}
            $Component.Props = $Props
            $Component.Children = @{}

            &$_ComponentsScriptMap[$Name] $Component

            return $Component
        }

        function _InitWpf($Component) {
            # try {
                _Log "Initializing Component $Component"
                _Log "Component XAML (pre-init): $($Component.Xaml.OuterXml)"
    
                #Replace child component placeholders with child component XAML
                $Component.Children.Keys | % {
                    $childComponentName = $_
                    $childComponentXaml = $Component.Children[$_].Xaml
                    _ReplaceXmlNode $Component.Xaml "//*[local-name() = '$childComponentName']" $childComponentXaml
                }

                # _ReplaceXmlNode $Component.Xaml "//*[local-name() = '_Framework_SomeComponent1']" ([xml]'<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent1</Button>')
                # _ReplaceXmlNode $Component.Xaml "//*[local-name() = '_Framework_SomeComponent2']" ([xml]'<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent2</Button>')
    
                #Load XAML
                _Log "Component XAML (post-init): $($Component.Xaml.OuterXml)"
                $Component.Wpf = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $Component.Xaml))

                _Log "Component WPF: $($Component.Wpf)"

            #Assign WPC child component variables
            # $Xaml.SelectNodes("//*[@Name]") | % {
            #     _Log "Adding child WPF Component: $($_.Name)"
            #     $Component[$_.Name] = $Component.Wpf.FindName($_.Name)
            # }
        }

        Function _ReplaceXmlNode([xml] $xml, $xpath, [xml] $newXml) {
            try {
                _Log "Original XML: $($xml.OuterXml)"
                _Log "Target XPATH: $($xpath)"
                _Log "New XML: $($newXml.OuterXml)"
                $newNode = $xml.ImportNode($newXml.DocumentElement, $true)
                $targetNode = $xml.SelectSingleNode($xpath)

                _Log "Target Node: $targetNode"

                #If the out-null is not present these commands will apparently cause errors to be thrown elsewhere!
                #"you cannot call a method on a null-valued expression."
                $targetNode.ParentNode.InsertAfter($newNode, $targetNode) | out-null
                $targetNode.ParentNode.RemoveChild($targetNode) | out-null
            } catch {
                _Log ($_.InvocationInfo | out-string)
                throw $_
            }
        }
    }
}
