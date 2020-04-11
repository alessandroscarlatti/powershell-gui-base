#import custom hashtable
try { [CustomHashtable] | Out-Null } catch { Add-Type -TypeDefinition (get-content -raw "./CustomHashtable.cs") -Language CSharp }

#import simple component
import-module "../../main/WpfComponent/SimpleComponent.psm1" -force


Describe "custom hashtable" {
    It "sets and gets values" {
        
        try {
            [CustomHashtable] $hashtable = new-object CustomHashtable
            $hashtable.var1 = "val1"
            $hashtable.var1 | should be "val1"
            $hashtable.Add("var2", "val2")
            $hashtable.var2 | should be "val2"
            $hashtable.var2 = "val3"
            $hashtable.var2 | should be "val3"

            $hashtable.var3 = new-object PSCustomObject -property @{
                var1 = "customVal1"
            }

            $hashtable.SetUpdateDependentProperties({
                write-host "update"
            })

            $hashtable.var3.var1 | should be "customVal1"

            $hashtable.InvokeUpdateDependentProperties()
        } catch {
            write-host $_
            throw $_.Exception
        }
    }
}