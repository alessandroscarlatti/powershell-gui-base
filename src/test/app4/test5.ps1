import-module "../../main/WpfComponent/SimpleComponent.psm1" -force

$ErrorActionPreference = "Stop"

$__WINDOW__ = {
    @"
    <Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="MainWindow" Height="350" Width="525"
    >
<StackPanel HorizontalAlignment="Center">
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,100,0,20">
        <TextBox Text="{Binding LeftSideNumber, ElementName=root}" 
                 PreviewTextInput="ValidateIsNumber" Width="50" Margin="0,0,10,0"/>
        <TextBlock>X</TextBlock>
        <TextBox Text="{Binding RightSideNumber, ElementName=root}" 
                 PreviewTextInput="ValidateIsNumber" Width="50" Margin="10,0,10,0"/>
        <TextBlock Margin="0,0,10,0">=</TextBlock>
        <TextBlock x:Name="Answer"/>
        <x:Code>
            <![CDATA[
                private System.Text.RegularExpressions.Regex isNumberRegex = 
                  new System.Text.RegularExpressions.Regex(@"^-*[0-9,\.]+$");

                public string LeftSideNumber { get; set; }
                public string RightSideNumber { get; set; }
                
                void CalculateClicked(object sender, RoutedEventArgs e)
                {
                    var left = Convert.ToDouble(LeftSideNumber);
                    var right = Convert.ToDouble(RightSideNumber);
                    Answer.Text = Convert.ToString(left * right);
                }

                void ValidateIsNumber(object sender, TextCompositionEventArgs e)
                {
                    e.Handled = !isNumberRegex.IsMatch(e.Text);
                }
            ]]>
        </x:Code>
    </StackPanel>
    <Button Click="CalculateClicked" Width="100">Calculate</Button>
</StackPanel>
</Window>
"@
}

try {
    #Create and show the window
    Mount-Component $__WINDOW__ | show-dialog
} catch {
    $_ | Out-StackTrace
    throw $_.Exception
}