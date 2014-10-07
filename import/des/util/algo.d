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

module des.util.algo;

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
