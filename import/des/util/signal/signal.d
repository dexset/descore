module des.util.signal.signal;

import des.util.object.emm;
import des.util.signal.slot;

class SignalException : Exception
{ this( string m ) @safe pure nothrow { super(m); } }

class Signal(Args...) : SignalLeverage, ExternalMemoryManager
{
    mixin DirectEMM;

protected:

    alias Slot!Args TSlot;
    alias TSlot.Func SlotFunc;

    TSlot[] slots;

public:

    void connect( TSlot slot )
    in { assert( slot !is null ); }
    body
    {
        if( connected( slot ) ) return;
        slots ~= slot;
        slot.control.connect( this );
    }

    void disconnect( TSlot slot )
    in { assert( slot !is null ); }
    body
    {
        size_t i = indexOf( slot );
        if( i == -1 ) return;
        slots = slots[0..i] ~ ( i != slots.length-1 ? slots[i..$] : [] );
        slot.control.disconnect( this );
    }

    override void disconnect( SlotController sc )
    in { assert( sc !is null ); }
    body
    {
        TSlot[] buf;
        SlotController[] dis;
        foreach( slot; slots )
            if( sc != slot.control ) buf ~= slot;
            else dis ~= slot.control;
        slots = buf;
        foreach( s; dis ) s.disconnect(this);
    }

    void disconnect( SlotHandler handler )
    { disconnect( handler.slotController ); }

    void opCall( Args args ) { foreach( slot; slots ) slot(args); }

protected:

    ptrdiff_t indexOf( TSlot slot )
    {
        foreach( i, cs; slots )
            if( cs == slot )
                return i;
        return -1;
    }

    bool connected( TSlot slot )
    { return indexOf(slot) != -1; }

    void selfDestroy()
    {
        foreach( slot; slots )
            slot.control.disconnect( this );
    }
}

template isSignal(T)
{
    enum isSignal = is( typeof( impl(T.init) ) );
    void impl(Args...)( Signal!(Args) ) {}
}

unittest
{
    static assert(  isSignal!( Signal!string ) );
    static assert(  isSignal!( Signal!(float,int) ) );
    static assert( !isSignal!( string ) );

}

alias Signal!() EmptySignal;
