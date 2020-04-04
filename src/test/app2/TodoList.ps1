param($this)

import-module "$($this.context.srcdir)/lib/SimpleComponent.psm1"
$__Todo__ = import-component "$($this.context.srcdir)/Todo.ps1"

$todos = @()
foreach($todo in $this.context.store.getValue("Todos")) {
    $todos += Mount-Child $__Todo__ $this @{ text = $todo }
}

@"
<StackPanel $($this.xmlns)>
    $(Mount-Children $todos)
</StackPanel>
"@