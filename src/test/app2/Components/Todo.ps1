param($this)

import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"

$this.Init({
    param($this)

    $INVERT_TODO_STATUS = New-SafeScriptBlock {
        & $script:this.context.actions.INVERT_TODO_STATUS @{
            context = $script:this.context;
            todo = $script:this.props.todo;
        }
    }.GetNewClosure()

    $this.vars.done = $false
    $this.refs.toggle.Add_Click($INVERT_TODO_STATUS)

    $this.context.store.subscribe((New-SafeScriptBlock {
        param($state, $action)

        if ($action.type -eq "INVERT_TODO_STATUS") {
            if ($action.todo.id -eq $script:this.props.todo.id) {
                if ($state.todos[$script:this.props.todo.id].status -eq "DONE") {
                    $script:this.refs.todoText.Content = "DONE " + $script:this.props.todo.text
                } else {
                    $script:this.refs.todoText.Content = "TODO " + $script:this.props.todo.text
                }
            }
        }
        
    }.GetNewClosure())) | out-null
})

@"
<StackPanel $($this.xmlns) Orientation="Horizontal">
    <Label Name=":todoText">$($this.props.todo.text)</Label>
    <Button Name=":toggle">Toggle</Button>
</StackPanel>
"@