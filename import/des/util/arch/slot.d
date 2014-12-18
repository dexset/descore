module des.util.arch.slot;

import des.util.arch.emm;

package interface SignalLeverage
{ void disconnect( SlotController ); }

class SlotController : ExternalMemoryManager
{
    mixin EMM;

protected:

    size_t[SignalLeverage] signals;

package:

    void connect( SignalLeverage sl )
    in { assert( sl !is null ); }
    body { signals[sl]++; }

    void disconnect( SignalLeverage sl )
    in { assert( sl !is null ); }
    body
    {
        if( sl in signals )
        {
            if( signals[sl] > 0 ) signals[sl]--;
            else signals.remove(sl);
        }
    }

protected:

    void selfDestroy()
    {
        foreach( key, count; signals )
            key.disconnect(this);
    }
}

class Slot(Args...)
{
package:
    Func func;
    SlotController control() @property { return ctrl; }

protected:

    SlotController ctrl;

public:
    alias void delegate(Args) Func;

    this( SlotController ctrl, Func func )
    in
    {
        assert( ctrl !is null );
        assert( func !is null );
    }
    body
    {
        this.ctrl = ctrl;
        this.func = func;
    }

    this( SlotHandler handler, Func func )
    { this( handler.slotController, func ); }

    void opCall( Args args ) { func( args ); }
}

template isSlot(T)
{
    enum isSlot = is( typeof( impl(T.init) ) );
    void impl(Args...)( Slot!Args ) {}
}

unittest
{
    static assert(  isSlot!( Slot!string ) );
    static assert(  isSlot!( Slot!(float,int) ) );
    static assert( !isSlot!( string ) );
}

interface SlotHandler
{
    SlotController slotController() @property;
}
