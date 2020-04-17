#pragma warning disable 67

using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System;
 
public static class SymbolExtensions
{
    /// <summary>
    /// Given a lambda expression that calls a method, returns the method info.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="expression">The expression.</param>
    /// <returns></returns>
    public static MethodInfo GetMethodInfo(Expression<Action> expression)
    {
        return GetMethodInfo((LambdaExpression)expression);
    }
 
    /// <summary>
    /// Given a lambda expression that calls a method, returns the method info.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="expression">The expression.</param>
    /// <returns></returns>
    public static MethodInfo GetMethodInfo<T>(Expression<Action<T>> expression)
    {
        return GetMethodInfo((LambdaExpression)expression);
    }
 
    /// <summary>
    /// Given a lambda expression that calls a method, returns the method info.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="expression">The expression.</param>
    /// <returns></returns>
    public static MethodInfo GetMethodInfo<T, TResult>(Expression<Func<T, TResult>> expression)
    {
        return GetMethodInfo((LambdaExpression)expression);
    }
 
    /// <summary>
    /// Given a lambda expression that calls a method, returns the method info.
    /// </summary>
    /// <param name="expression">The expression.</param>
    /// <returns></returns>
    public static MethodInfo GetMethodInfo(LambdaExpression expression)
    {
        MethodCallExpression outermostExpression = expression.Body as MethodCallExpression;
 
        if (outermostExpression == null)
        {
            throw new ArgumentException("Invalid Expression. Expression should consist of a Method call only.");
        }
 
        return outermostExpression.Method;
    }
}


public class Command1 : System.Windows.Input.ICommand {

    public event System.EventHandler CanExecuteChanged;

    public bool CanExecute(object parameter) {
        System.Console.WriteLine("command1 can execute");
        return true;
    }

    public void Execute(object parameter) {
        System.Console.WriteLine("command1 running.");
    }

    public void DoSomething() {
        System.Console.WriteLine("do something...");
    }

    public System.Reflection.MethodInfo GetMethodInfo() {
        return SymbolExtensions.GetMethodInfo(() => this.DoSomething());
    }
}