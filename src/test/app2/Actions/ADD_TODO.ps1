param($props)

#build new todo
$props.context.store.state.todoId++

$todo = @{
    id = $props.context.store.state.todoId;
    text = $props.text;
    status = "TODO"
}

#dispatch event
$props.context.store.Dispatch(@{
    type = "ADD_TODO";
    todo = $todo;
})