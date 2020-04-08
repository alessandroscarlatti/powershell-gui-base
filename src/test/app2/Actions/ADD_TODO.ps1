param($props)

#build new todo
$props.context.ButtonId++

$todo = @{
    id = $props.context.ButtonId;
    text = $props.text;
    status = "TODO"
}

#dispatch event
$props.context.store.Dispatch(@{
    type = "ADD_TODO";
    todo = $todo;
})