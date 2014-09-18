module desml.value;

import std.string;
import std.exception;

import desutil.testsuite;

struct Value
{
    string value;
    Value[] array;
    Value[string] dict;

    alias value this;

pure:
    this(this)
    {
        dict = dict.dup;
        array = array.dup;
        dict.rehash();
    }

    this( in string str ) { value = str; }
    this( in Value[] arr )
    {
        // WTF???
        //array = arr.dup;

        foreach( obj; arr )
            array ~= Value(obj);
    }
    this( in Value[string] dct )
    {
        foreach( key, obj; dct )
            dict[key] = Value(obj);
        dict.rehash();
    }
    this( in Value v )
    {
        foreach( key, obj; v.dict )
            dict[key] = Value(obj);
        dict.rehash();

        array = array.dup;
        value = v.value;
    }

    immutable this( in string str ) { value = str; }
    immutable this( in Value[] arr )
    {
        // WTF???
        //array = arr.idup;
        Value[] buf;
        foreach( obj; arr )
            buf ~= Value(obj);
        array = cast(immutable(Value)[])buf;
    }
    immutable this( in Value[string] dct )
    {
        Value[string] buf;
        foreach( key, obj; dct )
            buf[key] = Value(obj);
        buf.rehash();

        dict = assumeUnique(buf);
    }
    immutable this( in Value v )
    {
        Value[string] buf;
        foreach( key, obj; v.dict )
            buf[key] = Value(obj);
        buf.rehash();

        dict = assumeUnique(buf);
        array = array.idup;
        value = v.value;
    }

    string opAssign( string val )
    {
        value = val;
        return val;
    }

    auto append( string name, in Value obj )
    {
        dict[name] = Value(obj);
        return this;
    }

    auto append( string name, in string str )
    {
        dict[name] = Value(str);
        return this;
    }

    auto append( in string str )
    {
        array ~= Value(str);
        return this;
    }

    auto append( in Value obj )
    {
        array ~= Value(obj);
        return this;
    }

    /+ can access dict only if key not one of [value,dict,array]
       and if key is correct DLang identifier +/
    @property ref Value opDispatch(string name)()
    { return dict[name]; }
    @property ref const(Value) opDispatch(string name)() const
    { return dict[name]; }

    ref Value opIndex(string name) { return dict[name]; }
    ref const(Value) opIndex(string name) const { return dict[name]; }

    ref Value opIndex(size_t no) { return array[no]; }
    ref const(Value) opIndex(size_t no) const { return array[no]; }

    bool opBinaryRight(string op)( string name ) const
        if( op == "in" )
    { return !!(name in dict); }

    Value get( string access, lazy Value default_obj = Value.init, string sep="." ) const
    {
        auto access_names = access.split(sep);
        const(Value)* buf = &this;
        foreach( an; access_names )
        {
            if( an in (*buf) ) buf = &((*buf)[an]);
            else return default_obj;
        }
        return Value(*buf);
    }
}

unittest
{
    Value a;
    assert( a.value == "" );
    a.value = "hello";
    assert( a.value == "hello" );

    assert( a == "hello" );
    a = "world";
    assert( a == "world" );
}

unittest
{
    Value a;
    assert( mustExcept!RangeError({ a.one.two; }) );
}

unittest
{
    Value a;
    a = "hello";

    static void test( in string str )
    { assert( str == "hello" ); }

    test(a);
}

unittest
{
    Value a;
    a = "hello";

    auto b = immutable Value(a);

    static void test( in string str )
    { assert( str == "hello" ); }

    test(b);
}

unittest
{
    Value a;
    a.append( "name", "Ivan" );
    assert( "name" in a );
    assert( a["name"] == "Ivan" );
    assert( a.name == "Ivan" );
    a.name = "Petr";
    assert( a.name == "Petr" );
    a.append( "prof", Value().append("count","12") );
    assert( a.prof.count == "12" );
    assert( a.get( "prof.count" ) == "12" );
    assert( a.get( "prof.count.min", Value("3") ) == "3" );
    assert( a.get( "prof.count.min" ) == Value("") );
}

unittest
{
    Value a;

    a.append( "hello" );
    a.append( "world" );
    a.append( Value().append("ok","12") );

    assert( a.array.length == 3 );
    assert( a[0] == "hello" );
    assert( a[1] == "world" );
    assert( a[2] == Value().append("ok","12") );
    assert( a[2].ok == "12" );

    a.append( "array", "32" );
    assert( a.array.length == 3 );
    a.append( "bla bla", "42" );
    assert( a["bla bla"] == "42" );
}

unittest
{
    auto a = Value( "vv" );
    a.append( "dict1", "dv1" );
    a.append( "dict2", "dv2" );
    a.append( "av1" );
    a.append( "av2" );

    auto b = Value( a.dict );
    assert( b.value.length == 0 );
    assert( b.array.length == 0 );
    assert( b.dict == a.dict );
    
    auto c = Value( a.array );
    assert( c.value.length == 0 );
    assert( c.array == a.array );
 
    auto ib = immutable Value( a.dict );
    assert( ib.value.length == 0 );
    assert( ib.array.length == 0 );
    foreach( key; a.dict.keys )
        assert( ib.dict[key] == a.dict[key] );
    
    auto ic = immutable Value( a.array );
    assert( ic.value.length == 0 );
    foreach( i; 0 .. a.array.length )
        assert( ic.array[i] == a.array[i] );
    assert( ic.dict.keys.length == 0 );
}
