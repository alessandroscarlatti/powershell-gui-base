using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

public partial class Codebehind1 : System.Windows.Window {

    public void DoSomething(object sender, Object args) {
        Console.WriteLine("DoSomething called.");
        Console.WriteLine("Sender is " + sender);
        Console.WriteLine("Args is " + args);
    }
}