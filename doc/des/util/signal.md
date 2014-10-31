Provides 4 struct

```d
struct Signal(Args...);
struct NamedSignal( TName, Args... );
struct SignalBox(Args...);
struct ConditionSignal(Args...);
```

All of them calls list of `void delegate(Args...)` (slots).
All signals can `connect` with delegates.

Example:

```d
    string[] sarr;
    Signal!string strsignal;
    with( strsignal )
    {
        connect( ( str ){ sarr ~= str; } );
        connect( ( str ){ sarr ~= str ~ str; } );
    }

    assert( sarr.length == 0 );
    strsignal( "ok" );
    assert( sarr == [ "ok", "okok" ] );
```

```d
    size_t[] arr;

    NamedSignal!(string,size_t) susig;

    susig.connect( "add", (a){ arr ~= a; } );
    susig.connect( "remove", (a){ arr = arr[0 .. a] ~ arr[a+1 .. $]; } );

    susig( "add", 10 );
    susig( "add", 15 );

    assert( arr == [ 10, 15 ] );

    susig( "add", 20 );

    // returns true if find signal by name
    auto ret = susig( "add", 25 );

    assert( arr == [ 10, 15, 20, 25 ] );
    assert( ret == true );

    ret = susig( "remove", 1 ); 
    assert( arr == [ 10, 20, 25 ] );
    assert( ret == true );

    ret = susig( "get", 25 );
    assert( arr == [ 10, 20, 25 ] );
    assert( ret == false );

    // return list of finded signals
    auto ret_names = susig( ["add", "get"], 35 );
    assert( ret_names == ["add"] );
    assert( arr == [ 10, 20, 25, 35 ] );
```

```d
    string[] arr;
    SignalBox!() stest;
    stest.addPair({ arr ~= "open"; },{ arr ~= "close"; });
    stest.connect({ arr ~= "content"; });
    assert( arr.length == 0 );
    stest();
    assert( arr.length == 3 );
    assert( arr == [ "open", "content", "close" ] );
```

```d
    bool cond = true;

    int[] arr;

    ConditionSignal!() stest;
    stest.addCondition( { return cond; }, true );
    stest.connect({ arr ~= 0; });
    stest.connectAlt({ arr ~= 1; });

    stest();
    assert( arr == [ 0 ] );
    cond = false;
    stest();
    assert( arr == [ 0, 1 ] );
```
