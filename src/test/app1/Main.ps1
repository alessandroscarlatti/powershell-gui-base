$ErrorActionPreference = "stop"

$App = @{}
$App.AppDir = Split-Path $script:MyInvocation.MyCommand.Path

import-module "$($App.AppDir)/../../main/WpfComponent/SimpleComponent.psm1"

$__WINDOW__ = Import-Component "$($App.AppDir)/Window.ps1"

$Window = Mount-Component $__WINDOW__ @{App = $App}
$Window.ShowDialog()