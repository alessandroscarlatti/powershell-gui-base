import-module ./Store.psm1 -force

$ErrorActionPreference = "Stop"

Describe "Store" {
    It "saves values from store modified in separate object variable" {
        $store1 = New-Store "TestStores/TestStore2.xml" @{ var1 = "val1" } -ForceDefault

        #extract store value to a variable
        #modify value inside the variable
        $map = $store1.GetState()
        $map.var1 = "val2"

        #save the store
        $store1.Save()

        #assert that the store value has been updated
        $store2 = New-Store "TestStores/TestStore2.xml"
        $store2.GetState().var1 | should be "val2"
    }

    It "stores a primitive string value" {
        $store1 = New-Store "TestStores/TestStore4.xml" "line1`nline2" -ForceDefault

        #assert store is created properly
        $store1.GetState() | should be "line1`nline2"

        #set value and assert change is made
        $store1.SetState("asdfqwer")
        $store1.GetState() | should be "asdfqwer"

        #assert value is not committed
        $store2 = New-Store "TestStores/TestStore4.xml"
        $store2.GetState() | should be "line1`nline2"

        #now save the store
        $store1.Save()

        #load another store
        #assert value was saved
        $store3 = New-Store "TestStores/TestStore4.xml"
        $store3.GetState() | should be "asdfqwer"
    }

    It "stores a null value" {
        #null value is the default default value
        $store1 = New-Store "TestStores/TestStore5.xml" -ForceDefault

        #assert store is created properly
        #assert null value is created by default
        $store1.GetState() | should be $null

        #set value and assert change is made
        $store1.SetState($null)
        $store1.GetState() | should be $null

        #now save the store
        $store1.Save()

        #load another store
        #assert value was saved
        $store2 = New-Store "TestStores/TestStore5.xml"
        $store2.GetState() | should be $null
    }
}

Describe "Events" {
    It "subscription is called back on dispatch without reducer" {

        $state = @{
            var2 = "val2"
        }

        $store = New-Store "TestStores/TestStore6.xml" $state -ForceDefault
        
        $TestResults = @{
            callback1Invoked = $false;
            callback2Invoked = $false;
        }

        #create two susbscriptions
        $subscription1 = $store.subscribe({
            param($state, $action)
            $script:TestResults.callback1Invoked = $true
        }.GetNewClosure())

        $subscription2 = $store.subscribe({
            param($state, $action)
            $script:TestResults.callback2Invoked = $true
        }.GetNewClosure())

        #dispatch an action
        $store.Dispatch(@{
            type = "SOME_ACTION";
            var1 = "val1";
        })

        #callbacks should have been invoked after subscribe and dispatch
        $TestResults.callback1Invoked | should be $true
        $TestResults.callback2Invoked | should be $true

        #now unsubscribe
        $subscription1.Unsubscribe()
        $subscription2.Unsubscribe()

        #reset the test results
        #they should stay false this time
        #since we are unsubscribed
        $TestResults.callback1Invoked = $false
        $TestResults.callback2Invoked = $false

        $store.Dispatch(@{
            type = "SOME_ACTION";
            var1 = "val1";
        })

        #callbacks should not be invoked after unsubscribe
        $TestResults.callback1Invoked | should be $false
        $TestResults.callback2Invoked | should be $false
    }

    It "updates state when reducer function provided" {
        $state = @{
            var2 = "val2"
        }

        $reducer = { 
            param($state, $action)
            $state.var2 = $state.var2 + $action.var1
        }

        $store = New-Store "TestStores/TestStore6.xml" $state $reducer -ForceDefault
        
        $TestResults = @{
            callback1Invoked = $false;
            callback2Invoked = $false;
        }

        #create two susbscriptions
        $subscription1 = $store.subscribe({
            param($state, $action)
            $script:TestResults.callback1Invoked = $true

            #state should be updated
            $state.var2 | should be "val2val1"
        }.GetNewClosure())

        $subscription2 = $store.subscribe({
            param($state, $action)
            $script:TestResults.callback2Invoked = $true

            #state should be updated
            $state.var2 | should be "val2val1"
        }.GetNewClosure())

        #dispatch an action
        $store.Dispatch(@{
            type = "SOME_ACTION";
            var1 = "val1";
        })

        #callbacks should have been invoked after subscribe and dispatch
        $TestResults.callback1Invoked | should be $true
        $TestResults.callback2Invoked | should be $true
    }
}