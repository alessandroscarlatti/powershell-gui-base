param($context)

try {
    write-host "add another button."

    #build event
    $context.ButtonId++

    $todo = @{
        id = $context.ButtonId;
        text = "new todo $($context.ButtonId)";
    }

    #update store
    $context.store.todos += $todo.text
    $context._store.Save()
    
    #publish message to update listeners
    $context._store.Dispatch(@{
        type = "ADD_TODO";
        todo = $todo;
    })
} catch {
    write-host "error: $($_.Exception.GetBaseException().ToString())"
}