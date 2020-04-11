import-module "../../main/WpfComponent/SimpleComponent.psm1" -force
try { [CustomHashtable] | Out-Null } catch { Add-Type -TypeDefinition (get-content -raw "./CustomHashtable.cs") -Language CSharp }

$ErrorActionPreference = "Stop"


$__WINDOW__ = {
    param($this)

    # $this.Binding{
    #     param($this)
    #     $this.binding.MyCount = $this.store.MyCount
    # }

    $this.Init{
        param($this)

        $this.vars.binding = [CustomHashtable] (New-Object CustomHashtable)
        $this.vars.binding.MyCount = $props.store.MyCount
        $this.vars.binding.IncrementMe = {
            param($sender, $args)
            write-host "asdf"
        }

        $this.refs.this.DataContext = $this.vars.binding

        # $this.refs.btnIncrement.Add_Click((New-SafeScriptBlock {
        #             write-host "count is $($script:this.vars.binding.MyCount)"
        #             ([int] $script:this.vars.binding.MyCount)++
        #         }.GetNewClosure()))
    }

    @"
    <Window $($this.xmlns)>
        <StackPanel>
            <TextBox Name=":txtCount" Text="{Binding [MyCount]}"></TextBox>
            <Button Name=":btnIncrement" Click="IncrementMe">Increment Me</Button>
        </StackPanel>
    </Window>
"@
}


$store = @{
    MyCount = 10
}

$Hash = @{ }
try {
    $Hash.Window = Mount-Component $__WINDOW__ @{ store = $store }
} catch {
    $_ | Out-StackTrace
    throw $_.Exception
}
 
# Show the window
[void]$Hash.Window.Dispatcher.InvokeAsync{ $Hash.Window.ShowDialog() }.Wait()
