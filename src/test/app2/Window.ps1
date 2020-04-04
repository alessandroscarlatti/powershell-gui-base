param($this)

# imports
import-module "$($this.context.SrcDir)/lib/SimpleComponent.psm1"
$__Button1__ = Import-Component "$($this.context.SrcDir)/Button1.ps1"
$__Button2__ = Import-Component "$($this.context.SrcDir)/Button2.ps1"
$__TodoList__ = Import-Component "$($this.context.SrcDir)/TodoList.ps1"

#Define Behaviors

#create a new button
#and add it to the stack panel
$this.vars._AddButton = {
    try {
        write-host "add another button."
        write-host "stack panel is $($script:this.refs.stackPanel)"
    
        #create a new button
        #and add it to the stack panel
        $newButton = mount-component $script:__Button2__ @{ id = $script:this.context.ButtonId++} $script:this.context
        $script:this.refs.stackPanel.Children.Add($newButton)

        $todos = $script:this.context.store.GetValue("Todos")
        $todos += "new todo $($script:this.context.ButtonId)"
        $script:this.context.store.SetValue("Todos", $todos)
        write-host "done"
    } catch {
        write-host "error: $($_.Exception.GetBaseException().ToString())"
    }
}.GetNewClosure()

@"
<Window $($this.xmlns)
    Icon="C:\Users\pc\IdeaProjects\windows-context-menu-helper\dist\Command_My Command\Gear.ico"
    Title="Stuff and things"
>
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <StackPanel Name="stackPanel">
            $(mount-child $__Button1__ $this @{Click = $this.vars._AddButton})
            <Button Name="button2">Button2 does nothing</Button>
            $(mount-child $__TodoList__ $this)
        </StackPanel>
    </ScrollViewer>
</Window>
"@