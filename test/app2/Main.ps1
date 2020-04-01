import-module ./lib/SimpleComponent.psm1
$ErrorActionPreference = "Stop"

set-psdebug -trace 2

$App = @{}
$App.SrcDir = Split-Path $script:MyInvocation.MyCommand.Path
$App.Name = "some app"
$App.ButtonId = 23
$App.Todos = @(
    "asdf",
    "qwer",
    "zxcv"
)

$App.Service1 = {
    #some service defined here...
}

$__Window = Import-Component "$($App.SrcDir)/Window.ps1"
$Window = Mount-Component $__Window @{} @{App = $App}

# This makes it pop up
$Window.ShowDialog()