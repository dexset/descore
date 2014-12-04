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

module des.flow.event;

import std.traits;

import core.time;

import des.util.pdata;

import des.flow.base;
import des.flow.sysevdata;
/++
    code=ulong.max-1 is reserved for system
 +/
struct Event
{
    enum ulong system_code = ulong.max-1;
    alias typeof(this) Self;

    ulong code;
    ulong timestamp;
    PData data;

    static auto system( SysEvData sed )
    {
        Self ev;
        ev.code = system_code;
        ev.timestamp = currentTick;
        ev.data = PData(sed);
        return ev;
    }

    this(T)( ulong code, in T value )
        if( is( typeof(PData(value)) ) )
    in { assert( code != system_code ); } body
    {
        this.code = code;
        timestamp = currentTick;
        data = PData(value);
    }

    private enum base_ctor =
        ` this( in Event ev )
    {
        code = ev.code;
        timestamp = ev.timestamp;
        data = ev.data;
    }`;

    mixin( base_ctor );
    mixin( "const" ~ base_ctor );
    mixin( "immutable" ~ base_ctor );
    mixin( "shared" ~ base_ctor );
    mixin( "shared const" ~ base_ctor );

    @property
    {
        bool isSystem() pure const
        { return code == system_code; }

        ulong elapsed() const
        { return currentTick - timestamp; }

        T as(T)() const { return data.as!T; }
        T as(T)() shared const { return data.as!T; }
        T as(T)() immutable { return data.as!T; }

        immutable(void)[] pdata() const { return data.data; }
        immutable(void)[] pdata() shared const { return data.data; }
        immutable(void)[] pdata() immutable { return data.data; }
    }
}

interface EventProcessor { void processEvent( in Event ); }
interface EventBus { void pushEvent( in Event ); }

final class FunctionEventProcessor : EventProcessor
{
    private void delegate( in Event ) func;

    this( void delegate( in Event ) f ) { setFunction( f ); }

    void setFunction( void delegate( in Event ) f )
    in { assert( f !is null ); } body { func = f; }

    void processEvent( in Event ev ) { func(ev); }
}

final class EventProcessorList : EventProcessor
{
    EventProcessor[] list;
    this( EventProcessor[] list ) { this.list = list; }
    void processEvent( in Event ev )
    { foreach( p; list ) p.processEvent( ev ); }
}

unittest
{
    auto a = Event( 1, [ 0.1, 0.2, 0.3 ] );
    auto gg = a.as!(double[]);
    assert( gg == [ 0.1, 0.2, 0.3 ] );
    auto b = Event( 1, "some string"w );
    auto nn = b.as!wstring;
    assert( nn == "some string"w );
    auto c = Event( 1, "some str" );
    auto d = shared Event( c );
    assert( c.as!string == "some str" );
    assert( d.as!string == "some str" );
    assert( c.code == d.code );

    struct TestStruct { double x, y; string info; immutable(int)[] data; }

    auto ts = TestStruct( 10.1, 12.3, "hello", [1,2,3,4] );
    auto e = Event( 1, ts );

    auto f = shared Event( e );
    auto g = immutable Event( e );
    auto h = shared const Event( e );

    assert( e.as!TestStruct == ts );
    assert( f.as!TestStruct == ts );
    assert( g.as!TestStruct == ts );
    assert( h.as!TestStruct == ts );

    auto l = Event( f );
    auto m = Event( g );
    auto n = Event( h );

    assert( l.as!TestStruct == ts );
    assert( m.as!TestStruct == ts );
    assert( n.as!TestStruct == ts );
}

unittest
{
    auto a = Event( 1, [ 0.1, 0.2, 0.3 ] );
    assert( !a.isSystem );
    auto b = Event.system( SysEvData.init );
    assert( b.isSystem );
}

unittest
{
    static class Test { int[string] info; }
    static assert( !__traits(compiles,PData(0,new Test)) );
}

unittest
{
    import std.conv;
    import std.string;

    static class Test
    {
        int[string] info;

        static Test load( in void[] data )
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
            return new Test( buf );
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
            return cast(immutable(void)[])( buf.join(",").idup );
        }
    }

    auto tt = new Test( [ "ok":1, "no":3, "yes":5 ] );
    auto a = Event( 1, tt.dump() );
    auto ft = Test.load( a.data );
    assert( tt.info == ft.info );
    tt.info.remove("yes");
    assert( tt.info != ft.info );

    auto b = Event( 1, "ok:1,no:3" );
    auto ft2 = Test.load( b.data );
    assert( tt.info == ft2.info );
}

unittest
{
    static struct TestStruct { double x, y; string info; immutable(int)[] data; }
    auto ts = TestStruct( 3.14, 2.7, "hello", [ 2, 3, 4 ] );

    auto a = Event( 8, ts );
    auto ac = const Event( a );
    auto ai = immutable Event( a );
    auto as = shared Event( a );
    auto acs = const shared Event( a );

    assert( a.as!TestStruct == ts );
    assert( ac.as!TestStruct == ts );
    assert( ai.as!TestStruct == ts );
    assert( as.as!TestStruct == ts );
    assert( acs.as!TestStruct == ts );
}
