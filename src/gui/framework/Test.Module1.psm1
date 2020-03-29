$_id = 21
Function New-TestObject1() {
    $Id = $script:_id++

    New-Module -AsCustomObject -ArgumentList @($Id) -ScriptBlock {
        param($Id)

        Function NewTestObjectFromInsideModule() {
            return New-TestObject1
        }

        Export-ModuleMember -Variable Id
        Export-ModuleMember -Function NewTestObjectFromInsideModule
    }.GetNewClosure()
}