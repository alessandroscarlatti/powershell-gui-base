import-module ./ComponentFactory.psm1
$ErrorActionPreference = "Stop"

function Write-Callstack([System.Management.Automation.ErrorRecord]$ErrorRecord=$null, [int]$Skip=1)
{
    Write-Host # blank line
    if ($ErrorRecord)
    {
        Write-Host -ForegroundColor Red "$ErrorRecord $($ErrorRecord.InvocationInfo.PositionMessage)"

        if ($ErrorRecord.Exception)
        {
            Write-Host -ForegroundColor Red $ErrorRecord.Exception
        }

        if ((Get-Member -InputObject $ErrorRecord -Name ScriptStackTrace) -ne $null)
        {
            #PS 3.0 has a stack trace on the ErrorRecord; if we have it, use it & skip the manual stack trace below
            Write-Host -ForegroundColor Red $ErrorRecord.ScriptStackTrace
            return
        }
    }

    Get-PSCallStack | Select -Skip $Skip | % {
        Write-Host -ForegroundColor Yellow -NoNewLine "! "
        Write-Host -ForegroundColor Red $_.Command $_.Location $(if ($_.Arguments.Length -le 80) { $_.Arguments })
    }
}

Describe "ComponentFactoryWpf" {
    It "ShowDialog" {
        $factory = New-ComponentFactory
        $factory.DefineComponent("Window1", {
            param($Component)
            $id = $Component.Id
            $Component.Xaml = [xml]@"
            <Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            Name="Window"
            Title="Available Actions"
            SizeToContent="WidthAndHeight"
            ResizeMode="CanMinimize"
            WindowStartupLocation="CenterScreen"
            MaxHeight="600">
                <StackPanel>
                    <Button Name="button1">Stuff and Things</Button>
                    <_Framework_SomeComponent1 />
                    <_Framework_SomeComponent2 />
                </StackPanel>
            </Window>
"@

            $Component.Children["_Framework_SomeComponent1"] = @{
                Xaml = ([xml]'<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent1</Button>');
            }

            $Component.Children["_Framework_SomeComponent2"] = @{
                Xaml = ([xml]'<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent2</Button>');
            }

        # $Component.Xaml = [xml]'<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="Window" Title="Available Actions" SizeToContent="WidthAndHeight" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen" MaxHeight="600"><StackPanel><Button Name="button1">Stuff and Things</Button><Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent1</Button><Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">SomeComponent1</Button></StackPanel></Window>'


# <_Framework_SomeComponent1>asdf</_Framework_SomeComponent1>
# <_Framework_SomeComponent2 />

            # $Component.Init {
            #     $Component.children._button1.wpf.AddClick({
            #         write-host "clicked"
            #     })
            # }
        })

        $window1 = $factory.NewComponent("Window1")
        $factory._InitWpf($window1)
        write-host "Window WPF: $($window1.Wpf)"
        $window1.Wpf.ShowDialog()

    }
}