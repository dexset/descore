module desflow.element;

import desutil.emm;

import desflow.event;
import desflow.signal;

/+
action must be in:
    preparation -> ctor
    last actions before start processing -> process special input event
    processing -> process
    terminate all -> selfDestroy( external memory manager )
+/

abstract class WorkElement : ExternalMemoryManager
{
    mixin( getMixinChildEMM );

private:
    SignalProcessor signal_processor;
    EventProcessor event_listener;

public:

    abstract void process();

    EventProcessor[] getEventProcessors() { return []; }

    final void setEventListener( EventProcessor ep )
    { event_listener = ep; }

    final void pushEvent( in Event ev )
    {
        if( event_listener !is null )
            event_listener.processEvent( ev );
    }

    final void setSignalProcessor( SignalProcessor sp )
    in { assert( sp !is null ); } body
    { signal_processor = sp; }

    final void sendSignal( in Signal sg )
    {
        if( signal_processor !is null )
            signal_processor.processSignal( sg );
    }
}

unittest
{
    struct TestStruct { double x, y; string info; immutable(int)[] data; }
    auto ts = TestStruct( 3.14, 2.7, "hello", [ 2, 3, 4 ] );

    class TestElement: WorkElement
    {
        override void process(){}
        protected void selfDestroy(){}
    }

    class TestSignalProcessor : SignalProcessor 
    { void processSignal( in Signal s ) { assert( s.code == 0 ); } }

    auto elem = new TestElement;
    elem.setSignalProcessor( new TestSignalProcessor );

    elem.sendSignal( Signal(0) );

    size_t cnt = 0;
    elem.setEventListener( new FunctionEventProcessor (
        ( in Event ev ) { cnt++; assert( ev.as!TestStruct == ts ); }
    ));

    auto ev = Event( 8, ts );
    elem.pushEvent( ev );
    elem.pushEvent( const Event( ev ) );
    elem.pushEvent( shared Event( ev ) );
    elem.pushEvent( immutable Event( ev ) );
    elem.pushEvent( const shared Event( ev ) );
    elem.pushEvent( shared const Event( ev ) );
    elem.pushEvent( immutable shared Event( ev ) );
    elem.pushEvent( shared immutable Event( ev ) );
    assert( cnt == 8 );
}
