import-module ./Store.psm1 -force

$ErrorActionPreference = "Stop"

Describe "Store" {
    It "saves values from store modified in separate object variable" {
        $store1 = New-Store "TestStores/TestStore2.xml" @{ var1 = "val1" } -ForceDefault

        #extract store value to a variable
        #modify value inside the variable
        $map = $store1.GetValue()
        $map.var1 = "val2"

        #save the store
        $store1.Save()

        #assert that the store value has been updated
        $store2 = New-Store "TestStores/TestStore2.xml"
        $store2.GetValue().var1 | should be "val2"
    }

    It "stores a primitive string value" {
        $store1 = New-Store "TestStores/TestStore4.xml" "line1`nline2" -ForceDefault

        #assert store is created properly
        $store1.GetValue() | should be "line1`nline2"

        #set value and assert change is made
        $store1.SetValue("asdfqwer")
        $store1.GetValue() | should be "asdfqwer"

        #assert value is not committed
        $store2 = New-Store "TestStores/TestStore4.xml"
        $store2.GetValue() | should be "line1`nline2"

        #now save the store
        $store1.Save()

        #load another store
        #assert value was saved
        $store3 = New-Store "TestStores/TestStore4.xml"
        $store3.GetValue() | should be "asdfqwer"
    }

    It "stores a null value" {
        #null value is the default default value
        $store1 = New-Store "TestStores/TestStore5.xml" -ForceDefault

        #assert store is created properly
        #assert null value is created by default
        $store1.GetValue() | should be $null

        #set value and assert change is made
        $store1.SetValue($null)
        $store1.GetValue() | should be $null

        #now save the store
        $store1.Save()

        #load another store
        #assert value was saved
        $store2 = New-Store "TestStores/TestStore5.xml"
        $store2.GetValue() | should be $null
    }
}

Describe "Events" {
    It "subscription is called back on dispatch" {
        $store = New-Store "TestStores/TestStore6.xml" -ForceDefault
        
        $TestResults = @{
            callback1Invoked = $false;
            callback2Invoked = $false;
        }

        #create two susbscriptions
        $subscription1 = $store.subscribe({
            param($store, $action)
            $script:TestResults.callback1Invoked = $true
        }.GetNewClosure())

        $subscription2 = $store.subscribe({
            param($store, $action)
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
}