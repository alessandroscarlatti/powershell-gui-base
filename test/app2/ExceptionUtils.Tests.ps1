import-module ./ExceptionUtils.psm1

function sb_function1 {
    asdf
}

function sb_function2 {
    sb_function1
}

$sb = {
    try {
        sb_function2
    } catch {
        throw New-Exception "sb_error" $_
    }
}

function function1 {
    $sb.InvokeWithContext($null, $null, $null)
}

function function2 {
    try {
        function1
    } catch {
        throw New-Exception "error2" $_
    }
}

function function3 {
    try {
        function2
    } catch {
        throw New-Exception "error3" $_
    }
}

function function4 {
    try {
        function3
    } catch {
        throw New-Exception "error4" $_
    }
}

Describe "ExceptionUtils" {
    It "Prints Stack Trace" {
        try {
            write-host "hello"
            function4
            write-host "world"
        } catch {
            $_ | Out-StackTrace
        }
    }
}

