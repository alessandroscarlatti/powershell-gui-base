param($this)

import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"

#get the todo text
$this.vars.BuildTodoText = {
    param($todo)
    if ($todo.status -eq "DONE") {
        return "DONE - " + $todo.text
    } else {
        return "TODO - " + $todo.text
    }
}

#get the toggle button text
$this.vars.BuildToggleText = {
    param($todo)
    if ($todo.status -eq "DONE") {
        return "MARK TODO"
    } else {
        return "MARK DONE"
    }
}

$this.Init({
    param($this)

    #Add click handler
    $this.refs.toggle.Add_Click((New-SafeScriptBlock {
        & $script:this.context.actions.INVERT_TODO_STATUS @{
            context = $script:this.context;
            todo = $script:this.props.todo;
        }
    }.GetNewClosure()))

    #invert the text on the label when the status changes
    [void]$this.context.store.subscribe((New-SafeScriptBlock {
        param($state, $action)

        if ($action.type -eq "INVERT_TODO_STATUS") {
            if ($action.todo.id -eq $script:this.props.todo.id) {
                $script:this.refs.toggle.Content = &$script:this.vars.BuildToggleText $script:props.todo
                $script:this.refs.todoText.Content = &$script:this.vars.BuildTodoText $script:props.todo
            }
        }
    }.GetNewClosure()))
})

@"
<StackPanel $($this.xmlns) Orientation="Horizontal">
    <Button Name=":toggle">$(&$this.vars.BuildToggleText $this.props.todo)</Button>
    <Label Name=":todoText">$(&$this.vars.BuildTodoText $this.props.todo)</Label>
</StackPanel>
"@