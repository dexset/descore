Provide `struct PData`. It usable in multithreading 
programs for pass data to other thread.

Example:

```d
    auto a = PData( [ .1, .2, .3 ] );
    assert( eq( a.as!(double[]), [ .1, .2, .3 ] ) );
    a = "hello";
    assert( eq( a.as!string, "hello" ) );
```

If object has method `void[] dump()` it can be assigned to PData
If type has static method `T load(immutable(void)[])` it can be read from PData

Example:

```d
    class TestClass
    {
        int[string] info;

        static auto load( in void[] data )
        {
            auto str = cast(string)data.dup;
            auto elems = str.split(",");
            int[string] buf;
            foreach( elem; elems )
            {
                auto key = elem.split(":")[0];
                auto val = to!int( elem.split(":")[1] );
                buf[key] = val;
            }
            return new TestClass( buf );
        }

        this( in int[string] I ) 
        {
            foreach( key, val; I )
                info[key] = val;
            info.rehash();
        }

        auto dump() const
        {
            string[] buf;
            foreach( key, val; info ) buf ~= format( "%s:%s", key, val );
            return cast(void[])( buf.join(",").dup );
        }
    }

    auto tc = new TestClass( [ "ok":1, "no":3, "yes":5 ] );

    auto a = PData( tc );
    auto ta = a.as!TestClass;
    assert( ta.info == tc.info );
```
