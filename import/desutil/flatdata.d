module desutil.flatdata;

import std.traits;
import std.string;
import std.typetuple;

import desmath.basic.traits;

import desutil.testsuite;

pure auto flatData(T,E...)( in E vals ) if( E.length > 0 )
{
    T[] buf;
    foreach( e; vals )
        buf ~= flatValue!T(e);
    return buf;
}

unittest
{
    assert( eq( flatData!float([1.0,2],[[3,4]],5,[6,7]), [1,2,3,4,5,6,7] ) );
    static assert( !__traits(compiles,flatData!char([1.0,2],[[300,4]],5,[6,7])) );
    static assert(  __traits(compiles,flatData!ubyte([1.0,2],[[300,4]],5,[6,7])) );
    static assert(  __traits(compiles,flatData!char("hello", "world")) );
    assert( eq( flatData!cfloat(1-1i,2,3i), [1-1i,2+0i,0+3i] ) );
}

template hasIterableData(T)
{ enum hasIterableData = is( typeof( isIterable!(typeof(T.init.data)) ) ); }

pure auto flatValue(T,E)( in E val )
{
    T[] buf;
    static if( isNumeric!T && isNumeric!E ) buf ~= cast(T)val;
    else static if( isComplex!T && ( isNumeric!E || isImaginary!E) ) buf ~= T(0+0i+val);
    else static if( is(typeof(T(val))) ) buf ~= T(val);
    else static if( isIterable!E ) foreach( v; val ) buf ~= flatValue!T(v);
    else static if( hasIterableData!E ) buf ~= flatValue!T(val.data);
    else static assert(0, format("uncompatible types %s and %s", T.stringof, E.stringof ) );
    return buf;
}
