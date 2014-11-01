import des.util;
import des.flow;

import std.random;
import core.thread;

class TestWorkElement : WorkElement, EventProcessor
{
    size_t step;
    string name;

    this( string name )
    {
        this.name = name;
        log_info( "create '%s'", name );
    }

    override void process()
    {
        string msg = toMessage( " element '%s' step %d", name, step++ );
        pushEvent( Event( 0, msg ) );
        log_info( "'%s' generate message event", name );
        Thread.sleep(dur!"msecs"(100+uniform(-50,50)));
    }

    void processEvent( in Event ev )
    {
        switch( ev.code )
        {
        case 0:
            log_info( "'%s' get message event: %s", name, ev.as!string );
            break;
        case Event.system_code:
            log_info( "'%s' get system event: %s", name, ev.as!SysEvData );
            break;
        default:
            log_info( "'%s' get unknown event", name );
            break;
        }
    }

    override EventProcessor[] getEventProcessors() { return [this]; }

    protected void selfDestroy() { log_info( "destroy '%s'", name ); }
}

// it must be a function, not delegate
WorkElement createTestWE( string name )
{ return new TestWorkElement( name ); }

FThread[] prepare()
{
    auto a = new FThread( "th1", &createTestWE, "E1" );
    auto b = new FThread( "th2", &createTestWE, "E2" );
    a.addListener( b );
    b.addListener( a );
    return [a,b];
}

void batchCommand( FThread[] list, Command cmd )
{ foreach( th; list ) th.pushCommand( cmd ); }

void batchJoin( FThread[] list )
{ foreach( th; list ) th.join(); }

void printInfo( FThread[] list )
{ foreach( th; list ) log_info( "thread info: '%s' %s", th.name, th.info.state ); }

void batchCommandWithSleep( FThread[] list, Command cmd, size_t sleep_time )
{
    log_info( "##### %s", cmd );
    batchCommand( list, cmd );

    // may print wrong info because command in
    // thread may not processed yet
    printInfo( list );

    Thread.sleep( dur!"msecs"(sleep_time) );
}

void main()
{
    auto list = prepare();
    Thread.sleep(dur!"msecs"(50));
    batchCommandWithSleep( list, Command.START, 400 );
    batchCommandWithSleep( list, Command.PAUSE, 400 );
    batchCommandWithSleep( list, Command.START, 400 );
    batchCommandWithSleep( list, Command.REINIT, 200 );
    batchCommandWithSleep( list, Command.START, 400 );
    batchCommandWithSleep( list, Command.CLOSE, 200 );
    log_info( "join threads" );
    batchJoin( list );
    Thread.sleep(dur!"msecs"(10));
    log_info( "finish" );
}
