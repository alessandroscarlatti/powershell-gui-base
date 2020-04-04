import-module ./lib/SimpleComponent.psm1

$App = @{}
$App.SrcDir = Split-Path $script:MyInvocation.MyCommand.Path

$App.Service1 = {
    #some service defined here...
}

$__Window = Import-Component "$($App.SrcDir)/Window.ps1"
$Window = ConvertTo-Wpf $__Window @{} @{App = $App}
$Window.ShowDialog()