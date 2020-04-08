param($Context)

import-module "$($Context.SrcDir)/main/Store/Store.psm1"
$AppDir = $Context.AppDir

#define default store
$DefaultStore = @{
    Todos = @(
        "asdf",
        "qwer",
        "zxcv"
    )
}

#define actions
$Context.Actions = @{
    ADD_TODO = Import-Action "$AppDir\actions\ADD_TODO.ps1"
}

#define state transitions
$Reducer = {
    param($state, $action)

    if ($action.type -eq "ADD_TODO") {
        $state.todos += $action.todo.text
    }
}

#Create new store
$Context.Store = new-store "$AppDir\state\store.xml" $DefaultStore $Reducer