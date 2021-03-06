module des.flow.sync;

import std.traits;

import des.flow.base;
import des.flow.event;
import des.flow.signal;
import des.flow.thread;

/// FThread communication struct 
struct Communication
{
    shared SyncList!Command        commands; ///
    shared SyncList!Signal         signals;  ///
    shared SyncList!(FThread.Info) info;     ///
    shared SyncList!Event          eventbus; ///
    shared HubOutput!Event         listener; ///

    /// create all fields
    void initialize()
    {
        commands = new shared SyncList!Command;
        signals  = new shared SyncList!Signal;
        info     = new shared SyncList!(FThread.Info);
        eventbus = new shared SyncList!Event;
        listener = new shared HubOutput!Event;

        info.pushBack( FThread.Info( FThread.State.NONE, FThread.Error.NONE, "" ) );
    }
}

///
interface SyncOutput(T) { /++ +/ synchronized void pushBack( in T val ); }

///
synchronized class SyncList(T) : SyncOutput!T
{
    ///
    protected T[] list;

    ///
    void pushBack( in T obj )
    {
        static if( isBasicType!T ) list ~= obj;
        else static if( isArray!T ) list ~= obj.dup;
        else list = list ~ T(obj);
    }

    ///
    void popBack() { if( list.length ) list = list[0..$-1]; }

    ///
    T popAndReturnBack()
    {
        auto buf = back;
        popBack();
        return buf;
    }

    ///
    T[] clearAndReturnAll()
    {
        auto r = cast(T[])list.dup;
        list.length = 0;
        return r;
    }

    @property
    {
        ///
        bool empty() const { return list.length == 0; }

        ///
        auto back() const
        {
            static if( isBasicType!T ) return list[$-1];
            else static if( isArray!T ) return list[$-1].idup;
            else return T(list[$-1]);
        }
    }
}


///
version(unittest) void syncTest(T)( T a, T b )
{
    auto sl = new shared SyncList!T;

    assert( sl.empty );
    sl.pushBack( a );
    assert( !sl.empty );
    assert( eq( a, sl.back ) );
    assert( !sl.empty );
    assert( eq( a, sl.back ) );
    sl.pushBack( b );
    assert( eq( b, sl.back ) );
    sl.popBack();
    assert( eq( a, sl.back ) );
    auto val = sl.popAndReturnBack();
    assert( sl.empty );
    assert( eq( a, val ) );
    sl.pushBack( a );
    sl.pushBack( b );
    assert( !sl.empty );
    auto arr = sl.clearAndReturnAll();
    assert( sl.empty );
    assert( eq( arr, [ a, b ] ) );
}

unittest
{
    assert( creationTest( Signal(0) ) );
    assert( creationTest( FThread.Info( FThread.State.PAUSE ) ) );
    assert( creationTest( Event( 0, [1,2] ) ) );

    syncTest( 1.2, 3.4 );
    syncTest( "hello", "world" );
    syncTest( Command.START, Command.PAUSE );
    syncTest( Signal(0), Signal(1) );
    syncTest( FThread.Info( FThread.State.PAUSE ), 
              FThread.Info( FThread.State.WORK ));
    syncTest( Event(0,[1,2]), Event(1,[2,3]) );
}

///
synchronized class HubOutput(T): SyncOutput!T
{
    ///
    alias SyncOutput!T LST;

    ///
    protected LST[] listeners;

    private void check( shared LST checked )
    {
        auto ll = cast(shared HubOutput)checked;
        if( ll is null ) return;
        if( ll is this ) throw new FlowException( "listener found cycle link" );
        foreach( lll; ll.listeners ) check( lll );
    }

    ///
    void pushBack( in T val )
    {
        foreach( listener; listeners )
            listener.pushBack( val );
    }

    ///
    bool inList( shared LST sync )
    {
        foreach( l; listeners )
            if( l is sync ) return true;
        return false;
    }

    ///
    void add( shared LST[] syncs... )
    {
        foreach( s; syncs )
        {
            debug check(s);
            if( !inList(s) )
                listeners ~= s;
        }
    }

    ///
    void del( shared LST[] syncs... )
    {
        typeof(listeners) moved;
        m: foreach( lst; listeners )
        {
            foreach( ds; syncs )
                if( ds == lst )
                    continue m;
            moved ~= lst;
        }
        listeners = moved;
    }
}

unittest
{
    auto sl1 = new shared SyncList!int;
    auto sl2 = new shared SyncList!int;

    auto hub = new shared HubOutput!int;

    hub.add( sl1 );
    // duplicate adding
    hub.add( sl1 );
    hub.pushBack( 12 );

    hub.add( sl2 );
    hub.pushBack( 23 );

    assert( eq( sl1.list, [ 12, 23 ] ) );
    assert( eq( sl2.list, [ 23 ] ) );

    hub.del( sl1 );
    hub.pushBack( 34 );
    assert( eq( sl1.list, [ 12, 23 ] ) );
    assert( eq( sl2.list, [ 23, 34 ] ) );

    hub.add( sl1, sl2 );
    hub.pushBack( 45 );
    assert( eq( sl1.list, [ 12, 23, 45 ] ) );
    assert( eq( sl2.list, [ 23, 34, 45 ] ) );
}
