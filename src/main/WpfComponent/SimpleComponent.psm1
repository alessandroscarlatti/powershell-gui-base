# Set-StrictMode -Version Latest

#Add types for WPF
Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#sequence id for components over the lifetime of the application.
$_ComponentIdSeq = 0; 

# set-psdebug -trace 1

$ErrorActionPreference = "Stop"

Function Import-Component([string] $scriptFile) {
    $sb = Get-Command $scriptFile | Select-Object -ExpandProperty ScriptBlock
    return { param($this) 
        try {
            Invoke-Command $sb -ArgumentList $this
        } catch {
            _Throw ("Error defining component in file $($scriptFile)", $_)
        }
    }.GetNewClosure()
}

Function Mount-Child([ScriptBlock] $ComponentDefScript, $ParentComponent, $Props, $Context) {
    if ($null -eq $Context) {
        $Context = $ParentComponent.Context
    }

    $ParentComponent.RenderChild($ComponentDefScript, $Props, $Context)
}

Function Mount-Children($Children) {
    $xaml = ""
    foreach($child in $Children) {
        $xaml += $child
    }

    return $xaml
}

Function New-Child([ScriptBlock] $ComponentDefScript, $ParentComponent, $Props, $Context) {
    if ($null -eq $Context) {
        $Context = $ParentComponent.Context
    }
    Mount-Component $ComponentDefScript $Props $Context
}

Function Mount-Component([ScriptBlock] $ComponentDefScript, $Props, $Context) {
    ConvertTo-Wpf $ComponentDefScript $Props $Context
}

#Dismount the given WPF component.
#Only calls the destroy scripts.
#At this time, we THINK that this should be called BEFORE removing the component from the tree.
#However, depending on how the logical tree traversal works, this may not be necessary.
Function Dismount-Component($WpfComponent) {

    Function VisitControl($WpfComponent) {
        #search for UIElement children
        _Log("Visiting control: $($WpfComponent.ToString())")
        if (($WpfComponent -is [System.Windows.UIElement]) -or ($WpfComponent -is [System.Windows.UIElement3D])) {
            $children = [System.Windows.LogicalTreeHelper]::GetChildren($WpfComponent)
            foreach($child in $children) {
                #visit each child
                VisitControl $child
            }

            #look for a destroy script
            if (($WpfComponent.Tag._DestroyScript) -and ($WpfComponent.Tag._DestroyScript -is [ScriptBlock])) {
                #call the script if it exists
                _Log "Found destory script for component: $($WpfComponent.ToString()) : $($WpfComponent.Tag.ToString()) : $($WpfComponent.Tag._DestoryScript)"
                &$WpfComponent.Tag._DestroyScript $WpfComponent.Tag
            }
        }
    }

    #start the recursive process
    VisitControl $WpfComponent
}

Function ConvertTo-Wpf([ScriptBlock] $ComponentDefScript, $Props, $Context) {
    $Component = New-SimpleComponent $ComponentDefScript $Props $Context
    $Component.RenderAndInit()
    return $Component.refs.this
}

Function ConvertTo-Component([ScriptBlock] $ComponentDefScript, $Props, $Context) {
    $Component = New-SimpleComponent $ComponentDefScript $Props $Context
    $Component.RenderAndInit()
    return $Component
}

#Constructor for creating a simple component,
#whether or not the component is a top-level component or a child component.
Function New-SimpleComponent([ScriptBlock] $ComponentDefScript, $Props, $Context) {
    _Log "New-SimpleComponent: ComponentDefScript: $($ComponentDefScript)"
    _Log "New-SimpleComponent: Props: $($Props | out-string)"
    $ComponentId = $script:_ComponentIdSeq++
    $NewComponent = New-Module -AsCustomObject -ArgumentList @($ComponentId, $ComponentDefScript, $Props, $Context) -ScriptBlock $_SimpleComponentDef

    _Log "Defining component $($NewComponent)"
    $NewComponent._DefineComponent()

    _Log "New-SimpleComponent: Return component: $($NewComponent)"
    return $NewComponent
}

$_SimpleComponentDef = {
    param($_ComponentId, [ScriptBlock] $_ComponentDefScript, $Props, $Context)

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
    [ScriptBlock] $_DestroyScript = $null #the actual destroy script to call when unmounting this component
    [String] $_XamlNamePrefix = "_____SimpleComponent_$($_ComponentId)_";       #the prefix for all refs belonging to this component, eg "_SimpleComponent_1_MyButton1"
    [String] $_XamlPlaceholderXpath = "//*[local-name() = '_____SimpleComponent_$($_ComponentId)']"     #the xpath to use to identify this placeholder for this component
    [String] $_XamlPlaceholder = "<_____SimpleComponent_$($_ComponentId)/>";    #the xaml placeholder for this component, eg "<_SomeComponent123 />"
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

    #Convenience alias for AddChild
    function RenderChild([ScriptBlock] $_ComponentDefScript, $_Props, $_Context) {
        return $this.AddChild($_ComponentDefScript, $_Props, $_Context)
    }

    #Convenience method to create a component object and 
    #add it as a child to this component object.
    function AddChild([ScriptBlock] $_ComponentDefScript, $_Props, $_Context) {
        try {
            _Log "AddChild: _ComponentDefScript: $($_ComponentDefScript)"
            _Log "AddChild: _Props: $($_Props | out-string)"
            $ChildComponent = New-SimpleComponent $_ComponentDefScript $_Props $_Context
            _AddComponentAsChild $ChildComponent
            return $ChildComponent._XamlPlaceholder
        } catch {
            _Throw ("AddChild: Error", $_)
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
            $xmlns = $this.xmlns
            $vars = $this.vars
            $props = $this.props
            $varThis = Get-Variable "this"
            $varXmlns = Get-Variable "xmlns"
            $varVars = Get-Variable "vars"
            $varProps = Get-Variable "props"
            $varsThru = @($varThis, $varXmlns, $varVars, $varProps)
            $params = @($this)

            try {
                $result = Invoke-Command $this._ComponentDefScript -ArgumentList ($this) -EA stop
            } catch {
                _Throw ("_DefineComponent: Error calling component definition script. Check your component definition script for the root error.", $_)
            }

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
            _Throw ("_DefineComponent: Error", $_)
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
            $funcs = @{
                "RenderChild" = {
                    param($sb)
                    try {
                        $this.RenderChild($sb) 
                    } catch {
                        _Throw ("Error invoking RenderChild script", $_)
                    }
                };
            }

            $xmlns = $this.xmlns
            $vars = $this.vars
            $props = $this.props
            $varThis = Get-Variable "this"
            $varXmlns = Get-Variable "xmlns"
            $varVars = Get-Variable "vars"
            $varProps = Get-Variable "props"
            $xaml = $this._XamlScript.InvokeWithContext($funcs, ($varThis, $varXmlns, $varVars, $varProps), ($this))[0]
            if ($xaml -is [xml]) {
                $this._Xaml = $xaml
            }
            elseif ($xaml -is [string]) {
                $this._Xaml = [xml]$xaml
            }
            else {
                _Throw ("Unable to construct xaml from object: $($xaml | out-string)", $_)
            }

            _Log "_RealizeXaml: Xaml from script: $($this._Xaml.OuterXml)"

            #Add a name attribute for the root node if it does not already exist.
            _Log "_RealizeXaml: $($this) Checking if need to create root node Name attribute"
            
            $RootNodeNameAttribute = $this._Xaml.SelectSingleNode("/*/@Name")
            if (-not($RootNodeNameAttribute)) {
                _Log "_RealizeXaml: $($this) Creating root node Name attribute"
                $RootNode = $this._Xaml.SelectSingleNode("/*")
                $RootNodeNameAttribute = $RootNode.OwnerDocument.CreateAttribute("Name")
                $RootNodeNameAttribute.Value = ":this" #prefix with ":" so that the name will replaced with a unique identifier.
                $RootNode.Attributes.Append($RootNodeNameAttribute) | out-null

                _Log "_RealizeXaml: $($this) Added root node Name attribute: $($RootNodeNameAttribute.Value)"
            }

            #Find and store the name attributes that are present in this component
            $this._Xaml.SelectNodes("//@Name") | % {

                #Prepend any name attributes that begin with ":" with this component's XamlNamePrefix
                #Users should not reasonbaly use ":" to begin absolute component names, but might reasonably regular names for absolute components
                #This will help later so that those WPF components can be traced to this component for use during the init process.
                if ($_.Value.StartsWith(":")) {
                    $newName = $this._XamlNamePrefix + ($_.Value -replace ":", "")
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

            #Create a ref mapping for "this". It will point to the root node. 
            #The root node is guaranteed to have a Name attribute due to setup above.
            #Additionally, the root node may have been renamed in the step above.
            $this._Refs["this"] = $RootNodeNameAttribute.Value

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
            _Throw ("_RealizeXaml: Error", $_)
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

            #Set the tag on the WPF object to be this component
            #this will allow us to find framework components by the tag on the WPF component
            #when we traverse the WPF component tree.
            $Wpf.Tag = $this

            #Set WFP component for all child components
            $this.__SetWpfDeep($Wpf)

            _Log "_RealizeWpf: $($this) Complete"
        } catch {
            _throw ("_RealizeWpf: Error realizing WPF for component $($this)", $_)
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
            _Throw ("__InitRefs: Error", $_)
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
            _Throw ("_ReplaceXmlNode: Error replacing xml node", $_)
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
                $refs = $this.refs
                $props = $this.Props
                $this._InitScript.InvokeWithContext($null, ((Get-Variable "this"), (Get-Variable "refs"), (Get-Variable "props")), ($this))
            }

            $this._Children.Keys | % {
                $this._Children[$_]._InitDeep()
            }
        } catch {
            _Throw ("_InitDeep: $($this) Error calling init function, Check your Init function for the following error: $($_.Exception.Message)", $_)
        }
    }

    #Assign the script that will be called to generate xaml.
    function Xaml([ScriptBlock] $XamlScript) {
        try {
            $this._XamlScript = $XamlScript
        } catch {
            _Throw ("Xaml: Error", $_)
        }
    }

    #Assign the script that will be called to initialize the wpf objects.
    function Init([ScriptBlock] $InitScript) {
        try {
            $this._InitScript = $InitScript
        } catch {
            _Throw ("Init: Error", $_)
        }
    }

    #Assign the script that will be called to clean up this component when it is unmounted
    function Destroy([ScriptBlock] $DestroyScript) {
        try {
            $this._DestroyScript = $DestroyScript
        } catch {
            _Throw ("Destroy: Error", $_)
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
        $msg >> "_SimpleComponent.log"
    }
}

Function _Throw($msg, $_) {
    _Log("$msg $($_ | out-string)")
    throw new-object Exception $msg, $_.Exception
}