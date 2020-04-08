param($this)

import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"

$this.Init({
    $this.refs.this.Add_Click((New-SafeScriptBlock {
        write-host "clicked button $($script:this.props.id)"
        write-host "context app name is $($script:this.context.App.name)"
    }.GetNewClosure()))
})

@"
<Button $($this.xmlns)>Another button $($this.props.id)</Button>
"@