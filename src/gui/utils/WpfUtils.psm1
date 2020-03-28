$ErrorActionPreference = "Stop"
Import-Module ./src/main/ApplicationUtils.psm1

Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

Function Create-WpfComponent($params) {
    $ErrorActionPreference = "Stop"

    #Create empty component
    $Component = @{}

    #Load XAML into WPF component
    $Xaml = &$params.Xaml
    Log-Debug "Load WPF Xaml: $Xaml"
    $Component.Component = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $Xaml))
    
    #Prepare WPF component user Init function
    $Component.Init = { 
        Import-Module ./src/main/ApplicationUtils.psm1
        Log-Debug "Init WPF Component: $($Component.Name)"
        &$params.Init -ArgumentList $Component
    }.GetNewClosure()

    #Assign WPC child component variables
    $Xaml.SelectNodes("//*[@Name]") | % { 
        Log-Debug "WFP Component: $($_.Name)"
        $Component[$_.Name] = $Component.Component.FindName($_.Name) 
    }
    
    #Finished creating component
    #Init has NOT been called.
    return $Component
}