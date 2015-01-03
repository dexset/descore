Provides `struct PData`. It usable in multithreading 
programs for passing data to other thread.

##### Example:

```d
    auto a = PData( [ .1, .2, .3 ] );
    assert( eq( a.as!(double[]), [ .1, .2, .3 ] ) );
    a = "hello";
    assert( eq( a.as!string, "hello" ) );
```

#### Known problems:

- shared or immutable PData can't create from structs or arrays with strings 
