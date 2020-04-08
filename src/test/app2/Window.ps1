param($this)

# imports
import-module "$($this.Context.SrcDir)/main/WpfComponent/SimpleComponent.psm1"
$__Button1__ = Import-Component "$($this.context.AppDir)/Button1.ps1"
$__TodoList__ = Import-Component "$($this.context.AppDir)/TodoList.ps1"

#Define Behaviors

#create a new button
#and add it to the stack panel
$ADD_TODO = New-SafeScriptBlock {
    &$script:this.context.actions.ADD_TODO @{
        context = $script:this.context;
        text = $script:this.refs.textBoxTodo.text
    }
}.GetNewClosure()

@"
<Window $($this.xmlns)
    Icon="C:\Users\pc\IdeaProjects\windows-context-menu-helper\dist\Command_My Command\Gear.ico"
    Title="Stuff and things"
>
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <StackPanel Name=":stackPanel">
            <TextBox Name=":textBoxTodo"></TextBox>
            $($this | mount-child $__Button1__ @{Click = $ADD_TODO})
            <Button Name=":button2">Button2 does nothing</Button>
            $($this | mount-child $__TodoList__)
        </StackPanel>
    </ScrollViewer>
</Window>
"@