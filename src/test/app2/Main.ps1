try {
    $ErrorActionPreference = "Stop"

    #Setup app
    $Context = @{}
    $Context.AppDir = Split-Path $script:MyInvocation.MyCommand.Path
    $Context.SrcDir = "$($Context.AppDir)\..\..\..\src"
    $Context.Name = "app2"
    $Context.ButtonId = 23

    & "$($Context.AppDir)\State\Store.ps1" ($Context)

    #mount WPF
    import-module "$($Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1" -force
    $__WINDOW__ = Import-Component "$($Context.AppDir)/Components/Window.ps1"
    
    $Window = Mount-Component $__WINDOW__ @{} $Context
    $Window.ShowDialog()
} catch {
    write-host ($_.Exception.GetBaseException().Message)
    write-host ($_.Exception.GetBaseException().ErrorRecord | out-string)
}