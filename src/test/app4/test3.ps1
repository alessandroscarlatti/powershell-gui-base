import-module "../../main/WpfComponent/SimpleComponent.psm1" -force
try { [CustomHashtable] | Out-Null } catch { Add-Type -TypeDefinition (get-content -raw "./CustomHashtable.cs") -Language CSharp }

$ErrorActionPreference = "Stop"


$__WINDOW__ = {
    param($this)

    $this.Init{
        param($this)

        $this.refs.txtCount.DataContext = $this.props.DataContext

        $this.refs.btnIncrement.Add_Click((New-SafeScriptBlock {
                write-host "count is $($script:this.props.DataContext.MyCount)"
                ([int] $script:this.props.DataContext.MyCount)++
        }.GetNewClosure()))
    }

@"
    <Window $($this.xmlns)>
        <StackPanel>
            <TextBox Name=":txtCount" Text="{Binding [MyCount]}"></TextBox>
            <Button Name=":btnIncrement">Increment Me</Button>
        </StackPanel>
    </Window>
"@
}


$store = @{
    MyCount = 10
}
 
# Create a datacontext for the textbox and set it
[CustomHashtable] $DataContext = New-Object CustomHashtable

$DataContext.MyCount = [int] 10

$Hash = @{}
$Hash.Window = Mount-Component $__WINDOW__ @{ DataContext = $DataContext}
 
# Show the window
[void]$Hash.Window.Dispatcher.InvokeAsync{$Hash.Window.ShowDialog()}.Wait()
