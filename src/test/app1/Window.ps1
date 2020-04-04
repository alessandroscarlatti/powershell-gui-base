$this.Init({
    $this.refs.Button1.Add_Click({
        write-host "clicked button 1"
    })

    $this.refs.Button2.Add_Click({
        write-host "clicked button 2"
    })

    write-host "Init is running with props $($this.props | out-string)"
})

@"
<Window $($this.xmlns)>
    <StackPanel>
        <Button Name="button1">Button1</Button>
        <Button Name="button2">Button2</Button>
    </StackPanel>
</Window>
"@