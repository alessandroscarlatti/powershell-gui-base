param($Context)

import-module "$($Context.SrcDir)/main/Store/Store.psm1"
$AppDir = $Context.AppDir

#define default store
$DefaultStore = @{
    Todos = @{
        1 = @{
           id = 1;
           text = "todo1";
           status = "TODO";
        };
        2 = @{
            id = 2;
            text = "todo2";
            status = "TODO";
         }
    }
}

#define actions
$Context.Actions = @{
    ADD_TODO = Import-Action "$AppDir\actions\ADD_TODO.ps1";
    INVERT_TODO_STATUS = Import-Action "$AppDir\actions\INVERT_TODO_STATUS.ps1";
}

#define state transitions
$Reducer = {
    param($state, $action)

    if ($action.type -eq "ADD_TODO") {
        $state.todos[$action.todo.id] = $action.todo
        return
    }

    if ($action.type -eq "INVERT_TODO_STATUS") {
        $currentState = $state.todos[$action.todo.id].status
        if ($currentState -eq "DONE") {
            $state.todos[$action.todo.id].status = "TODO" 
        } else {
            $state.todos[$action.todo.id].status = "DONE" 
        }
        return
    }
}

#Create new store
$Context.Store = new-store "$AppDir\state\store.xml" $DefaultStore $Reducer