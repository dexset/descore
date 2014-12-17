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

module des.flow.element;

import des.util.object.emm;
import des.util.logsys;

import des.flow.event;
import des.flow.signal;

/+
action must be in:
    preparation -> ctor
    last actions before start -> process special input event
    actions on pause -> process special input event
    processing -> process
    terminate all -> selfDestroy( external memory manager )
+/

abstract class WorkElement : EventBus, SignalBus, ExternalMemoryManager
{
    mixin DirectEMM;
    mixin ClassLogger;

private:
    SignalProcessor signal_processor;
    EventProcessor event_listener;

public:

    abstract void process();

    EventProcessor[] getEventProcessors() { return []; }

    final void setEventListener( EventProcessor ep )
    {
        event_listener = ep;
        logger.Debug( "set event listener [%s]", ep );
    }

    final void pushEvent( in Event ev )
    {
        logger.trace( "push event with code [%d] timestamp [%d] to listener [%s]", ev.code, ev.timestamp, event_listener );
        if( event_listener !is null )
            event_listener.processEvent( ev );
    }

    final void setSignalProcessor( SignalProcessor sp )
    in { assert( sp !is null ); } body
    {
        signal_processor = sp;
        logger.Debug( "set signal processor [%s]", sp );
    }

    final void sendSignal( in Signal sg )
    {
        logger.trace( "send signal [%s] to processor [%s]", sg, signal_processor );
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
