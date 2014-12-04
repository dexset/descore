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

module des.util.pdata;

import std.traits;
import std.string;

import des.util.testsuite;

version(unittest)
{
    private
    {
        struct Msg { string data; }
        struct Vec { float x,y,z; }
        struct Arr { int[3] data; }

        struct Some
        {
            float f = 8;
            Vec v = Vec(1,2,3);
            Arr a = Arr([4,5,6]);
        }

        struct Bad { int[] data; }
    }
}

bool isPureData(T)() pure @property
{ return !hasUnsharedAliasing!T && !isArray!T; }

unittest
{
    static assert(  isPureData!int );
    static assert(  isPureData!float );
    static assert(  isPureData!Vec );
    static assert(  isPureData!Arr );
    static assert(  isPureData!Some );
    static assert( !isPureData!string );
    static assert( !isPureData!Bad );
}

bool isPureType(T)() pure @property
{
    static if( !isArray!T ) return isPureData!T;
    else return isPureType!(ForeachType!T);
}

unittest
{
    static assert(  isPureType!int );
    static assert(  isPureType!(int[]) );
    static assert(  isPureType!float );
    static assert(  isPureType!(float[]) );
    static assert(  isPureType!Vec );
    static assert(  isPureType!Arr );
    static assert(  isPureType!Some );
    static assert(  isPureType!string );
    static assert(  isPureType!(string[]) );
    static assert( !isPureType!Bad );
}

auto pureConv(T)( in immutable(void)[] data ) pure
{
    static if( isPureData!T )
        return (cast(T[])(data.dup))[0];
    else static if( isPureType!T )
        return cast(T)(data.dup);
    else static assert( 0, format( "unsuported type %s", T.stringof ) );
}

immutable(void)[] pureDump(T)( in T val ) pure
{
    static assert( !is( T == void[] ) );
    static if( isArray!T ) return (cast(void[])val).idup;
    else return (cast(void[])[val]).idup;
}

bool isPData(T)() pure @property
{ return is( typeof( (( PData a ){})( T.init ) ) ); }

struct PData
{
    immutable(void)[] data;
    alias data this;

    pure
    {
        this( in typeof(this) pd ) { data = pd.data; }

        this(T)( in T val ) if( isPureData!T ) { data = pureDump(val); }
        this(T)( in T[] val ) if( isPureType!T ) { data = pureDump(val); }

        auto opAssign(T)( in T val ) if( isPureData!T ) { data = pureDump(val); return val; }
        auto opAssign(T)( in T[] val ) if( isPureType!T ) { data = pureDump(val); return val; }

        @property
        {
            auto as(T)() const { return pureConv!T(data); }
            auto as(T)() shared const { return pureConv!T(data); }
            auto as(T)() immutable { return pureConv!T(data); }
        }
    }
}

unittest
{
    static assert( isPData!PData );
    static assert( isPData!(const(PData)) );
    static assert( isPData!(immutable(PData)) );
    static assert( isPData!(shared(PData)) );
    static assert( isPData!(shared const(PData)) );
    static assert( isPureData!PData );
    static assert( isPureType!PData );
}

void asTest(A,B)( in A val, in B orig )
{
    assert( (PData(val)).as!B              == orig || isPData!B );
    assert( (const PData(val)).as!B        == orig || isPData!B );
    assert( (immutable PData(val)).as!B    == orig || isPData!B );
    assert( (shared PData(val)).as!B       == orig || isPData!B );
    assert( (shared const PData(val)).as!B == orig || isPData!B );
}

void creationTest(T)( in T val )
{
    asTest( val, val );

    auto a = PData( val );
    auto ac = const PData( val );
    auto ai = immutable PData( val );
    auto as = shared PData( val );
    auto asc = shared const PData( val );

    asTest( a, val );
    asTest( ac, val );
    asTest( ai, val );
    asTest( as, val );
    asTest( asc, val );
}

unittest
{
    creationTest( "hello" );
    creationTest( 12.5 );
    creationTest( 12 );
    creationTest( [1,2,3] );
    creationTest( [.1,.2,.3] );
    creationTest( Vec(1,2,3) );
    creationTest( Arr([1,2,3]) );
    creationTest( Some.init );
}

unittest
{
    auto msg = Msg("ok");

    auto a = shared PData( PData( msg ) );
    assert( a.as!Msg == msg );

    auto b = immutable PData( PData( [msg] ) );
    assert( b.as!(Msg[]) == [msg] );
}

unittest
{
    static assert( !__traits(compiles, PData( Bad([1,2]) ) ) );
    static assert( !__traits(compiles, PData( [Bad([1,2])] ) ) );
}

unittest
{
    auto a = PData( [.1,.2,.3] );
    assert( eq( a.as!(double[]), [.1,.2,.3] ) );
    a = "hello";
    assert( eq( a.as!string, "hello" ) );
}

unittest // Known problems
{
    // shared or immutable PData can't create from structs or arrays with strings 
    enum arr = ["a","b","c"];
    enum msg = Msg("abc");

    static assert(  __traits(compiles, PData( arr ) ) );
    static assert(  __traits(compiles, PData( msg ) ) );
    static assert(  __traits(compiles, PData( [arr] ) ) );
    static assert(  __traits(compiles, PData( [msg] ) ) );
    static assert(  __traits(compiles, const PData( arr ) ) );
    static assert(  __traits(compiles, const PData( msg ) ) );

    static assert( !__traits(compiles, shared PData( arr ) ) );
    static assert( !__traits(compiles, shared PData( msg ) ) );
    static assert( !__traits(compiles, shared PData( [arr] ) ) );
    static assert( !__traits(compiles, shared PData( [msg] ) ) );
    static assert(  __traits(compiles, shared PData( PData( arr ) ) ) );
    static assert(  __traits(compiles, shared PData( PData( msg ) ) ) );

    static assert( !__traits(compiles, shared const PData( arr ) ) );
    static assert( !__traits(compiles, shared const PData( msg ) ) );
    static assert( !__traits(compiles, shared const PData( [arr] ) ) );
    static assert( !__traits(compiles, shared const PData( [msg] ) ) );
    static assert(  __traits(compiles, shared const PData( PData( arr ) ) ) );
    static assert(  __traits(compiles, shared const PData( PData( msg ) ) ) );

    static assert( !__traits(compiles, immutable PData( arr ) ) );
    static assert( !__traits(compiles, immutable PData( msg ) ) );
    static assert( !__traits(compiles, immutable PData( [arr] ) ) );
    static assert( !__traits(compiles, immutable PData( [msg] ) ) );
    static assert(  __traits(compiles, immutable PData( PData( arr ) ) ) );
    static assert(  __traits(compiles, immutable PData( PData( msg ) ) ) );
}
