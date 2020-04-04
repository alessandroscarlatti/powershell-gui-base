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

            #Initialize an empty component
            $Component = @{}
            $Component.Name = $Name
            $Component.Props = $Props
            $Component.Children = @{}
            $Component._ComponentFactory = $this

            #Define a method for users to call when creating a component
            $Component | Add-Member -Name NewXamlComponent -Type ScriptMethod -Value {
                param([string] $Type, $Props)

                #TODO this should handle IDs, not assuming type = id
                $newComponent = $this._ComponentFactory.NewComponent($Type, $Props)

                #TODO this should perhaps add to a "global" children?
                $this.Children[$Type] = $newComponent

                return $newComponent.GetXamlPlaceholder()
            }

            $Component | Add-Member -Name GetXamlPlaceholder -Type ScriptMethod -Value { "<$($this.Name) />" }
            $Component | Add-Member -Name ToString -Type ScriptMethod -Force -Value { "<$($this.Name) />" }

            #Call the initializer for this component
            &$_ComponentsScriptMap[$Name] $Component

            #After calling initializer, expect:
            #Component.Xaml is initialized.
            return $Component
        }

        function _InitWpf($Component) {
            try {
                _Log "Initializing Component $Component"
                _Log "Component XAML (pre-init): $($Component.Xaml.OuterXml)"
    
                #Replace child component placeholders with child component XAML
                $Component.Children.Keys | % {
                    $childComponentName = $_
                    $childComponentXaml = $Component.Children[$_].Xaml
                    _ReplaceXmlNode $Component.Xaml "//*[local-name() = '$childComponentName']" $childComponentXaml
                }
    
                #Load XAML
                _Log "Component XAML (post-init): $($Component.Xaml.OuterXml)"
                $Component.Wpf = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $Component.Xaml))

                _Log "Component WPF: $($Component.Wpf)"

                #Assign WPC child component variables
                $Component.Xaml.SelectNodes("//*[@Name]") | % {
                    _Log "Considering WPF Component: $($_.Name)"
                    if ($Component.Children[$_.Name]) {
                        _Log "Adding child WPF Component: $($_.Name)"
                        $Component.Children[$_.Name].Wpf = $Component.Wpf.FindName($_.Name)
                    } else {
                        _Log "Not adding child WPF Component: $($_.Name)"
                    }
                }

                #Call init function
                write-host "Asdf"
                _InitRecursive($Component)

                Write-host "Children: $($Component.Children | out-string)"
            } catch {
                _Log "Error initializing WPF component: $($_ | out-string)"
                throw $_
            }
        }

        Function _InitRecursive($Component) {
            try {
                _Log "Initializing component: $($Component.Name)"
                if ($Component.Init) {
                    &$Component.Init
                }

                #Initialize children
                _Log("Children: $($Component.Children | out-string)")
                $Component.Children.Keys | % {
                    _Log("Considering child component $($_)")
                    if ($_) {
                        _Log("Initializing child component $($_.Name)")
                        $this._InitRecursive($Component.Children[$_])
                    }
                }
            } catch {
                _Log "Error initializing component: $($Component.Name) $($_ | out-string)"
                throw $_
            }
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
