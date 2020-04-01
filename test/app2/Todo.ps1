Init({
    $this.vars.done = $false
    $this.refs.this.Add_Click({
        if ($script:this.vars.done) {
            $script:this.vars.done = $false
            $script:this.refs.this.Content = $script:this.props.text
        } else {
            $script:this.vars.done = $true
            $script:this.refs.this.Content = "done"
        }
    }.GetNewClosure())
})

"<Button $xmlns>$($this.props.text)</Button>"