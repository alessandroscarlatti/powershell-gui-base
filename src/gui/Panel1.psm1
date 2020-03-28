$ErrorActionPreference = "Stop"
Import-Module ./src/gui/utils/WpfUtils.psm1

Function Xaml {
	[xml]@"
			<StackPanel Margin="10">
				<TextBlock 
					Width="300"
					Margin="0,10"
					TextWrapping="Wrap">
					Persist this value after closing the application.
				</TextBlock>
				<TextBox Name="textBox2"
						Text="Close App"
						AllowDrop="true"
				/>
				<Button Name="button2"
					Content="Save and Exit"
					Margin="0,10,0,0"
				/>
			</StackPanel>
"@
}
Function Init($Component) {
	$Component.button2.Add_Click({
		write-host "button1: clicked."
	})
}
Function Panel1 {
	return . ./src/gui/utils/Create-WpfComponent.ps1
}

Export-ModuleMember -Function Panel1