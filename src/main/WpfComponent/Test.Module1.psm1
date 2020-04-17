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

Function Get-String() {
    return "Hello World"
}

Function New-TestObservableList {
    [System.Collections.ObjectModel.ObservableCollection[string]] $list = New-Object System.Collections.ObjectModel.ObservableCollection[string]
    $list.Add_CollectionChanged({ param($sender, $e)
        write-host "CollectionChanged on test observable list"
    })
    return ,$list
}