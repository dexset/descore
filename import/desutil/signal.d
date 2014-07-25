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

module desutil.signal;

class SignalException: Exception 
{ @safe pure nothrow this( string msg ){ super( msg ); } }

struct Signal(Args...)
{ 
    /++ делегат +/
    alias void delegate(Args) slottype;

    /++ "список дел" +/
    slottype[] slots; 
    void clear() { slots.length = 0; }

    /++ добавляет в список делегат +/
    void connect( slottype f )
    {
        if( f is null ) throw new SignalException( "signal get null delegate" );
        slots ~=  f;
    }

    /++ вызывает все делегаты в прямом порядке +/
    void opCall( Args args )
    { foreach( slot; slots ) slot( args ); }

    /++ вызывает все делегаты в обратном порядке +/
    void callReverse( Args args )
    { foreach_reverse( slot; slots ) slot( args ); }
}

alias Signal!() EmptySignal;

unittest
{
    uint[] array;
    EmptySignal stest;
    stest.connect( (){ array ~= 0; } );
    stest.connect( (){ array ~= 3; } );
    assert( array.length == 0 );
    stest();
    assert( array.length == 2 );
    assert( array == [ 0, 3 ] );
    stest.callReverse();
    assert( array.length == 4 );
    assert( array == [ 0, 3, 3, 0 ] );

    string[] sarr;
    Signal!string strsignal;
    with( strsignal )
    {
        connect( ( str ){ sarr ~= str; } );
        connect( ( str ){ sarr ~= str ~ str; } );
    }

    assert( sarr.length == 0 );
    strsignal( "ok" );
    assert( sarr == [ "ok", "okok" ] );
}

struct NamedSignal( TName, Args... )
{
    alias void delegate(Args) slottype;
    slottype[TName] slots;
    void clear() { slots.clear(); }

    /++ добавляет в список делегат с определённым именем +/
    void connect( TName name, slottype f )
    {
        if( f is null ) throw new SignalException( "signal get null delegate" );
        slots[name] = f;
    }

    /++ вызывает делегат под именем +/
    bool opCall( TName name, Args args )
    { 
        auto fun = name in slots;
        if( fun !is null )
        {
            (*fun)( args );
            return true;
        }
        return false;
    }

    /++ позволяет вызвать несколько именнованых делегатов +/
    TName[] opCall( TName[] nlist, Args args )
    {
        TName[] ret;
        foreach( name; nlist )
            if( this.opCall( name, args ) )
                ret ~= name;
        return ret;
    }
}

unittest
{
    size_t[] arr;

    alias NamedSignal!(string, size_t) SU_sig;

    SU_sig susig;

    susig.connect( "add", (a){ arr ~= a; } );
    susig.connect( "remove", (a){ arr = arr[0 .. a] ~ arr[a+1 .. $]; } );

    susig( "add", 10 );
    susig( "add", 15 );

    assert( arr == [ 10, 15 ] );

    susig( "add", 20 );
    auto ret = susig( "add", 25 );

    assert( arr == [ 10, 15, 20, 25 ] );
    assert( ret == true );

    ret = susig( "remove", 1 ); 
    assert( arr == [ 10, 20, 25 ] );
    assert( ret == true );

    ret = susig( "get", 25 );
    assert( arr == [ 10, 20, 25 ] );
    assert( ret == false );

    auto ret_names = susig( ["add", "get"], 35 );
    assert( ret_names == ["add"] );
    assert( arr == [ 10, 20, 25, 35 ] );
}

/++
Расширяет концепцию Signal, выполняет в прямом порядке 
делегаты из списка begin, затем выполняет в прямом порядке контент,
затем в обратном делегаты из списка end.

See_Also: Signal
+/
struct SignalBox(Args...)
{
    /++ делегат +/
    alias void delegate(Args) slottype;

    slottype[] begin;
    slottype[] end;
    slottype[] list;
    void clear() 
    { 
        begin.length = 0; 
        list.length = 0; 
        end.length = 0; 
    }

    /++ добавляет пару делегатов +/
    void addPair( slottype b, slottype e )
    {
        if( b is null ) throw new SignalException( "signalbox get null open delegate" );
        if( e is null ) throw new SignalException( "signalbox get null close delegate" );
        begin ~= b;
        end ~= e;
    }

    /++ добавляет делегат открытия +/
    void addBegin( slottype f )
    {
        if( f is null ) throw new SignalException( "signalbox get null open delegate" );
        begin ~= f;
    }

    /++ добавляет делегат закрытия +/
    void addEnd( slottype f )
    {
        if( f is null ) throw new SignalException( "signalbox get null close delegate" );
        end ~= f;
    }

    /++ добавляет делегат открытия +/
    void addBeginF( slottype f )
    {
        if( f is null ) throw new SignalException( "signalbox get null open delegate" );
        begin = f ~ begin;
    }

    /++ добавляет делегат закрытия +/
    void addEndF( slottype f )
    {
        if( f is null ) throw new SignalException( "signalbox get null close delegate" );
        end = f ~ end;
    }

    /++ добавляет контент +/
    void connect( slottype f )
    {
        if( f is null ) throw new SignalException( "signalbox get null content delegate" );
        list ~= f;
    }

    /++ производит последовательный вызов всех begin, затем контента, затем end в обратном порядке +/
    void opCall( Args args )
    {
        call_begin( args );
        call_list( args );
        call_end( args );
    }

    void call_begin( Args args ) { foreach( f; begin ) f( args ); }
    void call_list( Args args ) { foreach( f; list ) f( args ); }
    void call_end( Args args ) { foreach_reverse( f; end ) f( args ); }
}

alias SignalBox!() SignalBoxNoArgs;

unittest
{
    string[] arr;
    SignalBoxNoArgs stest;
    stest.addPair( (){ arr ~= "open"; }, (){ arr ~= "close"; } );
    stest.connect( (){ arr ~= "content"; } );
    assert( arr.length == 0 );
    stest();
    assert( arr.length == 3 );
    assert( arr == [ "open", "content", "close" ] );
    auto except_test = false;
    try
        stest.connect( null );
    catch( SignalException e )
        except_test = true;
    assert( except_test );
}

/++ 
Условный вызов всех слотов.

Поведение аналогичное Signal происходит в случае, если
все делегаты из списка условий возвращают значение, принятое за верное.
Иначе выполняется список altslots.
+/
struct ConditionSignal(Args...)
{
    /++ тип условия

         если trueval совпадает с возвращаемым значением делегата
         условие считается выполненым
    +/
    struct condition
    {
        /++ делегат +/
        bool delegate(Args) fun; 
        /++ значение, принятое за верное +/
        bool trueval=false; 
    }

    /++ делегат +/
    alias void delegate(Args) slottype;

    condition[] conds;
    slottype[] always;
    slottype[] slots;
    slottype[] altslots;

    void clear()
    {
        conds.length = 0;
        always.length = 0;
        slots.length = 0;
        altslots.length = 0;
    }

    /++ добавляет условие в список
        Params:
        f = делегат проверки
        trueval = "верное" значение
        +/
    void addCondition( bool delegate(Args) f, bool trueval=false )
    {
        if( f is null ) throw new SignalException( "get null condition delegate" ~ __FUNCTION__ );
        conds ~= condition( f, trueval );
    }

    /++ добавляет обязательный вызов
     +/
    void connectAlways( slottype f )
    {
        if( f is null ) throw new SignalException( "get null delegate" ~ __FUNCTION__  );
        always ~= f;
    }

    /++ добавляет слот в список slots
     +/
    void connect( slottype f )
    {
        if( f is null ) throw new SignalException( "get null delegate" ~ __FUNCTION__  );
        slots ~= f;
    }

    /++ добавляет слот в список altslots
     +/
    void connectAlt( slottype f )
    {
        if( f is null ) throw new SignalException( "get null delegate" ~ __FUNCTION__  );
        altslots ~= f;
    }

    /++ вызывает последовательно сначала условия, потом слоты

        при невыполнении условия прекращает проверку
        выполняет вызов слотов из списка altslots
    +/
    bool opCall( Args args )
    {
        bool ok = true;

        foreach( a; always ) a( args );

        foreach( c; conds )
            if( c.fun( args ) != c.trueval ) 
            {
                ok = false;
                break;
            }

        if( ok ) foreach( f; slots ) f( args );
        else foreach( f; altslots ) f( args );

        return ok;
    }
}

unittest
{
    bool cond = true;

    int[] arr;

    ConditionSignal!() stest;
    stest.addCondition( (){ return true; }, true );
    stest.connect( (){ arr ~= 0; } );
    stest.connectAlt( (){ arr ~= 1; } );

    stest();
    assert( arr == [ 0 ] );
    stest.addCondition( (){ return true; } );
    stest();
    assert( arr == [ 0, 1 ] );
}
