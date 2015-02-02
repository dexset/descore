module des.il.util;

import std.algorithm;
import std.exception;
import std.range;
import std.conv : to;

import des.util.stdext.algorithm;
import des.util.testsuite;

import des.math.linear.vector;
import des.math.util.accessstring;

///
class ImageException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); } 
}

string coordinateAccessString( size_t N, string VVASES=" ", string VVASVS="|" ) pure
{
    if( N > 3 ) return "";

    string[] v1 = [ "x", "y", "z" ][0 .. N];
    string[] v2 = [ "abscissa", "ordinate", "applicate" ][0 .. N];

    return arrayAccessStringCtor( VVASES, VVASVS, v1, v2 );
}

unittest
{
    static assert( coordinateAccessString(4) == "" );
    static assert( coordinateAccessString(3) == "x y z|abscissa ordinate applicate" );
    static assert( coordinateAccessString(2) == "x y|abscissa ordinate" );
    static assert( isCompatibleArrayAccessStrings( 2, coordinateAccessString(2), " ", "|" ) ); 
}

string sizeAccessString( size_t N, string VVASES=" ", string VVASVS="|" ) pure
{
    if( N > 3 ) return "";

    string[] v1 = [ "w", "h", "d" ][0 .. N];
    string[] v2 = [ "width", "height", "depth" ][0 .. N];

    return arrayAccessStringCtor( VVASES, VVASVS, v1, v2 );
}

unittest
{
    static assert( sizeAccessString(4) == "" );
    static assert( sizeAccessString(3) == "w h d|width height depth" );
    static assert( sizeAccessString(2) == "w h|width height" );
    static assert( isCompatibleArrayAccessStrings( 2, sizeAccessString(2), " ", "|" ) ); 
}

string volumeAccessString( size_t N, string VVASES=" ", string VVASVS="|" ) pure
{
    if( N > 3 ) return "";

    string[] c1 = [ "x", "y", "z" ][0 .. N];
    string[] c2 = [ "abscissa", "ordinate", "applicate" ][0 .. N];

    string[] s1 = [ "w", "h", "d" ][0 .. N];
    string[] s2 = [ "width", "height", "depth" ][0 .. N];

    return arrayAccessStringCtor( VVASES, VVASVS, c1 ~ s1, c2 ~ s2 );
}

unittest
{
    static assert( volumeAccessString(4) == "" );
    static assert( volumeAccessString(3) == "x y z w h d|abscissa ordinate applicate width height depth" );
    static assert( volumeAccessString(2) == "x y w h|abscissa ordinate width height" );
    static assert( isCompatibleArrayAccessStrings( 4, volumeAccessString(2), " ", "|" ) ); 
}

alias CrdVector(size_t N) = Vector!(N,ptrdiff_t);

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

/++ get index of element in 1-dim array by N-dim coordinate

 Params:
 size = N-dim array of sizes by each dimension
 crd = N-dim array of coordinates in N-dim space

 Returns:
 index in 1-dim array
 +/
size_t getIndex(size_t N,A,B)( in Vector!(N,A) size, in Vector!(N,B) crd ) pure
if( isIntegral!A && isIntegral!B )
in
{
    assert( isAllCompPositive( size ) );
    assert( isAllCompPositive( crd ) );
    assert( all!"a[0]>a[1]"( zip( size.data.dup, crd.data.dup ) ), "range violation" );
}
body
{
    size_t ret;
    foreach( i; 0 .. N )
    {
        auto v = reduce!((a,b)=>(a*=b))(1UL,size[0..i]);
        ret += crd[i] * v;
    }
    return ret;
}

version(todos) pragma( msg, __FILE__,":", __LINE__, " TODO: add tests to indexCalc" );

/++ get coordinate in N-dim space by N-dim size and line index
 
 Params:
 size = N-dim array of sizes by each dimension
 index = index in 1-dim array

 Retrurns:
 N-dim array of coordinates in N-dim space
 +/
CrdVector!N getCoord(size_t N,A)( in Vector!(N,A) size, size_t index ) pure
if( isIntegral!A )
in
{
    assert( isAllCompPositive( size ) );
    assert( index <= getIndex( size, CrdVector!N(size)-CrdVector!N(1) ), "range violation" );
}
body
{
    size_t buf = index;
    CrdVector!N ret;
    foreach_reverse( i; 0 .. N )
    {
        auto vol = reduce!((a,b)=>(a*=b))(1U,size[0..i]);
        ret[i] = buf / vol;
        buf = buf % vol;
    }
    return ret;
}

unittest
{
    auto size = CrdVector!4( 10, 20, 30, 40 );
    auto crd = CrdVector!4( 3, 5, 8, 10 );
    assert( eq( crd, getCoord( size, getIndex( size, crd ) ) ) );
}

/++ get line index in origin array by layer line index and layer number

 Params:
 size = original size
 K = number of dimension
 lindex = line index in layer
 lno = layer number
 +/
size_t getOrigIndexByLayerCoord(size_t N,A)( in Vector!(N,A) size, size_t K, size_t lindex, size_t lno ) pure
if( isIntegral!A )
in { assert( K < N ); } body
{
    auto lcrd = getCoord( ivec!(N-1)( removeStat( size, K ) ), lindex );
    return getIndex( size, ivec!N( pasteStat( lcrd, K, lno ) ) );
}

/++ remove value from static array

 Params:
 arr = array
 K = index to remove
 +/
T[N-1] removeStat(T,size_t N)( in T[N] arr, size_t K ) pure
in { assert( K < N ); } body
{
    if( K == N-1 ) return cast(T[N-1])arr[0..$-1];
    else return to!(T[N-1])( arr[0..K] ~ arr[K+1..$] );
}

///
unittest
{
    size_t[3] arr = [ 0, 1, 2 ];
    static assert( is( typeof( removeStat( arr, 0 ) ) == size_t[2] ) );

    assert( eq( removeStat( arr, 0 ), [1,2] ) );
    assert( eq( removeStat( arr, 1 ), [0,2] ) );
    assert( eq( removeStat( arr, 2 ), [0,1] ) );
}

/++ paste value to static array

 Params:
 arr = array
 K = index to paste
 val = value to paste
 +/
T[N+1] pasteStat(T,size_t N)( in T[N] arr, size_t K, T val ) pure
in { assert( K <= N ); } body
{
    if( K == N ) return to!(T[N+1])( arr ~ val );
    else return to!(T[N+1])( arr[0..K] ~ val ~ arr[K..$] );
}

///
unittest
{
    size_t[3] arr = [ 0, 1, 2 ];
    static assert( is( typeof( pasteStat( arr, 0, 10 ) ) == size_t[4] ) );

    assert( eq( pasteStat( arr, 0, 10 ), [10,0,1,2] ) );
    assert( eq( pasteStat( arr, 1, 10 ), [0,10,1,2] ) );
    assert( eq( pasteStat( arr, 3, 10 ), [0,1,2,10] ) );
}
