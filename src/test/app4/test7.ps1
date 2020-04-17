$ErrorActionPreference = "Stop"
import-module "../../main/WpfComponent/SimpleComponent.psm1" -force

$__TODO__ = { 
    param($this)
    $this.Init{ param($this)
        $this.refs.this.Add_Click({
            write-host "clicked $($script:this.props.item.text)"
        }.GetNewClosure())
    }
    "<Button $($this.xmlns)>$($this.props.item.text)</Button>"
}

$__WINDOW__ = {
    param($this)

    $this.Init{
        param($this)

        #set up bindings
        $this.binding.MyCount = $this.props.store.MyCount
        $this.binding.MyObject = @{
            Var1 = [int] 19
        }

        #bind list of buttons
        $this.binding.ListItems = new-synclist @{
            Items = $this.props.store.ListItems;
            Target = $this.refs.itemsControl.Items;
            Map = {
                param($item)
                return mount-component $script:this.context.__TODO__ @{ item = $item }
            }.GetNewClosure()
        }

        #derived bindings
        $this.binding.Derive{
            param($this)
            $this.binding.MyCountPlusOne = $this.binding.MyCount + 1
        }

        #add todo
        $this.refs.btnIncrement.Add_Click((New-TryCatchBlock {
            ([int] $script:this.binding.MyObject.Var1)++
            ([int] $script:this.binding.MyCount)++
            $script:this.binding.ListItems.Add(@{
                text = "todo $($script:this.binding.MyCount)"
            })

            write-host "done"

            #decide whether or not to commit this change...
            # $store.MyCount = $script:this.binding.MyCount
        }.GetNewClosure()))

        #remove todo
        $this.refs.btnDecrement.Add_Click((New-TryCatchBlock {
            ([int] $script:this.binding.MyObject.Var1)--
            ([int] $script:this.binding.MyCount)--

            $script:this.binding.ListItems.RemoveAt($script:this.binding.ListItems.Count - 1)
        }.GetNewClosure()))
    }

    @"
    <Window $($this.xmlns) xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
        <StackPanel>
            <TextBox Text="{Binding [MyCount]}"></TextBox>
            <TextBox Text="{Binding [MyCountPlusOne]}"></TextBox>
            <TextBox Text="{Binding [MyObject][Var1]}"></TextBox>
            <Button Name=":btnIncrement">Increment Me</Button>
            <Button Name=":btnDecrement">Decrement Me</Button>
            <ItemsControl Name=":itemsControl"></ItemsControl>
        </StackPanel>
    </Window>
"@
}

$store = @{
    MyCount = 10;
    ListItems = @(
        @{ text = "asdf"; },
        @{ text = "qwer"; }
    );
}

$props = @{ 
    store = $store 
}

$context = @{
    __TODO__ = $__TODO__
}

try {
    #Create and show the window
    Mount-Component $__WINDOW__ $props $context | show-dialog
} catch {
    $_ | Out-StackTrace
    throw $_.Exception
}