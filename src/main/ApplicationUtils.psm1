Function Log-Debug($msg) {
    if ($env:DEBUG -eq "true") { 
        write-host $msg
    }
}