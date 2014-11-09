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

module des.math.util.flatdata;

import std.traits;
import std.string;
import std.typetuple;

import des.util.testsuite;
import des.math.basic.traits;

pure auto flatData(T,E...)( in E vals ) if( E.length > 0 )
{
    T[] buf;
    foreach( e; vals ) buf ~= flatValue!T(e);
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
    static if( isNumeric!T && isNumeric!E ) return [ cast(T)val ];
    else static if( isComplex!T && ( isNumeric!E || isImaginary!E) ) return [ T(0+0i+val) ];
    else static if( is(typeof(T(val))) ) return [ T(val) ];
    else static if( isIterable!E )
    {
        T[] buf;
        foreach( v; val )
            buf ~= flatValue!T(v);
        return buf;
    }
    else static if( hasIterableData!E ) return flatValue!T(val.data);
    else static assert(0, format("uncompatible types %s and %s", T.stringof, E.stringof ) );
}
