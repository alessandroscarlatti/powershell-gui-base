param($this)

$this.Init({
    $this.refs.this.Add_Click({
        write-host "clicked button $($script:this.props.id)"
        write-host "context app name is $($script:this.context.App.name)"
    }.GetNewClosure())
})

@"
<Button $($this.xmlns)>Another button $($this.props.id)</Button>
"@