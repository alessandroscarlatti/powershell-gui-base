$ErrorActionPreference = "Stop"

try { [Codebehind1] | Out-Null } catch { 
    Add-Type -TypeDefinition (get-content -raw "./Codebehind1.cs") -Language CSharp `
    -ReferencedAssemblies ("PresentationFramework", "PresentationCore", `
    "WindowsBase", "System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089", `
    "C:\Windows\Microsoft.Net\assembly\GAC_MSIL\System.Windows.Forms\v4.0_4.0.0.0__b77a5c561934e089\System.Windows.Forms.dll") `
    -PassThru -OutputAssembly "C:\Users\pc\Desktop\ps-gui-base\src\Codebehind1.dll"
}

try { [Command1] | Out-Null } catch { 
    Add-Type -TypeDefinition (get-content -raw "./Command1.cs") -Language CSharp
    # -ReferencedAssemblies ("PresentationFramework", "PresentationCore", `
    # "WindowsBase", "System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089", `
    # "C:\Windows\Microsoft.Net\assembly\GAC_MSIL\System.Windows.Forms\v4.0_4.0.0.0__b77a5c561934e089\System.Windows.Forms.dll") `
    # -PassThru -OutputAssembly "C:\Users\pc\Desktop\ps-gui-base\src\Codebehind1.dll"
}

[Environment]::CurrentDirectory = "C:\Users\pc\Desktop\ps-gui-base\src"
[System.Reflection.Assembly]::LoadWithPartialName("Codebehind1234")

import-module "../../main/WpfComponent/SimpleComponent.psm1" -force



$__WINDOW__ = {
    param($this)

    $this.Init{
        param($this)

        #define bindings
        $this.binding.Command1 = [Command1] (new-object Command1)
        # $this.binding.Command2 = [System.Reflection.MethodInfo] $this.binding.Command1.GetMethodInfo()
        $this.binding.MyCount = $this.props.store.MyCount
        $this.binding.ListItems = $this.props.store.ListItems
        $this.binding.MyObject = @{
            Var1 = [int] 19
        }
        $this.binding.ListItems = new-synclist @{
            Items = $this.props.store.ListItems;
            Target = $this.refs.itemsControl.Items;
            Map = {
                param($item)
                return mount-component { param($this)
                    $this.Init{ param($this)
                        $this.refs.this.Add_Click({
                            write-host "clicked $($script:this.props.item.text)"
                        }.GetNewClosure())
                        write-host "adf"
                    }
                    "<Button $($this.xmlns)>$($this.props.item.text)</Button>" 
                } @{ item = $item }
            }.GetNewClosure()
        }

        $this.binding.Derive{
            param($this)
            $this.binding.MyCountPlusOne = $this.binding.MyCount + 1
        }

        #define events
        $this.refs.btnIncrement.Add_Click((New-TryCatchBlock {
            ([int] $script:this.binding.MyObject.Var1)++
            ([int] $script:this.binding.MyCount)++

            #decide whether or not to commit this change...
            # $store.MyCount = $script:this.binding.MyCount
        }.GetNewClosure()))
    }

    @"
    <Window $($this.xmlns) xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
        <StackPanel>
            <TextBox Text="{Binding [MyCount]}"></TextBox>
            <TextBox Text="{Binding [MyCountPlusOne]}"></TextBox>
            <TextBox Text="{Binding [MyObject][Var1]}"></TextBox>
            <Button Name=":btnIncrement">Increment Me</Button>
            <Button Command="{Binding [Command1]}">Increment Me</Button>
            <ItemsControl Name=":itemsControl"></ItemsControl>
        </StackPanel>
    </Window>
"@
}

# <ItemsControl.ItemTemplate>
# <DataTemplate>
#     <StackPanel Name="asdf" Orientation="Horizontal">
#         <TextBlock Text="{Binding [Text]}" />
#         <Button Command="{Binding [Command]}">Click</Button>
#     </StackPanel>
# </DataTemplate>
# </ItemsControl.ItemTemplate>

$store = @{
    MyCount = 10;
    ListItems = @(
        @{ text = "asdf"; Command = [Command1] (new-object Command1) },
        @{ text = "qwer"; Command = [Command1] (new-object Command1) },
        @{ text = "zxcv"; Command = [Command1] (new-object Command1) }
    );
}

try {
    #Create and show the window
    Mount-Component $__WINDOW__ @{ store = $store } | show-dialog
} catch {
    $_ | Out-StackTrace
    throw $_.Exception
}