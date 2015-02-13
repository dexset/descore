module des.flow.signal;

import des.flow.base;

/// Control signals
struct Signal
{
    ///
    ulong code;

pure nothrow @nogc:
    ///
    this( ulong code ) { this.code = code; }
    ///
    this( in Signal s ) { this.code = s.code; }
}

///
interface SignalProcessor { /++ +/ void processSignal( in Signal ); }

///
interface SignalBus { /++ +/ void sendSignal( in Signal ); }

unittest
{
    assert( creationTest( Signal(0) ) );
}
