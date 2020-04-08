param($props)

write-host "add another button."

#build new todo
$props.context.ButtonId++

$todo = @{
    id = $props.ButtonId;
    text = $props.text;
}

#dispatch event
$props.context.store.Dispatch(@{
    type = "ADD_TODO";
    todo = $todo;
})