/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desutil.pdata;

import std.traits;
import std.string;

alias immutable(ubyte)[] imbyte;

private pure imbyte pureDumpData(T)( in T val )
{
    static if( is( T == PData ) || is( T == shared PData ) )
        return val.data.idup;
    else static if( isArray!T )
        return cast(imbyte)val.idup;
    else static if( !hasUnsharedAliasing!T )
        return cast(imbyte)[val].idup;
    else static assert( 0, format( "unsupported type '%s' for pure read data", T.stringof ) );
}

@property @safe pure nothrow isPureDump(T)()
{ return is( typeof( pureDumpData( T.init ) ) ); }

unittest
{
    static assert( isPureDump!(imbyte) );
    static assert( isPureDump!(string) );
    static assert( isPureDump!(double) );
    static assert( isPureDump!(PData) );
    static assert( isPureDump!(double[]) );
    static assert( !isPureDump!(int[string]) );

    static struct TS { int[string] val; }
    static assert( !isPureDump!(TS) );
}

private T conv(T)( in imbyte data, string inittype )
{
    static if( isArray!T )
        return cast(T)data.dup;
    else static if( !hasUnsharedAliasing!T )
    {
        if( data.length * ubyte.sizeof != T.sizeof )
            throw new Exception( format( "this PData create with '%s' unable convert to '%s'", 
                        (inittype.length ? inittype : "no data"),
                        T.stringof ) );
        return (cast(T[])data.dup)[0];
    }
    else static if( __traits(compiles, T.load(data)) )
        return T.load(data);
    else static assert( 0, format( "unsupported type '%s'", T.stringof ) );
}

private pure string getType(T)( T obj )
{
    static if( is(T == PData) || is( T == const(PData) ) || is(T == shared(PData) ) || is( T == immutable(PData) )  )
        return obj.inittype;
    else return T.stringof;
}

struct PData
{
    imbyte data;
    string inittype;

    private void readData(T)( in T val )
    {
        static if( isPureDump!T ) 
            data = pureDumpData( val );
        else static if( __traits(compiles, val.dump()) )
            data = val.dump().idup;
        else static assert( 0, format( "unsupported type '%s'", T.stringof ) );
        inittype = getType(val);
    }

    pure this( in ubyte[] dd ) 
    { 
        data = dd.idup; 
        inittype = "byte array";
    }

    pure this(T)( in T val ) if( isPureDump!T ) 
    { 
        data = pureDumpData( val ); 
        inittype = getType(val);
    }

    this(T)( in T val ) if( !isPureDump!T ) 
    { readData( val ); }

    T opAssign(T)( in T val )
    {
        readData( val );
        return val;
    }

    @property
    {
        T as(T)() const { return conv!T( data, inittype ); }
        T as(T)() shared const { return conv!T( data, inittype ); }
        T as(T)() immutable { return conv!T( data, inittype ); }
    }
}

unittest
{
    void should_eq(size_t line=__LINE__,T1,T2)( T1 a, T2 b )
    { assert( a == b, format( "'%s' should equal '%s' at line #%d", a, b, line ) ); }

    void should_not_eq(size_t line=__LINE__,T1,T2)( T1 a, T2 b )
    { assert( a != b, format( "'%s' should not equal '%s' at line #%d", a, b, line ) ); }

    auto a = PData( [ .1, .2, .3 ] );
    should_eq( a.as!(double[]), [ .1, .2, .3 ] );
    a = "hello";
    should_eq( a.as!string, "hello" );

    static struct TestStruct 
    { double x, y; string info; immutable(int)[] data; }
    auto ts = TestStruct( 10.1, 12.3, "hello", [1,2,3,4] );

    auto xx = PData( ts );

    auto xa = shared PData( xx );
    auto xb = const PData( xx );
    auto xc = shared const PData( xx );
    auto xd = immutable PData( xx );
    auto xe = shared immutable PData( xx );

    should_eq( xx, xa );
    should_eq( xx, xb );
    should_eq( xx, xc );
    should_eq( xx, xd );
    should_eq( xx, xe );

    should_eq( xa.as!TestStruct, ts );
    should_eq( xb.as!TestStruct, ts );
    should_eq( xc.as!TestStruct, ts );
    should_eq( xd.as!TestStruct, ts );
    should_eq( xe.as!TestStruct, ts );

    auto ax = PData( xa );
    auto bx = PData( xb );
    auto cx = PData( xc );
    auto dx = PData( xd );
    auto ex = PData( xe );

    //assert( xx == ax, format("%s != %s", xx, xa) );
    //assert( xx == bx );
    //assert( xx == cx );
    //assert( xx == dx );
    //assert( xx == ex );

    should_eq( ax.data, xx.data );
    should_eq( bx.data, xx.data );
    should_eq( cx.data, xx.data );
    should_eq( dx.data, xx.data );
    should_eq( ex.data, xx.data );

    should_eq( ax.as!TestStruct, ts );
    should_eq( bx.as!TestStruct, ts );
    should_eq( cx.as!TestStruct, ts );
    should_eq( dx.as!TestStruct, ts );
    should_eq( ex.as!TestStruct, ts );
}

unittest
{
    import std.conv;
    static class TestClass
    {
        int[string] info;

        static auto load( in ubyte[] data )
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
            return cast(ubyte[])( buf.join(",").dup );
        }
    }

    auto tc = new TestClass( [ "ok":1, "no":3, "yes":5 ] );

    auto a = PData( tc );
    auto ta = a.as!TestClass;
    assert( ta.info == tc.info );

    auto b = a;
    b = "ok:1,no:3";
    auto tb = b.as!TestClass;
    tc.info.remove( "yes" );

    assert( tb.info == tc.info );

    tc.info["yes"] = 5;
    b = a;
    tb = b.as!TestClass;
    assert( tb.info == tc.info );
}

unittest
{
    auto fnc_a() { return cast(immutable(ubyte)[])("hello_a".idup); }
    auto fnc_b() { return cast(ubyte[])("hello_b".dup); }
    auto a = PData( fnc_a() );
    assert( a.as!string == "hello_a" );
    auto b = PData( fnc_b() );
    assert( b.as!string == "hello_b" );

    auto ca = const PData( fnc_a() );
    assert( ca.as!string == "hello_a" );
    auto cb = const PData( fnc_b() );
    assert( cb.as!string == "hello_b" );

    auto ia = immutable PData( fnc_a() );
    assert( ia.as!string == "hello_a" );
    auto ib = immutable PData( fnc_b() );
    assert( ib.as!string == "hello_b" );

    auto sa = shared PData( fnc_a() );
    assert( sa.as!string == "hello_a" );
    auto sb = shared PData( fnc_b() );
    assert( sb.as!string == "hello_b" );

    auto sca = shared const PData( fnc_a() );
    assert( sca.as!string == "hello_a" );
    auto scb = shared const PData( fnc_b() );
    assert( scb.as!string == "hello_b" );

    auto sia = shared immutable PData( fnc_a() );
    assert( sia.as!string == "hello_a" );
    auto sib = shared immutable PData( fnc_b() );
    assert( sib.as!string == "hello_b" );
}
