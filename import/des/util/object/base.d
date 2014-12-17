module des.util.object.base;

import std.stdio;
import std.string;

import des.util.signal;
import des.util.object.emm;
import des.util.stdext.traits;

enum slot;

template isObject(alias f) { enum isObject = __traits(compiles,typeof(f)); }

template isSlotObj(alias f)
{
    static if( isObject!f ) enum isSlotObj = isSlot!(typeof(f));
    else enum isSlotObj = false;
}

template isSignalObj(alias f)
{
    static if( isObject!f ) enum isSignalObj = isSignal!(typeof(f));
    else enum isSignalObj = false;
}

interface DesBase : ExternalMemoryManager, SlotHandler
{
    protected
    {
        void createSlotController();
        void __createSignals();
        void __createSlots();

        final void prepareDES()
        {
            createSlotController();
            __createSignals();
            __createSlots();
        }
    }

    mixin template DES()
    {
        mixin DefineTemplateVars!( Slot, findAndPrepareSlotTemplateVarDefs!(typeof(this)) );

        static if( is(typeof(__DES_BASE_CLASS)) )
        {
            override protected
            {
                void __createSignals() { mixin( __createSignalsMixin!(typeof(this)) ); }
                void __createSlots() { mixin( __createSlotsMixin!(typeof(this)) ); }
            }
        }
        else
        {
            mixin EMM;

            enum __DES_BASE_CLASS = true;

            private SlotController __slot_controller;
            final SlotController slotController() @property { return __slot_controller; }

            protected
            {
                void createSlotController() { __slot_controller = newEMM!SlotController; }
                void __createSignals() { mixin( __createSignalsMixin!(typeof(this)) ); }
                void __createSlots() { mixin( __createSlotsMixin!(typeof(this)) ); }
            }
        }
    }

    template allSlotNames(T)
    {
        template isVoidSlotFunc(string n)
        {
            static if( __traits(compiles,__traits(hasMember,T,n)) &&
                    __traits(hasMember,T,n) &&
                    __traits(compiles,__traits(getMember,T,n)) &&
                    __traits(compiles,tt!(__traits(getMember,T,n))) &&
                    true )
                enum isVoidSlotFunc = impl!(n,__traits(getMember,T,n));
            else enum isVoidSlotFunc = false;

            template tt(alias f){}

            template impl(string name, alias f)
            {
                static if( isCallable!f && hasAttrib!(slot,f) )
                {
                    static assert( is(ReturnType!f == void),
                            format( "slot func '%s' for class '%s' must be void", name, T.stringof ) );
                    enum impl = true;
                }
                else enum impl = false;
            }
        }

        alias allSlotNames = staticFilter!( isVoidSlotFunc, __traits(allMembers,T) );
    }
    
    template findAndPrepareSlotTemplateVarDefs(T)
    {
        template noDefSlotObject(string n)
        { enum noDefSlotObject = !(__traits(hasMember,T,getSlotName(n))); }

        alias all_slots = allSlotNames!T;

        static if( all_slots.length > 0 )
        {
            alias new_slots = staticFilter!(noDefSlotObject,all_slots);

            template TVD(string name)
            {
                alias TVD = TemplateVarDef!( getSlotName(name), 
                        ParameterTypeTuple!(__traits(getMember,T,name)) );
            }

            alias findAndPrepareSlotTemplateVarDefs = staticMap!( TVD, new_slots );
        }
        else alias findAndPrepareSlotTemplateVarDefs = TypeTuple!();
    }

    static final protected @property
    {
        string __createSignalsMixin(T)() if( is( T : DesBase ) )
        {
            string[] ret;

            enum list = [ filterMembers!( isSignalObj, T ) ];

            static if( list.length == 0 ) return "";
            else
            {
                foreach( sig; list )
                    ret ~= format( "%1$s = newEMM!(typeof(%1$s))();", sig );

                return ret.join("\n");
            }
        }

        string __createSlotsMixin(T)() if( is( T : DesBase ) )
        {
            string[] ret;

            enum list = [ allSlotNames!T ];

            static if( list.length == 0 ) return "";
            else
            {
                foreach( sl; list )
                    ret ~= format( "%1$s = newEMM!(typeof(%1$s))(this,&(%2$s));", getSlotName(sl), sl );
                return ret.join("\n");
            }
        }
    }

    static string getSlotName(string n) pure nothrow { return n ~ "_slot"; }

    final auto newSlot(Args...)( void delegate(Args) fnc )
    { return newEMM!(Slot!Args)( this, fnc ); }

    final void connect(Args...)( Signal!Args sig, void delegate(Args) fnc )
    { sig.connect( newSlot!Args( fnc ) ); }
}

unittest
{
    static class A : DesBase
    {
        mixin DES;
        mixin EmptyImplementEMM;

        Signal!(int,int) mouse;

        void abc() @slot {}
    }

    static assert( __traits(hasMember,A,DesBase.getSlotName("abc")) );
}

void connect(string slotname,SIG,DB)( SIG signal, DB shandler )
    if( isSignal!SIG && is( DB : DesBase ) )
{
    auto slot = __traits( getMember, shandler, DesBase.getSlotName(slotname) );
    signal.connect( slot );
}

class DesObject : DesBase
{
    mixin DES;
    mixin EmptyImplementEMM;

    this() { prepareDES(); }
}

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
        void listen( string msg ) @slot { messages ~= msg; }
    }

    class C2 : C1
    {
        mixin DES;
        float a;
        void abcFunc12( float x ) @slot { a = x + 3.15; }
    }

    class C3 : DesObject
    {
        mixin DES;

        string str;
        int num;

        void cfunc( string s, int i ) @slot
        {
            str = s;
            num = i;
        }
    }

    auto sigsig = new Sigsig;
    auto client = new C2;
    auto c3 = new C3;

    static assert( !__traits(compiles,sigsig.message.connect( client.notSlot_slot ) ) );
    sigsig.message.connect( client.listen_slot );
    sigsig.number.connect( client.abcFunc12_slot );

    static assert( !__traits(compiles, connect!( sigsig.onNumber, client, "notSlot" ) ) );

    sigsig.message( "hello" );

    assert( client.messages.length == 1 );
    assert( client.messages[0] == "hello" );

    sigsig.number( 0 );

    import std.math;
    assert( abs(client.a - 3.15) < float.epsilon );

    sigsig.number.disconnect( client.abcFunc12_slot );

    sigsig.number( 2 );
    assert( abs(client.a - 3.15) < float.epsilon );
    sigsig.number.connect( client.abcFunc12_slot );
    sigsig.number( 2 );
    assert( abs(client.a - 5.15) < float.epsilon );

    sigsig.comp.connect( c3.cfunc_slot );
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

    class Obj : DesObject { mixin DES; }

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

        this()
        {
            connect( sig, (string s){ buf ~= s; } );
        }
    }

    auto c2 = new C2;

    c2.sig( "hello" );
    assert( c2.buf == ["hello"] );
}
