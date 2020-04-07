param($this)

import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"
$__TODO__ = import-component "$($this.context.AppDir)/Todo.ps1"

#subscribe to events
$subscription = $this.context._store.subscribe({
    param($store, $action)

    if ($action.type -eq "ADD_TODO") {
        #create a new button
        #and add it to the stack panel
        $newButton = mount-component $script:__TODO__ @{ text = $action.text} $script:this.context
        $script:this.refs.this.Children.Add($newButton)
    }
}.GetNewClosure())

$todos = @()
foreach($todo in $this.context.store.todos) {
    $todos += Mount-Child $__TODO__ $this @{ text = $todo }
}

@"
<StackPanel $($this.xmlns)>
    $(Mount-Children $todos)
</StackPanel>
"@