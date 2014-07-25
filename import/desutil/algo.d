module desutil.algo;

public import std.array;
public import std.algorithm;
public import std.range;
public import std.traits;

template amap(fun...) if ( fun.length >= 1 )
{
    auto amap(Range)(Range r) 
        if (isInputRange!(Unqual!Range))
    { return array( map!fun(r) ); }
}

unittest
{
    int[] res = [ 1, 2, 3 ];
    void func( int[] arr ) { res ~= arr; }
    func( amap!(a=>a^^2)(res) );
    assert( res == [ 1, 2, 3, 1, 4, 9 ] );
}

bool oneOf(E,T)( T val )
{
    foreach( pv; [EnumMembers!E] )
        if( pv == val ) return true;
    return false;
}

private version(unittest)
{
    enum TestEnum
    {
        ONE = 1,
        TWO = 2,
        FOUR = 4
    }
}

unittest
{
    assert( !oneOf!TestEnum(0) );
    assert(  oneOf!TestEnum(1) );
    assert(  oneOf!TestEnum(2) );
    assert( !oneOf!TestEnum(3) );
    assert(  oneOf!TestEnum(4) );
    assert( !oneOf!TestEnum(5) );
}

bool oneOf(E,T)( E[] arr, T val )
    if( is( typeof( arr[0] == val ) ) )
{
    foreach( pv; arr ) if( pv == val ) return true;
    return false;
}

unittest
{
    assert( !oneOf( [TestEnum.ONE, TestEnum.TWO], 0) );
    assert(  oneOf( [TestEnum.ONE, TestEnum.TWO], 2) );
}
