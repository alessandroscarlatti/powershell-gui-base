$list = [System.Collections.ObjectModel.ObservableCollection[string]] (New-Object System.Collections.ObjectModel.ObservableCollection[string])
$list.Add_CollectionChanged({ param($sender, $e)
    write-host "asdf"
})
$list.Add("qwer")
$list.Add("zxcv")
$list.Add("xcvb")
$list.RemoveAt(1)
$list.Remove("qwer")
$list.Add()