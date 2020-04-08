param($props)

#dispatch event
$props.context.store.Dispatch(@{
    type = "INVERT_TODO_STATUS";
    todo = $props.todo;
})