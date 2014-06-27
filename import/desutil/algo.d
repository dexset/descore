module desutil.algo;

public import std.array;
public import std.algorithm;
public import std.range;
public import std.traits;

template amap(fun...) if ( fun.length >= 1 )
{
    auto amap(Range)(Range r) if (isInputRange!(Unqual!Range))
    { return array( map!fun(r) ); }
}

unittest
{
    int[] res = [ 1, 2, 3 ];
    void func( int[] arr ) { res ~= arr; }
    func( amap!(a=>a^^2)(res) );
    assert( res == [ 1, 2, 3, 1, 4, 9 ] );
}
