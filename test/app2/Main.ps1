import-module ./lib/SimpleComponent.psm1
$ErrorActionPreference = "Stop"

set-psdebug -trace 2

$App = @{}
$App.Name = "app2"
$App.ButtonId = 23
$App.DefaultStore = @{
    Todos = @(
        "asdf",
        "qwer",
        "zxcv"
    )
}
$App.SrcDir = Split-Path $script:MyInvocation.MyCommand.Path

$App.Service1 = $null #some service defined here...

$__Window = Import-Component "$($App.SrcDir)/Window.ps1"
$Window = Mount-Component $__Window @{} $App

# This makes it pop up
$Window.ShowDialog()