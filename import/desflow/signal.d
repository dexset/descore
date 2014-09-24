module desflow.signal;

import desflow.base;

struct Signal
{
    ulong code;

    pure this( ulong code )
    { this.code = code; }

    pure this( in Signal s )
    { this.code = s.code; }
}

interface SignalProcessor
{ void processSignal( in Signal ); }

unittest
{
    assert( creationTest( Signal(0) ) );
}
