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
