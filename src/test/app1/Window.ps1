Init({
    $refs.Button1.Add_Click({
        write-host "clicked button 1"
    })

    $refs.Button2.Add_Click({
        write-host "clicked button 2"
    })

    write-host "Init is running with props $($props | out-string)"
})

@"
<Window $xmlns>
    <StackPanel>
        <Button Name="button1">Button1</Button>
        <Button Name="button2">Button2</Button>
    </StackPanel>
</Window>
"@