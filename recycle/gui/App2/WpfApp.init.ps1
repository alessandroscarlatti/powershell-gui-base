param($Component)

write-host "init component: $Component"
$Component.buttonAction1.Add_Click({
    write-host "button1: clicked."
})