module des.util.arch.base;

import std.stdio;
import std.string;

import des.util.arch.sig;
import des.util.arch.slot;
import des.util.arch.emm;

import des.util.stdext.traits;

import des.util.logsys;

///
template isObject(alias f) { enum isObject = __traits(compiles,typeof(f)); }

///
template isSignalObj(alias f)
{
    static if( isObject!f ) enum isSignalObj = isSignal!(typeof(f));
    else enum isSignalObj = false;
}

///
interface DesBase : ExternalMemoryManager, SlotHandler
{
    protected
    {
        ///
        void createSlotController();

        void __createSignals();

        ///
        final void prepareDES()
        {
            createSlotController();
            __createSignals();
        }
    }

    ///
    mixin template DES()
    {
        import des.util.stdext.traits;

        static if( !is(typeof(__DES_BASE_CLASS)) )
        {
            mixin EMM;

            enum __DES_BASE_CLASS = true;

            private SlotController __slot_controller;
            final SlotController slotController() @property { return __slot_controller; }

            protected
            {
                void createSlotController() { __slot_controller = newEMM!SlotController; }
                void __createSignals() { mixin( __createSignalsMixin!(typeof(this)) ); }
            }
        }
        else
        {
            override protected
            {
                void __createSignals() { mixin( __createSignalsMixin!(typeof(this)) ); }
            }
        }
    }

    template allSignalNames(T)
    {
        template isSignalMember(string n)
        {
            static if( __traits(compiles,typeof(__traits(getMember,T,n))) )
                enum isSignalMember = isSignal!(typeof(__traits(getMember,T,n)));
            else enum isSignalMember = false;
        }

        alias allSignalNames = staticFilter!( isSignalMember, __traits(allMembers,T) );
    }

    static final protected @property
    {
        string __createSignalsMixin(T)()//if( is( T : DesBase ) )
        {
            string[] ret;

            enum list = [ allSignalNames!T ];

            static if( list.length == 0 ) return "";
            else
            {
                foreach( sig; list )
                    ret ~= format( "%1$s = newEMM!(typeof(%1$s))();", sig );

                return ret.join("\n");
            }
        }
    }

    ///
    final auto newSlot(Args...)( void delegate(Args) fnc )
    { return newEMM!(Slot!Args)( this, fnc ); }

    ///
    final auto connect(Args...)( Signal!Args sig, void delegate(Args) fnc )
    in { assert( sig !is null, "signal is null" ); } body
    {
        auto ret = newSlot!Args( fnc );
        sig.connect( ret );
        logger.Debug( "sig: %s, fnc: %s", sig, fnc );
        return ret;
    }
}

///
class DesObject : DesBase
{
    mixin DES;
    this() { prepareDES(); }
}

///
unittest
{
    static class Sigsig : DesObject
    {
        mixin DES;
        Signal!string message;
        Signal!float number;

        Signal!(string,int) comp;
    }

    static class C1 : DesObject
    {
        mixin DES;
        string[] messages;
        void notSlot( float x ) { }
        void listen( string msg ) { messages ~= msg; }
    }

    class C2 : C1
    {
        mixin DES;
        float a;
        void abcFunc12( float x ) { a = x + 3.15; }
    }

    class C3 : DesObject
    {
        mixin DES;

        string str;
        int num;

        void cfunc( string s, int i )
        {
            str = s;
            num = i;
        }
    }

    auto sigsig = new Sigsig;
    auto client = new C2;
    auto c3 = new C3;

    sigsig.message.connect( client.newSlot( &(client.listen) ) );
    auto client_abcFunc12_slot = sigsig.number.connect( client.newSlot( &(client.abcFunc12) ) );

    sigsig.message( "hello" );

    assert( client.messages.length == 1 );
    assert( client.messages[0] == "hello" );

    sigsig.number( 0 );

    import std.math;
    assert( abs(client.a - 3.15) < float.epsilon );

    sigsig.number.disconnect( client_abcFunc12_slot );

    sigsig.number( 2 );
    assert( abs(client.a - 3.15) < float.epsilon );
    sigsig.number.connect( client_abcFunc12_slot );
    sigsig.number( 2 );
    assert( abs(client.a - 5.15) < float.epsilon );

    sigsig.comp.connect( c3.newSlot( &c3.cfunc ) );
    sigsig.comp( "okda", 13 );
    assert( c3.str == "okda" );
    assert( c3.num == 13 );
}

unittest
{
    class Sig : DesObject
    {
        mixin DES;
        Signal!(string,int) s;
    }

    class Obj : DesObject {}

    auto sig = new Sig;
    auto obj = new Obj;

    string[] str_arr;
    int[] int_arr;

    sig.s.connect( obj.newSlot(( string s, int i )
                {
                    str_arr ~= s;
                    int_arr ~= i;
                }) );

    sig.s( "hello", 3 );
    sig.s( "world", 5 );

    assert( str_arr == ["hello","world"] );
    assert( int_arr == [3,5] );
}

unittest
{
    class C1 : DesObject
    {
        mixin DES;
        Signal!(string) sig;
    }

    class C2 : C1 
    {
        string[] buf;
        this() { connect( sig, (string s){ buf ~= s; } ); }
    }

    auto c2 = new C2;

    c2.sig( "hello" );
    assert( c2.buf == ["hello"] );
}


unittest
{
    class C1 : DesObject
    {
        mixin DES;
        Signal!() empty;
        SignalBox!int number;
    }

    auto c1 = new C1;

    bool empty_call = false;
    c1.connect( c1.empty, { empty_call = true; } );

    assert( !empty_call );
    c1.empty();
    assert( empty_call );

    int xx = 0;
    int ss = 0;
    int ee = 0;
    c1.connect( c1.number.begin, (int v){ ss = v; } );
    c1.connect( c1.number.end, (int v){ ee = v; } );
    c1.connect( c1.number, (int v){ xx = v; } );
    assert( xx == 0 );
    c1.number(12);
    assert( xx == 12 );
    assert( ss == 12 );
    assert( ee == 12 );
}
