param($this)

import-module ./lib/SimpleComponent.psm1

$__Button1 = Import-Component "$($this.context.App.SrcDir)/Button1.ps1"
$__Button2 = Import-Component "$($this.context.App.SrcDir)/Button2.ps1"

$this.vars.id = 23

#Define Behaviors

#create a new button
#and add it to the stack panel
$this.vars._AddButton = {
    try {
        write-host "add another button."
        write-host "stack panel is $($script:this.refs.stackPanel)"
    
        #create a new button
        #and add it to the stack panel
        $newButton = mount-component $script:__Button2 @{ id = $script:this.vars.id++} $script:this.context
        $script:this.refs.stackPanel.Children.Add($newButton)
    } catch {
        write-host "another error: $($_ | out-string)"
    }
}.GetNewClosure()

@"
<Window $xmlns
    Icon="C:\Users\pc\IdeaProjects\windows-context-menu-helper\dist\Command_My Command\Gear.ico"
    Title="Stuff and things"
>
    <StackPanel Name="stackPanel">
        $(mount-child $__Button1 $this @{Click = $this.vars._AddButton})
        <Button Name="button2">Button2 does nothing</Button>
    </StackPanel>
</Window>
"@