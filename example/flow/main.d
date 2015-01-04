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
        logger.info( "create '%s'", name );
    }

    override void process()
    {
        string msg = ntFormat( " element '%s' step %d", name, step++ );
        pushEvent( Event( 0, msg ) );
        logger.info( "'%s' generate message event", name );
        Thread.sleep(dur!"msecs"(100+uniform(-50,50)));
    }

    void processEvent( in Event ev )
    {
        switch( ev.code )
        {
        case 0:
            logger.info( "'%s' get message event: %s", name, ev.as!string );
            break;
        case Event.system_code:
            logger.info( "'%s' get system event: %s", name, ev.as!SysEvData );
            break;
        default:
            logger.info( "'%s' get unknown event", name );
            break;
        }
    }

    override EventProcessor[] getEventProcessors() { return [this]; }

    protected override void selfDestroy() { logger.info( "destroy '%s'", name ); }
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
{ foreach( th; list ) logger.info( "thread info: '%s' %s", th.name, th.info.state ); }

void batchCommandWithSleep( FThread[] list, Command cmd, size_t sleep_time )
{
    logger.info( "##### %s", cmd );
    batchCommand( list, cmd );

    // can print wrong info because command in
    // thread can be not processed yet
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
    logger.info( "join threads" );
    batchJoin( list );
    Thread.sleep(dur!"msecs"(10));
    logger.info( "finish" );
}
