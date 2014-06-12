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

module desmath.method.approx.interp;

public import desmath.basic.traits;
import std.algorithm;
import std.exception;

struct InterpolateTableData(T) if( hasBasicMathOp!T ) { float key; T val; }

auto line_interpolate(T)( in InterpolateTableData!T[] tbl, float k, bool line_end=false )
    if( hasBasicMathOp!T )
{
    enforce( tbl.length > 1 );
    size_t i = tbl.length - find!"a.key > b"( tbl, k ).length;
    if( !line_end )
    {
        if( i <= 0 ) return tbl[0].val;
        else if( i >= tbl.length ) return tbl[$-1].val;
    }
    else
    {
        if( i < 1 ) i = 1;
        else if( i > tbl.length-1 ) i = tbl.length-1;
    }

    auto a = tbl[i-1];
    auto b = tbl[i];
    return cast(T)( a.val + ( b.val - a.val ) * ( ( k - a.key ) / ( b.key - a.key ) ) );
}

unittest
{
    alias InterpolateTableData!float TT;
    auto tbl =
        [
        TT( 0, 10 ),
        TT( 10, 18 ),
        TT( 25, 20 ),
        TT( 50, 13 ),
        TT( 55, 25 )
        ];

    assert( line_interpolate( tbl, 0 ) == 10 );
    assert( line_interpolate( tbl, 5 ) == 14 );
    assert( line_interpolate( tbl, 10 ) == 18 );
    assert( line_interpolate( tbl, -10 ) == 10 );
    assert( line_interpolate( tbl, 80 ) == 25 );
}

unittest
{
    alias InterpolateTableData!double TD;
    auto tbl =
        [
        TD( 0, 0 ),
        TD( 1, 1 ),
        TD( 2, 3 ),
        TD( 3, 4 )
        ];
    assert( line_interpolate( tbl, 5, true ) == 6 );
    assert( line_interpolate( tbl, -3, true ) == -3 );
}

unittest
{
    import desmath.linear.vector;
    alias InterpolateTableData!col3 TC;
    auto tbl =
        [
        TC( 0, col3(1,0,0) ),
        TC( 1, col3(0,1,0) ),
        TC( 2, col3(0,0,1) )
        ];

    assert( line_interpolate( tbl, -1 ) == col3(1,0,0) );
    assert( line_interpolate( tbl, 0 ) == col3(1,0,0) );
    assert( line_interpolate( tbl, 0.5 ) == col3(0.5,0.5,0) );
    assert( line_interpolate( tbl, 3 ) == col3(0,0,1) );
}
