$_id = 0
$ErrorActionPreference = "Stop"

#Create a new store with the given file.
#If the file does not exist, it will be created.
function New-Store($file, $defaultValue = $null, [switch] $ForceDefault) {
    $store = New-Module -AsCustomObject -ArgumentList @($file, $defaultValue, $ForceDefault.IsPresent, $script:_id++) -ScriptBlock $_StoreDef
    $store._InitStore()
    return $store
}

$_StoreDef = {
    param($file, $defaultValue, $ForceDefault, $id = "default")
    $ErrorActionPreference = "Stop"

    $_ConvertToString = {
        param($obj)
        [System.Management.Automation.PSSerializer]::Serialize($obj, 10)
    }

    $_ConvertFromString = {
        param($str)
        [System.Management.Automation.PSSerializer]::Deserialize($str)
    }

    Function _Log($msg) {
        if ($env:DEBUG) {
            write-host $msg
            $msg >> "_Store.log"
        }
    }
    Function _Throw($msg, $e) {
        _Log $msg
        _Log ($e | out-string)
        throw new-object Exception ($msg, $e.Exception)
    }

    Function _ToAbsolutePath($path) {
        try {
            #will throw a non-terminating error if path does not exist
            Resolve-Path $path -ea stop
        } catch {
            #target object is the path that does not exist
            $_.TargetObject
        }
    }
    
    $_Store = $null; #the actual object representing the store
    $_SubscriptionIndex = 0; #the index for the next subscription id
    $_Subscribers = @{} #map of all susbcribers, eg subscriber_0 => { ...some code runs on event }
    $file = _ToAbsolutePath($file) #convert file to absolute path

    _Log "Store_$id : Creating store from file: $file"

    function _InitStore() {
        #if force create default store, create it

        #if store does not exist, create it
        if (!$this._StoreExists()) {
            $this._CreateDefaultStore()
        } elseif ($ForceDefault) {
            _Log("Store_$id : Forcing Default store: $($defaultValue | out-string)")
            $this._CreateDefaultStore()
        }

        try {
            #Load the store
            $this._TryLoadStore()
        } catch {
            try {
                _Log("Store_$id : Error loading store from file: $file : $($_ | out-string)")
                _Log("Store_$id : Will backup current store and create a new store.")
                #the store was corrupt, try one more time to create store.
                #try to backup the store before overwriting it with an empty store.
                $this._TryBackupStore()
                $this._CreateDefaultStore()
                $this._TryLoadStore()
            } catch {
                #Could not create the store, even after trying to create a new store.
                _Throw("Store_$id : Error loading store (final attempt) from file: $file", $_)
            }
        }
    }

    #Get the value from the store
    function GetValue() {
        return $this._store
    }

    #Set a value in the store
    #By default, this will also commit the store to persistence.
    function SetValue($value) {
        try {
            _Log("Store_$id : Setting value for store: $value")
            $this._store = $value
        } catch {
            _Throw("Store_$id : Error setting value for store: $($value)", $_)
        }
    }

    function Save() {
        $this._TrySaveStore()
    }

    #Dispatch an action to the store
    function Dispatch($action) {
        #call the subscribers
        _CallSubscribers($action)
    }

    function Subscribe($callback) {
        #add the callback to the map
        _Log("Store_$id : adding subscription: $($callback)")
        $subscriberId = "Subscriber_" + $this._SubscriptionIndex++
        $_Subscribers[$subscriberId] = $callback

        #return a subscription object
        #with a single Unsubscribe() method.
        $subscription = new-object -TypeName PSCustomObject
        $subscription | add-member -MemberType ScriptMethod -Name Unsubscribe -Value { 
            $script:this.Unsubscribe($subscriberId) 
        }.GetNewClosure()
        return $subscription
    }

    #Unsubscribe the given subscriber by id, eg "Subscriber_0"
    function Unsubscribe($SubscriberId) {
        #remove the subscriber from the map
        _Log("Store_$id : removing subscription: $($callback)")
        $_Subscribers.Remove($SubscriberId)
    }

    function _CallSubscribers($Action) {
        _Log("Store_$id : call subscribers: $($callback)")
        foreach ($subscriberId in $_Subscribers.Keys) {
            _Log("Store_$id : call subscriber: $($key)")
            #call the subscriber, passing the store and the action
            try {
                &$_Subscribers[$subscriberId] $_Store $Action
            } catch {
                _Throw("Error calling subscriber $($subscriberId)", $_)
            }
        }
    }

    #Return whether or not the store exists in persistence.
    function _StoreExists() {
        #if the file does not exist, the store does not exist
        _Log("Store_$id : Checking if store exists in file: $file")
        return test-path $file
    }

    #Create an empty store in persistence, overwriting any previous store.
    #Create directories if not exists
    function _CreateDefaultStore() {
        _Log("Store_$id : Creating empty store in file: $file")
        md -force (split-path $file) | out-null
        $strStore = &$_ConvertToString($defaultValue)
        set-content $file ($strStore)
    }

    #Try to load the store into memory, otherwise, throw an exception.
    function _TryLoadStore() {
        try {
            _Log("Store_$id : Try to read store from file: $file")
            $this._Store = @{}
            $strStore = (get-content -raw $file)
            $this._Store = &$_ConvertFromString($strStore)
        } catch {
            _Throw("Store_$id : Error reading store from file: $file", $_)
        }
    }

    #Try to backup the store (in the case of an error loading it)
    #Backup the store to a file beside the current store file
    #For example if the current store file is C:\store.json
    #The backup file will be C:\store.json_2020.04.02_31.06.18.backup.json
    function _TryBackupStore() {
        $backupFile = "$($file)_$(get-date -format yyyy.MM.dd_mm.hh.ss).backup.json"
        try {
            _Log("Store_$id : Try to back up store from file: $file")
            _Log("Store_$id : Back up store to file $backupFile")
            set-content $backupFile (get-content -raw $file)
        } catch {
            _Log("Store_$id : Error backing up store to file $backupFile", $_)
        }
    }

    function _TrySaveStore() {
        try {
            _Log("Store_$id : Try to save store to file: $file")
            $_strStore = &$_ConvertToString($_Store)
            _Log("Store_$id : store is: $_strStore")
            set-content $file $_strStore
        } catch {
            _Throw("Error saving store to file: $file", $_)
        }
    }

    Export-ModuleMember -Function *
    Export-ModuleMember -Variable *
}

Export-ModuleMember -Function New-Store