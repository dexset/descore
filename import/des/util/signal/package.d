module des.util.signal;

public
{
    import des.util.signal.slot;
    import des.util.signal.signal;
    import des.util.object.emm;
}

unittest
{
    string[] messages;
    string[] human_readed;
    string[] robot_readed;
    string[] cliend_okdas;

    class Postal : ExternalMemoryManager
    {
        mixin EmptyImplementEMM;
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
        mixin EmptyImplementEMM;

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
