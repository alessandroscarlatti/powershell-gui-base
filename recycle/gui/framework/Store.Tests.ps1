import-module ./Store.psm1

Describe "Store" {
    It "sets and gets values" {
        $store1 = New-Store "config/TestStore1.json" -ForceDefault
        $store1.SetValue("var1", "val1")
        $store1.SetValue("var2", @{ var3 = "val3"})
        $store1.SetValue("list1", @( "item1", "item2", "item3"))

        #assert values retrieved from store
        $store1.GetValue("var1") | should be "val1"
        $store1.GetValue("var2").var3 | should be "val3"
        $store1.GetValue("list1").length | should be 3
        $store1.GetValue("list1")[2] | should be "item3"

        #load a new store
        #assert values retrieved from store
        $store2 = New-Store "config/TestStore1.json"
        $store2.GetValue("var1") | should be "val1"
        $store2.GetValue("var2").var3 | should be "val3"
        $store2.GetValue("list1").length | should be 3
        $store2.GetValue("list1")[2] | should be "item3"

        #edit store
        #add additional properties
        $store2.SetValue("newVar1", "newVal1")

        #can add new property to deserialized object (ie, did not deserialize to an inconvenient type!)
        $store2.GetValue("var2").var4 = "var4"
        $store2.SetValue("var2", $store2.GetValue("var2"))
        $list1 = $store2.GetValue("list1")
        $list1 += "item4"
        $store2.SetValue("list1", $list1)
        
        #load a new store
        #assert values retrieved from store
        $store3 = New-Store "config/TestStore1.json"
        $store3.GetValue("newVar1") | should be "newVal1"
        $store3.GetValue("list1").length | should be 4
        $store3.GetValue("list1")[3] | should be "item4"
    }
}