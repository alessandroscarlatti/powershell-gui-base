import-module ./Test.Module1.psm1

Describe "TestModule1" {
    it "increments id" {
        $obj1 = New-TestObject1
        $obj1.Id | should be 21

        $obj2 = New-TestObject1
        $obj2.Id | should be 22

        $obj3 = $obj2.NewTestObjectFromInsideModule()
        $obj3.Id | should be 23
    }
}