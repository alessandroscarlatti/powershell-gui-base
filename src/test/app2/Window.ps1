param($this)

# imports
import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"
$__Button1__ = Import-Component "$($this.context.AppDir)/Button1.ps1"
$__TodoList__ = Import-Component "$($this.context.AppDir)/TodoList.ps1"

#Define Behaviors

#create a new button
#and add it to the stack panel
$ADD_TODO = {
    & "$($script:this.context.AppDir)/Actions/ADD_TODO.ps1"($script:this.context)
}.GetNewClosure()

@"
<Window $($this.xmlns)
    Icon="C:\Users\pc\IdeaProjects\windows-context-menu-helper\dist\Command_My Command\Gear.ico"
    Title="Stuff and things"
>
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <StackPanel Name=":stackPanel">
            $(mount-child $__Button1__ $this @{Click = $ADD_TODO})
            <Button Name=":button2">Button2 does nothing</Button>
            $(mount-child $__TodoList__ $this)
        </StackPanel>
    </ScrollViewer>
</Window>
"@