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

module des.flow.thread;

import std.string;

import std.algorithm;
import std.array;

import std.datetime;
import core.thread;

import des.util.arch.emm;
import des.util.logsys;

import des.flow.base;
import des.flow.event;
import des.flow.element;
import des.flow.signal;
import des.flow.sync;
import des.flow.sysevdata;

class FThreadException : FlowException
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

class FThread
{
protected:
    Communication com;
    Thread thread;
    string self_name;

public:
    enum State { NONE, PAUSE, WORK };
    enum Error { NONE, FTHREAD, FLOW, EXCEPT, FATAL };

    static struct Info
    {
        State state;
        Error error;
        string message;
        ulong timestamp;

        this( State state, Error error=Error.NONE, string msg="" )
        {
            this.state = state;
            this.error = error;
            message = msg;
            timestamp = currentTick;
        }

        enum ctor_text = ` this( in Info fts )
        {
            state = fts.state;
            error = fts.error;
            message = fts.message;
            timestamp = fts.timestamp;
        }
        `;

        mixin( ctor_text );
        mixin( "const" ~ ctor_text );
        mixin( "immutable" ~ ctor_text );
        mixin( "shared" ~ ctor_text );
        mixin( "shared const" ~ ctor_text );
    }

    this(Args...)( string name, WorkElement function(Args) func, Args args )
    in { assert( func !is null ); } body
    {
        thread = new Thread({ tmain( com, func, args ); });
        thread.name = name;
        self_name = name;
        com.initialize();
        thread.start();
        debug logger.Debug( "name: '%s'", name );
    }

    @property auto info() const { return Info(com.info.back); }
    @property auto name() const { return self_name; }

    auto takeAllSignals()
    { return com.signals.clearAndReturnAll(); }

    void pushCommand( Command cmd )
    {
        com.commands.pushBack( cmd );
        debug logger.trace( "thread: '%s', command: '%s'", name, cmd );
    }

    void pushEvent( in Event ev )
    {
        com.eventbus.pushBack( ev );
        debug logger.trace( "thread: '%s', event code: %d", name, ev.code );
    }

    void join() { thread.join(); }

    void addListener( FThread[] thrs... )
    {
        foreach( t; thrs )
            com.listener.add( t.com.eventbus );
        debug logger.Debug( "thread: '%s', listeners: %s", name, array(map!(a=>a.name)(thrs)) );
    }

    void delListener( FThread th )
    {
        com.listener.del( th.com.eventbus );
        debug logger.Debug( "thread: '%s', listener: %s", name, th.name );
    }
}

version(none)
{
unittest
{
    static class TestElement : WorkElement
    {
        this() { stderr.writeln( "init" ); }
        override EventProcessor[] getEventProcessors()
        {
            return [
                new FunctionEventProcessor( (in Event ev) 
                {
                    if( ev.isSystem )
                        stderr.writeln( "system event: ",
                            ((cast(Event)ev).data.as!SysEvData).msg );
                })
            ];
        }
        override void process() { stderr.writeln( "process" ); }
        protected void selfDestroy() { stderr.writeln( "destroy" ); }
    }

    auto fth = new FThread( "test", { return new TestElement; } );
    fth.pushCommand( Command.START );
    Thread.sleep(dur!"usecs"(20));
    fth.pushCommand( Command.PAUSE );
    Thread.sleep(dur!"msecs"(20));
    fth.pushCommand( Command.START );
    Thread.sleep(dur!"usecs"(20));
    fth.pushCommand( Command.REINIT );
    Thread.sleep(dur!"usecs"(20));
    fth.pushCommand( Command.START );
    Thread.sleep(dur!"usecs"(20));
    fth.pushCommand( Command.CLOSE );
    fth.join();
}
}

private
{
    void tmain(Args...)( Communication com, WorkElement function(Args) func, Args args )
    {

        Logger logger = new InstanceLogger( __MODULE__ ~ ".WorkProcessor", Thread.getThis().name );
        auto wp = createProcessor( com, logger, func, args );
        if( wp is null ) return;
        scope(exit) fullTerminate(wp);
        try while( wp.hasWork ) wp.process();
        catch( Throwable e ) com.info.pushBack( convertToErrorInfo(logger,e) );
    }

    auto createProcessor(Args...)( Communication com, Logger logger, WorkElement function(Args) func, Args args )
    {
        try return new WorkProcessor!Args( com, logger, func, args );
        catch( Throwable e )
        {
            com.info.pushBack( convertToErrorInfo(logger,e) );
            return null;
        }
    }

    final class WorkProcessor(Args...) : ExternalMemoryManager, SignalProcessor, EventProcessor
    {
        mixin EMM;

        Args args;
        WorkElement function(Args) func;
        WorkElement elem;
        EventProcessor[] evprocs;

        Communication com;

        bool work = false;
        bool has_work = true;

        Logger logger;

        this( Communication com, Logger logger, WorkElement function(Args) func, Args args )
        {
            this.com = com;
            this.func = func;
            this.args = args;

            this.logger = logger;

            init();
            debug logger.Debug( "pass" );
        }

        @property bool hasWork() const { return has_work; }

        void process()
        {
            debug logger.trace( "start process" );
            if( work )
            {
                foreach( e; com.eventbus.clearAndReturnAll() )
                    transmitEvent( e );

                elem.process();

                debug logger.trace( "events processed" );
            }

            foreach( scmd; com.commands.clearAndReturnAll() )
            {
                auto cmd = cast(Command)scmd;

                debug logger.trace( "process command '%s'", cmd );
                final switch( cmd )
                {
                    case Command.START:  start();  break;
                    case Command.PAUSE:  pause();  break;
                    case Command.STOP:   stop();   break;
                    case Command.REINIT: reinit(); break;
                    case Command.CLOSE:  close();  break;
                }
                debug logger.trace( "process command '%s' pass", cmd );
            }
            debug logger.trace( "process pass" );
        }

        void transmitEvent( in Event event )
        {
            foreach( ep; evprocs )
                ep.processEvent( event );
        }

        // SignalProcessor
        void processSignal( in Signal sig ) { com.signals.pushBack(sig); }

        // EventProcessor
        void processEvent( in Event ev ) { com.listener.pushBack(ev); }

        void pushEvent( in Event ev ) { com.eventbus.pushBack( ev ); }

        void pushInfo( FThread.State state, FThread.Error error=FThread.Error.NONE, string msg="" )
        { com.info.pushBack( FThread.Info( state, error, msg ) ); }

        void init()
        {
            debug logger.Debug( "start" );
            elem = func(args);

            if( elem is null )
                throw new FThreadException( "creation func return null" );

            elem.setSignalProcessor( this );
            elem.setEventListener( this );

            evprocs = elem.getEventProcessors();

            pause();
            debug logger.Debug( "pass" );
        }

        void start()
        {
            pushInfo( FThread.State.WORK );
            transmitEvent( Event.system( SysEvData.work ) );
            work = true;
            debug logger.Debug( "pass" );
        }

        void pause()
        {
            pushInfo( FThread.State.PAUSE );
            transmitEvent( Event.system( SysEvData.pause ) );
            work = false;
            debug logger.Debug( "pass" );
        }

        void stop()
        {
            pushInfo( FThread.State.NONE );
            if( elem is null ) return;
            pause();
            evprocs.length = 0;
            elem.destroy();
            elem = null;
            debug logger.Debug( "pass" );
        }

        void reinit()
        {
            stop();
            init();
        }

        void close()
        {
            stop();
            has_work = false;
            debug logger.Debug( "pass" );
        }

    protected:

        void selfDestroy()
        {
            stop();
            debug logger.Debug( "pass" );
        }
    }

    void fullTerminate(T)( ref T obj )
    {
        if( is( T : ExternalMemoryManager ) && obj !is null )
            obj.destroy();
        obj = null;
    }

    FThread.Info convertToErrorInfo( Logger logger, Throwable e )
    in{ assert( logger !is null ); } body
    {
        if( auto pe = cast(FThreadException)e ) 
        {
            logger.error( "EXCEPTION: fthread exc: %s", pe );
            return errorInfo( FThread.Error.FTHREAD, e.msg );
        }
        else if( auto fe = cast(FlowException)e )
        {
            logger.error( "EXCEPTION: flow exc: %s", fe );
            return errorInfo( FThread.Error.FLOW, e.msg );
        }
        else if( auto se = cast(Exception)e )
        {
            logger.error( "EXCEPTION: %s", se );
            return errorInfo( FThread.Error.EXCEPT, e.msg );
        }
        else if( auto te = cast(Throwable)e )
        {
            logger.error( "FATAL: %s", te );
            return errorInfo( FThread.Error.FATAL, e.msg );
        }
        assert(0,"unknown exception");
    }

    FThread.Info errorInfo( FThread.Error error, string msg )
    { return FThread.Info( FThread.State.NONE, error, msg ); }
}
