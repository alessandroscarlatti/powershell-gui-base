import-module ./lib/SimpleComponent.psm1

set-psdebug -trace 2

$ErrorActionPreference = "Stop"

$App = @{}
$App.SrcDir = Split-Path $script:MyInvocation.MyCommand.Path
$App.Name = "some app"

$App.Service1 = {
    #some service defined here...
}

$__Window = Import-Component "$($App.SrcDir)/Window.ps1"
$Window = mount-component $__Window @{} @{App = $App}

# This makes it pop up
$Window.ShowDialog()