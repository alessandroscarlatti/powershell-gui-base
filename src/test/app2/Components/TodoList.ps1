param($this)

import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"
$__TODO__ = import-component "$($this.context.AppDir)/Components/Todo.ps1"

#subscribe to events
$this.context.store.subscribe({
    param($state, $action)

    if ($action.type -eq "ADD_TODO") {
        #create a new button
        #and add it to the stack panel
        $newButton = mount-component $script:__TODO__ @{ todo = $action.todo } $script:this.context
        $script:this.refs.this.Children.Add($newButton)

        #this could ALSO be implemented as a different rendering strategy...
        #for example, could delete all todos and rerender all.
        #the choice is left up to the component.
    }
}.GetNewClosure()) | out-null

$todos = @()
foreach($key in $this.context.store.state.todos.keys) {
    $todos += $this | Mount-Child $__TODO__ @{ todo = $this.context.store.state.todos[$key] }
}

@"
<StackPanel $($this.xmlns)>
    $(Mount-Children $todos)
</StackPanel>
"@