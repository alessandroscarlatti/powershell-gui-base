param($Context)

#define default store
$DefaultStore = @{
    Todos = @(
        "asdf",
        "qwer",
        "zxcv"
    )
}

#Create new store
import-module "$($Context.SrcDir)/main/Store/Store.psm1"
$Context.Store = new-store "$($Context.AppDir)\store.xml" $DefaultStore