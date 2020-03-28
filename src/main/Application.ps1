$ErrorActionPreference = "Stop"

import-module ./src/gui/WpfApp.psm1

$WpfApp = WpfApp

&$WpfApp.Init
$WpfApp.Component.ShowDialog()
