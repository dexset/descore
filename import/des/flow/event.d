module des.flow.event;

import std.traits;
import std.string : format;

import core.time;

import des.util.data.pdata;

import des.flow.base;
import des.flow.sysevdata;

/// Pass data between threads
struct Event
{
    /// `ulong.max` reserved system event code
    enum system_code = ulong.max;

    alias typeof(this) Self;

    ///
    ulong code;

    ///
    ulong timestamp;

    /// information in event
    PData data;

    /++ generate system event
        returns:
         Event
     +/
    static auto system( SysEvData sed )
    {
        Self ev;
        ev.code = system_code;
        ev.timestamp = currentTick;
        ev.data = PData(sed);
        return ev;
    }

    ///
    this(T)( ulong code, in T value )
        if( is( typeof(PData(value)) ) )
    in { assert( code != system_code ); } body
    {
        this.code = code;
        timestamp = currentTick;
        data = PData(value);
    }

    private enum base_ctor =
    q{
        this( in Event ev ) %s
        {
            code = ev.code;
            timestamp = ev.timestamp;
            data = ev.data;
        }
    };

    mixin( format( base_ctor, "" ) );
    mixin( format( base_ctor, "const" ) );
    mixin( format( base_ctor, "immutable" ) );
    mixin( format( base_ctor, "shared" ) );
    mixin( format( base_ctor, "shared const" ) );

    @property
    {
        ///
        bool isSystem() pure const
        { return code == system_code; }

        /// elapsed time before create event
        ulong elapsed() const
        { return currentTick - timestamp; }

        /// get data as type T
        T as(T)() const { return data.as!T; }
        /// get data as type T
        T as(T)() shared const { return data.as!T; }
        /// get data as type T
        T as(T)() immutable { return data.as!T; }

        /// get pdata
        immutable(void)[] pdata() const { return data.data; }
        /// get pdata
        immutable(void)[] pdata() shared const { return data.data; }
        /// get pdata
        immutable(void)[] pdata() immutable { return data.data; }
    }
}

///
interface EventProcessor { /++ +/ void processEvent( in Event ); }

///
interface EventBus { /++ +/ void pushEvent( in Event ); }

///
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

///
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
