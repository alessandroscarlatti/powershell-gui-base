import-module "../../main/WpfComponent/SimpleComponent.psm1" -force

# $result1 = Add-Type -AssemblyName PresentationFramework
# $result2 = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")


# try { [CustomHashtable] | Out-Null } catch { Add-Type -TypeDefinition (get-content -raw "./CustomHashtable.cs") -Language CSharp }
# try { [Codebehind1] | Out-Null } catch { Add-Type -TypeDefinition (get-content -raw "./Codebehind1.cs") -Language CSharp -ReferencedAssemblies ("PresentationFramework", "PresentationCore", "WindowsBase", "System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089", "C:\Windows\Microsoft.Net\assembly\GAC_MSIL\System.Windows.Forms\v4.0_4.0.0.0__b77a5c561934e089\System.Windows.Forms.dll") }

$ErrorActionPreference = "Stop"

$__WINDOW__ = {
    param($this)

    $this.Init{
        param($this)

        #define bindings
        $this.binding.MyCount = $props.store.MyCount

        $this.binding.Derive{
            param($this)
            $this.binding.MyCountPlusOne = $this.binding.MyCount + 1
        }

        #define events
        $this.refs.btnIncrement.Add_Click((New-TryCatchBlock {
            ([int] $script:this.binding.MyCount)++

            #decide whether or not to commit this change...
        }.GetNewClosure()))
    }

    @"
    <Window $($this.xmlns)>
        <StackPanel>
            <TextBox Text="{Binding [MyCount]}"></TextBox>
            <TextBox Text="{Binding [MyCountPlusOne]}"></TextBox>
            <Button Name=":btnIncrement">Increment Me</Button>
        </StackPanel>
    </Window>
"@
}

$store = @{
    MyCount = 10
}

try {
    #Create and show the window
    Mount-Component $__WINDOW__ @{ store = $store } | show-dialog
} catch {
    $_ | Out-StackTrace
    throw $_.Exception
}