#Add types for WPF
Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#sequence id for components over the lifetime of the application.
$_ComponentIdSeq = 0; 

Function Render([ScriptBlock] $ComponentDefScript, $Props) {
    $Component = New-SimpleComponent $ComponentDefScript $Props
    $Component.RenderAndInit()
    return $Component.refs.this
}

Function RenderComponent([ScriptBlock] $ComponentDefScript, $Props) {
    $Component = New-SimpleComponent $ComponentDefScript $Props
    $Component.RenderAndInit()
    return $Component
}

#Constructor for creating a simple component,
#whether or not the component is a top-level component or a child component.
Function New-SimpleComponent([ScriptBlock] $ComponentDefScript, $Props) {
    _Log "New-SimpleComponent: ComponentDefScript: $($ComponentDefScript)"
    _Log "New-SimpleComponent: Props: $($Props | out-string)"
    $ComponentId = $script:_ComponentIdSeq++
    $NewComponent = New-Module -AsCustomObject -ArgumentList @($ComponentId, $ComponentDefScript, $Props) -ScriptBlock $_SimpleComponentDef

    _Log "Defining component $($NewComponent)"
    $NewComponent._DefineComponent()

    _Log "New-SimpleComponent: Return component: $($NewComponent)"
    return $NewComponent
}

$_SimpleComponentDef = {
    param($_ComponentId, [ScriptBlock] $_ComponentDefScript, $Props)

    $ErrorActionPreference = "Stop"

    $Vars = @{};            #vars for custom use
    $Refs = @{};            #map of ref WPF components directly relating to this component, eg MyButton1 => [WPF object]
                            #This map will NOT contain grandchild WPF components.
                            #This map will only be populated after _RealizeWpf has been called.
    $_Refs = @{};           #map of short name => full name
    $_Children = @{};       #map of child component objects, eg _SomeComponent123 => [SimpleComponent object]
                            #this will only be populated after _RealizeXaml has been called.
    [xml] $_Xaml = $null;   #the actual xaml used for this component
    [ScriptBlock] $_XamlScript = $null;   #the script to be executed to obtain the pre-realized xaml
    [ScriptBlock] $_InitScript = $null;   #the actual init script to call to initialize the component
    [String] $_XamlNamePrefix = "_SimpleComponent_$($_ComponentId)_";       #the prefix for all refs belonging to this component, eg "_SimpleComponent_1_MyButton1"
    [String] $_XamlPlaceholderXpath = "//*[local-name() = '_SimpleComponent_$($_ComponentId)']"     #the xpath to use to identify this placeholder for this component
    [String] $_XamlPlaceholder = "<_SimpleComponent_$($_ComponentId)/>";    #the xaml placeholder for this component, eg "<_SomeComponent123 />"
                                                                            #this will be autogenerated.
    $_Wpf = $null;           #the WPF component that this component represents.
                             #This will only be populated after the component _RealizeWpf has been called.
    $xmlns = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'    #default XAML namespace entry, to help save space in component xaml defs

    #Check that the component def script is not null
    if (!$_ComponentDefScript) {
        _Throw "_ComponentDefScript may not be null!"
    }
    
    #Add a component to the children of this component.
    #The child component object will contain its definition script.
    function _AddComponentAsChild($Component) {
        _Log "_AddComponentAsChild: Component: $($Component)"
        $_Children[$Component._XamlPlaceholder] = $Component
    }

    #Convenience method to create a component object and 
    #add it as a child to this component object.
    function AddChild([ScriptBlock] $_ComponentDefScript, $_Props) {
        try {
            _Log "AddChild: _ComponentDefScript: $($_ComponentDefScript)"
            _Log "AddChild: _Props: $($_Props | out-string)"
            $ChildComponent = New-SimpleComponent $_ComponentDefScript $_Props
            _AddComponentAsChild $ChildComponent
            return $ChildComponent._XamlPlaceholder
        } catch {
            _Throw "AddChild: Error: $($_ | out-string)"
        }
    }

    #Render this component into WPF AND execute the custom init scripts.
    function RenderAndInit() {
        #populate the $_Xaml object
        $this._RealizeXaml()

        #populate the $Wfp object
        $this._RealizeWpf()

        #populate the $Refs map
        $this._InitRefsDeep()

        #call the custom init scripts
        $this._InitDeep()
    }

    #Run the definition script.
    #The result of this will be that the Xaml script and the Init script 
    #will have opportunity to be defined by the custom component.
    function _DefineComponent() {
        try {
            _Log "_DefineComponent: $($this)"

            #Call the definition script
            #Evaluate the result to see if the user returned XAML
            $funcs = @{
                "Xaml" = {param($sb) $this.Xaml($sb) };
                "Init" = {param($sb) $this.Init($sb) };
            }
            $result = $this._ComponentDefScript.InvokeWithContext($funcs, (Get-Variable 'this'), ($this))[0]

            if ($result) {
                _Log "_DefineComponent: $($this) Definition script returned value: $($result) Expecting value to be xaml for this component."
                if ($result -is [string]) {
                    $this._XamlScript = { $result }.GetNewClosure()
                } elseif ($result -is [xml]) {
                    $this._XamlScript = { $result }.GetNewClosure()
                } else {
                    _Log "_DefineComponent: $($this) Definition script return value not able to be considered XAML."
                }
            }

            _Log "_DefineComponent: $($this) Complete"
        } catch {
            _Throw "_DefineComponent: Error: $($_ | out-string)"
        }
    }

    #Realize the xaml in this component by resolving the placeholders 
    #for each of this component's child components.
    #The result will be that this component and each of its children
    #will have valid xaml and no remaining placeholders.
    function _RealizeXaml() {
        try {
            _Log "_RealizeXaml: $($this)"

            #Assert that we have a xaml script to run
            if (-not($this._XamlScript)) { _Throw "_RealizeXaml: Error. No xaml provided. Must provide a XAML script." }

            #Run the xaml script
            #InvokeWithContext returns a list of objects (presumably b/c of supporting streaming)
            $xaml = $this._XamlScript.InvokeWithContext($null, (Get-Variable "this"), ($this))[0]
            if ($xaml -is [xml]) {
                $this._Xaml = $xaml
            }
            elseif ($xaml -is [string]) {
                $this._Xaml = [xml]$xaml
            }
            else {
                _Throw "Unable to construct xaml from object: $($xaml | out-string)"
            }

            _Log "_RealizeXaml: Xaml from script: $($this._Xaml.OuterXml)"

            #Add a name attribute for the root node if it does not already exist.
            _Log "_RealizeXaml: $($this) Checking if need to create root node Name attribute"
            
            $RootNodeNameAttribute = $this._Xaml.SelectSingleNode("/*/@Name")
            if (-not($RootNodeNameAttribute)) {
                _Log "_RealizeXaml: $($this) Creating root node Name attribute"
                $RootNode = $this._Xaml.SelectSingleNode("/*")
                $RootNodeNameAttribute = $RootNode.OwnerDocument.CreateAttribute("Name")
                $RootNodeNameAttribute.Value = "this"
                $RootNode.Attributes.Append($RootNodeNameAttribute) | out-null

                _Log "_RealizeXaml: $($this) Added root node Name attribute: $($RootNodeNameAttribute.Value)"
            }

            #Create a ref mapping for "this". It will point to the root node. 
            #The root node is guaranteed to have a Name attribute due to setup above.
            $this._Refs["this"] = $RootNodeNameAttribute.Value

            #Find and store the name attributes that are present in this component
            $this._Xaml.SelectNodes("//@Name") | % {

                #Prepend any name attributes that do not begin with _ with this component's XamlNamePrefix
                #This will help later so that those WPF components can be traced to this component for use during the init process.
                if (-not($_.Value.StartsWith("_"))) {
                    $newName = $this._XamlNamePrefix + $_.Value
                    _Log "_RealizeXaml: Replace original Name $($_.Value) with unique Name $($newName)"
                    $_.Value = $newName
                }

                #Name attribute will be something like _SimpleComponent_1_MyButton1
                #The short name should be MyButton1
                #In the case of the name being something like MyButton2
                #The conversion to short name will be a noop.
                $shortName = $_.Value -replace $this._XamlNamePrefix, ""
                $this._Refs[$shortName] = $_.Value
            }

            #TODO use child component map to replace xaml placeholders with child component xaml.
            _Log "_RealizeXaml: $($this): Render component placeholders"
            $this._Children.Keys | % {
                #render the xaml for the child component
                $child = $this._Children[$_]
                $child._RealizeXaml()

                #now that the child component's xaml is rendered,
                #replace the placeholder with the full xaml from the child component.
                _ReplaceXmlNode $this._Xaml $child._XamlPlaceholderXpath $child._Xaml.OuterXml
            }

            _Log "_RealizeXaml: $($this) Complete"
        } catch {
            _Throw "_RealizeXaml: Error: $($_ | out-string)"
        }
    }

    #Realize the WPF component by loading the XAML as WPF object.
    #The result of this is that this component's WPF variable will contain the WPF object created.
    #This action will also create all of the "child" WPF components.
    #This method will then traverse all the child components
    #to populate the child component's WPF variable
    function _RealizeWpf() {
        try {
            _Log "_RealizeWpf: $($this)"

            #Load WPF component
            _Log "_RealizeWpf: XAML: $($this._Xaml.OuterXml)"
            $Wpf = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $this._Xaml))

            #Set WFP component for all child components
            $this.__SetWpfDeep($Wpf)

            _Log "_RealizeWpf: $($this) Complete"
        } catch {
            _throw "_RealizeWpf: Error: $($_ | out-string)"
        }
    }

    #Use the "this" ref in the $_refs map to populate the $Wfp variable
    #The Wpf component at the top of the hierarchy
    function __SetWpfDeep($TopWpfComponent) {
        _Log "__SetWpfDeep: $($TopWpfComponent)"
        $this._Wpf = $TopWpfComponent.FindName($this._Refs.this)

        if (-not($this._Wpf)) {
            throw "Could not find component for name '$($this._Refs.this)' in WPF component $($TopWpfComponent)"
        }

        $this._Children.Keys | % {
            $child = $this._Children[$_]
            if (-not($child)) {
                _Throw "__SetWpfDeep: $($this) Error: No child component found for name $_"
            }
            $child.__SetWpfDeep($TopWpfComponent)
        }
        _Log "__SetWpfDeep: $($TopWpfComponent) Complete"
    }

    #Find refs inside the xaml that belong to this component
    #AND to its children, recursively
    #(by using this component ID to identify name attributes)
    #The result will be a populated $refs variable.
    function _InitRefsDeep() {
        _Log "_InitRefsDeep: $($this) XamlNamePrefix: $($this._XamlNamePrefix)"
        $this.__InitRefs()
        $this._Children.Keys | % {
            $this._Children[$_]._InitRefsDeep()
        }
        _Log "_InitRefsDeep: $($this) XamlNamePrefix: $($this._XamlNamePrefix) Complete"
    }

    #Find refs inside the xaml that belong to this component
    #(by using the populated $_refs map)
    #This ASSUMES that the $Wpf variable will be populated
    #The result will be a populated $refs variable.
    function __InitRefs() {
        try {
            _Log "__InitRefs: $($this) XamlNamePrefix: $($this._XamlNamePrefix)"
            _Log "__InitRefs: $($this) _Refs: $($this._Refs | out-string)"

            #At this point the _Refs table will be filled out.
            #eg: MyButton1 => _SimpleComponent_1_MyButton1
            #eg: MyButton2 => MyButton2
            #Use this table to discover which actual name to use to find the WFP component ref.
            $this._Refs.Keys | % {
                $actualName = $this._Refs[$_]
                $this.Refs[$_] = $this._Wpf.FindName($actualName)
            }

            _Log "__InitRefs: $($this) Refs: $($this.Refs | out-string)"
            _Log "__InitRefs: $($this) Complete"
        } catch {
            _Throw "__InitRefs: Error: $($_ | out-string)"
        }
    }

    function _ReplaceXmlNode([xml] $xml, $xpath, [xml] $newXml) {
        try {
            _Log "_ReplaceXmlNode: Original XML: $($xml.OuterXml)"
            _Log "_ReplaceXmlNode: Target XPATH: $($xpath)"
            _Log "_ReplaceXmlNode: New XML: $($newXml.OuterXml)"
            $newNode = $xml.ImportNode($newXml.DocumentElement, $true)
            $targetNode = $xml.SelectSingleNode($xpath)

            _Log "_ReplaceXmlNode: Target Node: $targetNode"
            if (-not($targetNode)) {
                _Throw "_ReplaceXmlNode: No target node found for xpath: $($xpath)"
            }

            #If the out-null is not present these commands will apparently cause errors to be thrown elsewhere!
            #"you cannot call a method on a null-valued expression."
            $targetNode.ParentNode.InsertAfter($newNode, $targetNode) | out-null
            $targetNode.ParentNode.RemoveChild($targetNode) | out-null
        } catch {
            throw "_ReplaceXmlNode: Error replacing xml node: $($_ | out-string)"
        }
    }

    #Initialize this component by calling its init script
    #and then calling each child's init script (if not $null).
    #The result will be that this component and each of its children
    #will have had their init scripts called.
    #This means that the WPF objects are fully initialized,
    #ready to be displayed.
    function _InitDeep() {
        try {
            _Log "_InitDeep: $($this)"
            if ($this._InitScript) {
                _Log "_InitDeep: $($this) Calling init function: $($this._InitScript)"
                $this._InitScript.InvokeWithContext($null, (Get-Variable "this"), ($this))
            }

            $this._Children.Keys | % {
                $this._Children[$_]._InitDeep()
            }
        } catch {
            _Throw "_InitDeep: $($this) Error calling init function, Check your Init function for the following error: $($_ | out-string)"
        }
    }

    #Assign the script that will be called to generate xaml.
    function Xaml([ScriptBlock] $XamlScript) {
        try {
            $this._XamlScript = $XamlScript
        } catch {
            _Throw "Xaml: Error: $($_ | out-string)"
        }
    }

    #Assign the script that will be called to initialize the wpf objects.
    function Init([ScriptBlock] $InitScript) {
        try {
            $this._InitScript = $InitScript
        } catch {
            _Throw "Init: Error: $($_ | out-string)"
        }
    }

    #String representation of this component.
    function ToString() {
        return "Framework.SimpleComponent[$($this._XamlPlaceholder)]"
    }

    Export-ModuleMember -Function *
    Export-ModuleMember -Variable *
}

#Log the activities of this component.
#Only log when in debug mode, ie, when $env:DEBUG is not empty.
Function _Log($msg) {
    if ($env:DEBUG) {
        write-host $msg
        $msg >> stuff.txt
    }
}

Function _Throw($msg) {
    _Log $msg
    throw $msg
}