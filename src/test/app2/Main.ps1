$workingDir = Split-Path $script:MyInvocation.MyCommand.Path

write-host "working dir= $($workingDir)"

import-module "$workingDir/lib/SimpleComponent.psm1" -force
import-module "$workingDir/lib/Store.psm1" -force

$ErrorActionPreference = "Stop"

# set-psdebug -trace 1

try {
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
    $App.SrcDir = $workingDir

    $App.Store = new-store "config/store.json" $App.DefaultStore

    $App.Service1 = $null #some service defined here...

    $__Window = Import-Component "$($App.SrcDir)/Window.ps1"
    $Window = Mount-Component $__Window @{} $App

    # This makes it pop up
    $Window.ShowDialog()
} catch {
    write-host ($_.Exception.GetBaseException().Message)
    write-host ($_.Exception.GetBaseException().ErrorRecord)
}