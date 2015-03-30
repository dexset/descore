module des.il.util;

import std.algorithm;
import std.exception;
import std.range;
import std.conv : to;

import des.util.stdext.algorithm;
import des.util.testsuite;

import des.math.linear.vector;
import des.math.util.accessstring;

import des.il.region;

///
class ImageException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

void imEnforce(string file=__FILE__, size_t line=__LINE__)( bool val, lazy string msg )
{ enforce( val, new ImageException( msg, file, line ) ); }

alias coord_t = ptrdiff_t;
alias CrdVector(size_t N) = Vector!(N,coord_t);
alias CrdRegion(size_t N) = Region!(N,coord_t);
alias CrdVectorD = CrdVector!0;
alias CrdRegionD = CrdRegion!0;

/++ checks all components
 Returns:
 true if all is positive
 +/
bool isAllCompPositive(V)( in V v )
    if( is( typeof( v[0] ) ) && isNumeric!(typeof(v[0])) )
{
    foreach( e; v ) if( e < 0 ) return false;
    return true;
}

///
unittest
{
    assert(  isAllCompPositive( [1,2,3] ) );
    assert(  isAllCompPositive( vec3( 1,2,3 ) ) );
    assert(  isAllCompPositive( CrdVector!3( 1,2,3 ) ) );
    assert( !isAllCompPositive( [-1,2,3] ) );
}

///
coord_t[] redimSize(A)( size_t K, size_t N, in A[] size ) pure
if( isIntegral!A )
in
{
    assert( K >= N );
    assert( isAllCompPositive( size ) );
}
body
{
    auto ret = new coord_t[](K);
    ret[] = 1;
    foreach( i; 0 .. min( N, size.length ) )
        ret[i] = size[i];
    if( size.length > N )
        ret[N-1] *= reduce!((r,v)=>r*=v)( 1, size[N..$] );
    return ret;
}

///
unittest
{
    assertEq( [1,2,3], redimSize( 3, 3, [1,2,3] ) );
    assertEq( [1,6,1], redimSize( 3, 2, [1,2,3] ) );
    assertEq( [5,6,1], redimSize( 3, 2, [5,3,2] ) );
    assertEq( [5,6], redimSize( 2, 2, [5,3,2] ) );
    assertEq( [30,1,1,1], redimSize( 4, 1, [5,3,2] ) );
}

///
coord_t[] redimSize(A)( size_t N, in A[] size ) pure
if( isIntegral!A )
in { assert( isAllCompPositive( size ) ); }
body { return redimSize( N, N, size ); }

///
unittest
{
    assertEq( [1,2,3], redimSize( 3, [1,2,3] ) );
    assertEq( [1,2,3,1,1], redimSize( 5, [1,2,3] ) );
    assertEq( [1,6], redimSize( 2, [1,2,3] ) );
    assertEq( [6], redimSize( 1, [1,2,3] ) );
    assertEq( [1,1,1,1], redimSize( 4, cast(int[])[] ) );
}

/++ get index of element in 1-dim array by N-dim coordinate

 Params:
 size = N-dim array of sizes by each dimension
 crd = N-dim array of coordinates in N-dim space

 Returns:
 index in 1-dim array
 +/
coord_t getIndex(A,B)( in A[] size, in B[] crd ) pure
if( isIntegral!A && isIntegral!B )
in
{
    assert( size.length == crd.length, "array length mismatch" );
    assert( isAllCompPositive( size ), "negative size" );
    assert( isAllCompPositive( crd ), "negative coordinate" );
    assert( all!"a[0]>a[1]"( zip( size, crd ) ), "range violation" );
}
body
{
    size_t ret;
    foreach( i; 0 .. size.length )
    {
        size_t cm = 1UL;
        foreach( j; 0 .. i ) cm *= size[j];
        ret += crd[i] * cm;
    }
    return ret;
}

///
unittest
{
    assertEq( getIndex( [3,3], [1,1] ), 4 );
    assertEq( getIndex( [4,3], [1,1] ), 5 );
    assertEq( getIndex( [3,3,3], [1,1,1] ), 13 );
}

/++ get coordinate in N-dim space by N-dim size and line index

 Params:
 size = N-dim array of sizes by each dimension
 index = index in 1-dim array

 Retrurns:
 N-dim array of coordinates in N-dim space
 +/
size_t[] getCoord(A)( in A[] size, size_t index ) pure
if( isIntegral!A )
in
{
    assert( isAllCompPositive( size ), "negative size" );
    auto maxindex = new A[]( size.length );
    foreach( i, ref mi; maxindex ) mi = size[i] - 1;
    assert( index <= getIndex( size, maxindex ), "range violation" );
}
body
{
    size_t buf = index;
    auto ret = new size_t[]( size.length );
    foreach_reverse( i; 0 .. size.length )
    {
        auto vol = reduce!((a,b)=>(a*=b))(1U,size[0..i]);
        ret[i] = buf / vol;
        buf = buf % vol;
    }
    return ret;
}

///
unittest
{
    assertEq( getCoord( [3,3,3], 13 ), [1,1,1] );
    auto size = CrdVector!4( 10, 20, 30, 40 );
    auto crd = CrdVector!4( 3, 5, 8, 10 );
    assertEq( crd, getCoord( size, getIndex( size, crd ) ) );
}

/// get line index in origin array by layer line index and layer number
size_t getOrigIndexByLayerCoord(A)( in A[] size, size_t dimNo,
                                    size_t layerIndex, size_t layerNo ) pure
if( isIntegral!A )
in
{
    assert( isAllCompPositive( size ), "negative size" );
    assert( dimNo < size.length );
}
body
{
    auto layerCrd = getCoord( cut( size, dimNo ), layerIndex );
    return getIndex( size, paste( layerCrd, dimNo, layerNo ) );
}

unittest
{
    assertEq( getOrigIndexByLayerCoord( [3,3,3], 2, 4, 1 ), 13 );
}

T[] cut(T)( in T[] arr, size_t N ) pure
in{ assert( N < arr.length ); } body
{ return arr[0..N].dup ~ ( arr.length-1 == N ? [] : arr[N+1..$] ); }

unittest
{
    assertEq( [1,2,3,4].cut(0), [2,3,4] );
    assertEq( [1,2,3,4].cut(2), [1,2,4] );
    assertEq( [1,2,3,4].cut(3), [1,2,3] );
}

T[] paste(T)( in T[] arr, size_t N, T value ) pure
in{ assert( N <= arr.length ); } body
{ return arr[0..N].dup ~ value ~ ( arr.length == N ? [] : arr[N..$] ); }

unittest
{
    assertEq( [1,2,3,4].paste(0,8), [8,1,2,3,4] );
    assertEq( [1,2,3,4].paste(3,8), [1,2,3,8,4] );
    assertEq( [1,2,3,4].paste(4,8), [1,2,3,4,8] );
}

unittest
{
    auto orig = [1,2,3,4];
    assertEq( orig.paste(0,666).cut(0), orig );
    assertEq( orig.paste(1,666).cut(1), orig );
    assertEq( orig.paste(2,666).cut(2), orig );
    assertEq( orig.paste(3,666).cut(3), orig );
}
