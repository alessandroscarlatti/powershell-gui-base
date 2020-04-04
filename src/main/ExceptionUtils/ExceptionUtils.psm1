#Create a new exception with root cause
function New-Exception($msg, $cause) {
    if ($cause -is [Management.Automation.ErrorRecord]) {
        #This is an error record.
        #Add the error record to the exception so that is easier to unwind the stacktrace.
        $e = new-object Exception ($msg, $cause.Exception)
        $e | add-member -Name "ErrorRecord" -Value $causeErrorRecord -MemberType NoteProperty -Force
    } elseif ($cause -is [Exception]) {
        #This is an exception, just create the exception.
        $e = new-object Exception ($msg, $cause)
    } else {
        throw new-object Exception "Unrecognized object type: $cause"
    }

    return $e
}

#Print stack trace from error record or exception
function Out-StackTrace([Parameter(Mandatory, ValueFromPipeline)] $_) {
    process {
        function _PrintRootCauseException($e) {
            write-host "caused by $($e.ErrorRecord | out-string)"
            write-host "$($e.ErrorRecord.ScriptStackTrace)"
        }
        function _VisitException($e) {
            if ($e.InnerException) {
                #this is not the root exception
                write-host "caused by $($e.Message)"
                if ($e.ErrorRecord) {
                    #print the stacktrace up to this point, if there is one available
                    write-host $e.ErrorRecord.ScriptStackTrace
                }
                _VisitException($e.InnerException)
            } else {
                #this is the root exception
                _PrintRootCauseException($e)
            }
        }

        if ($_ -is [Management.Automation.ErrorRecord]) {
            #this is an error record
            #so print the error invocation details
            write-host ($_ | out-string)
            write-host $_.Exception
            write-host "at $($_.ScriptStackTrace)"
            $e = $_.Exception
        } elseif ($_ -is [Exception]) {
            #this is an exception
            $e = $_
        } else {
            throw new-object Exception "Unrecognized object type: $($_)"
        }
        
        if ($e.InnerException) {
            #there is an inner exception so visit it
            _VisitException($e.InnerException)
        } else {
            #there is no inner exception, just print the root cause
            _PrintRootCauseException($e)
        }
    }
}
