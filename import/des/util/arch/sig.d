module des.util.arch.sig;

import des.util.arch.emm;
import des.util.arch.slot;

///
class SignalException : Exception
{ this( string m ) @safe pure nothrow { super(m); } }

///
template isSignal(T)
{
    enum isSignal = is( typeof( impl(T.init) ) );
    void impl(Args...)( Signal!(Args) ) {}
}

///
class Signal(Args...) : SignalLeverage, ExternalMemoryManager
{
    mixin EMM;

protected:

    ///
    alias Slot!Args TSlot;

    ///
    TSlot[] slots;

public:

    ///
    TSlot connect( TSlot slot )
    in { assert( slot !is null ); }
    body
    {
        if( !connected(slot) )
        {
            slots ~= slot;
            slot.control.connect( this );
        }
        return slot;
    }

    ///
    void disconnect( TSlot slot )
    in { assert( slot !is null ); }
    body
    {
        size_t i = indexOf( slot );
        if( i == -1 ) return;
        slots = slots[0..i] ~ ( i != slots.length-1 ? slots[i..$] : [] );
        slot.control.disconnect( this );
    }

    ///
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

    ///
    void disconnect( SlotHandler handler )
    { disconnect( handler.slotController ); }

    ///
    void opCall( Args args ) { foreach( slot; slots ) slot(args); }

protected:

    ///
    ptrdiff_t indexOf( TSlot slot )
    {
        foreach( i, cs; slots )
            if( cs == slot )
                return i;
        return -1;
    }

    ///
    bool connected( TSlot slot )
    { return indexOf(slot) != -1; }

    void selfDestroy()
    {
        foreach( slot; slots )
            slot.control.disconnect( this );
    }
}
///
unittest
{
    string[] messages;
    string[] human_readed;
    string[] robot_readed;
    string[] cliend_okdas;

    class Postal : ExternalMemoryManager
    {
        mixin EMM;
        Signal!string onMessage;
        this() { onMessage = newEMM!(Signal!string); }
        void message( string msg )
        {
            messages ~= msg;
            onMessage( msg );
        }
    }

    class Client : SlotHandler, ExternalMemoryManager
    {
        mixin EMM;

        SlotController sc;
        Slot!string read_slot;
        Slot!string okda_slot;

        this()
        {
            sc = newEMM!SlotController;
            read_slot = newEMM!(Slot!string)(this,&read);
            okda_slot = newEMM!(Slot!string)(this,&okda);
        }

        SlotController slotController() @property { return sc; }

        abstract void read( string msg );

        void okda( string msg ) { cliend_okdas ~= msg; }
    }

    auto human = new class Client
    { override void read( string msg ) { human_readed ~= msg; } };

    auto robot = new class Client
    { override void read( string msg ) { robot_readed ~= msg; } };

    auto postal = new Postal;

    postal.message( "test" );
    assert( messages.length == 1 );
    assert( messages[0] == "test" );
    assert( human_readed.length == 0 );
    assert( robot_readed.length == 0 );
    assert( cliend_okdas.length == 0 );

    postal.onMessage.connect( human.read_slot );
    postal.onMessage.connect( human.read_slot );
    postal.onMessage.connect( human.okda_slot );

    postal.message( "hello" );
    assert( messages.length == 2 );
    assert( human_readed.length == 1 );
    assert( human_readed[0] == "hello" );
    assert( robot_readed.length == 0 );
    assert( cliend_okdas.length == 1 );

    postal.onMessage.connect( robot.read_slot );

    postal.message( "tech" );
    assert( messages.length == 3 );
    assert( human_readed.length == 2 );
    assert( robot_readed.length == 1 );
    assert( robot_readed[0] == "tech" );
    assert( cliend_okdas.length == 2 );

    postal.onMessage.disconnect( human );

    postal.message( "tech2" );
    assert( messages.length == 4 );
    assert( human_readed.length == 2 );
    assert( robot_readed.length == 2 );
    assert( cliend_okdas.length == 2 );

    human.read( "ok" );
    assert( human_readed.length == 3 );

    robot.destroy();

    postal.message( "tech3" );

    assert( messages.length == 5 );
    assert( human_readed.length == 3 );
    assert( robot_readed.length == 2 );
    assert( cliend_okdas.length == 2 );

    postal.onMessage.connect( human.read_slot );
    postal.onMessage.connect( human.okda_slot );

    postal.message( "bb" );
    assert( messages.length == 6 );
    assert( human_readed.length == 4 );
    assert( robot_readed.length == 2 );
    assert( cliend_okdas.length == 3 );

    postal.onMessage.disconnect( human.okda_slot );

    postal.message( "fbb" );
    assert( messages.length == 7 );
    assert( human_readed.length == 5 );
    assert( robot_readed.length == 2 );
    assert( cliend_okdas.length == 3 );
}

///
class SignalReverse( Args... ) : Signal!Args
{
    ///
    override void opCall( Args args )
    { foreach_reverse( slot; slots ) slot( args ); }
}

///
class SignalBox( Args... ) : Signal!Args
{
    this()
    {
        begin = newEMM!(Signal!Args);
        end = newEMM!(SignalReverse!Args);
    }

    ///
    Signal!Args begin;
    ///
    SignalReverse!Args end;

    /++ calls:
     +  0. begin
     +  0. this
     +  0. end
     +/
    override void opCall( Args args )
    {
        begin( args );
        super.opCall( args );
        end( args );
    }
}

unittest
{
    static assert(  isSignal!( Signal!string ) );
    static assert(  isSignal!( Signal!(float,int) ) );
    static assert(  isSignal!( SignalReverse!string ) );
    static assert(  isSignal!( SignalBox!(float,int) ) );
    static assert( !isSignal!( string ) );
    static assert( !isSignal!( int ) );
    static assert( !isSignal!( Slot!int ) );
}

