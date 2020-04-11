using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

public class CustomHashtable : System.Collections.Hashtable, INotifyPropertyChanged {

    public event PropertyChangedEventHandler PropertyChanged;

    public delegate void UpdateDependentProperties();

    private UpdateDependentProperties _UpdateDependentProperties;

    public void SetUpdateDependentProperties(CustomHashtable.UpdateDependentProperties callback) {
        Console.WriteLine("asdf");
        this._UpdateDependentProperties = callback;
    }

    public void InvokeUpdateDependentProperties() {
        if (this.method != null) {
            method.Invoke(null);
        }
    }

    public void NotifyPropertyChanged([CallerMemberName] String propertyName = "") {
        if (PropertyChanged != null)
        {
            Console.WriteLine("Firing property changed event for " + propertyName);
            PropertyChanged(this, new PropertyChangedEventArgs(""));
        }
    }

    public override object this[object key] { 
        get {
            Console.WriteLine("getting item " + key + " value is " + base[key]);
            return base[key];
        }
        set {
            Console.WriteLine("setting item " + key + " with value " + value);
            base[key] = value;
            NotifyPropertyChanged((string) "[" + key + "]");

            // Delegate d = (Delegate) base["UpdateDependentProperties"];
        }
    }
}