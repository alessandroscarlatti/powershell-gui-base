param($context)

try {
    write-host "add another button."

    $context.ButtonId++

    $todo = @{
        id = $context.ButtonId;
        text = "new todo $($context.ButtonId)";
    }

    $context.store.todos += $todo.text
    $context._store.Save()
    
    $context._store.Dispatch(@{
        type = "ADD_TODO";
        todo = $todo;
    })
} catch {
    write-host "error: $($_.Exception.GetBaseException().ToString())"
}