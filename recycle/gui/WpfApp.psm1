$ErrorActionPreference = "Stop"
Import-Module ./src/gui/utils/WpfUtils.psm1

Function Xaml {
	[xml]@"
	<Window
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		x:Name="Window"
		Title="Available Actions"
		SizeToContent="WidthAndHeight"
		ResizeMode="CanMinimize"
		WindowStartupLocation="CenterScreen"
		MaxHeight="600"
		>
		<ScrollViewer VerticalScrollBarVisibility="Auto">
			<StackPanel Margin="10">
				<TextBlock 
					Width="300"
					Margin="0,10"
					TextWrapping="Wrap">
					Persist this value after closing the application.
				</TextBlock>
				<TextBox Name="textBox1"
						Text="Close App"
						AllowDrop="true"
				/>
				<Button Name="buttonAction1"
					Content="Save and Exit"
					Margin="0,10,0,0"
				/>
				$()
			</StackPanel>
		</ScrollViewer>
	</Window>
"@
}
Function Init($Component) {
	$Component.buttonAction1.Add_Click({
		write-host "button1: clicked."
	})
}
Function WpfApp {
	return . ./src/gui/utils/Create-WpfComponent.ps1
}

Export-ModuleMember -Function WpfApp