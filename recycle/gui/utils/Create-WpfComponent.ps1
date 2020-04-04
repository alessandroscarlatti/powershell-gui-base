return Create-WpfComponent @{
    Xaml = { Xaml };
    Init = { Init $args[1] };
}