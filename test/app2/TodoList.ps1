param($this)

import-module ./lib/SimpleComponent.psm1
$__Todo = import-component "$($this.context.app.srcdir)/Todo.ps1"

$todos = @()
foreach($todo in $this.context.app.todos) {
    $todos += Mount-Child $__Todo $this @{ text = $todo }
}

@"
<StackPanel $xmlns>
    $(Mount-Children $todos)
</StackPanel>
"@