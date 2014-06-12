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

module desmath.basic.matharray;

import std.math;
import std.traits;
import std.algorithm;
import std.exception;

import desmath.basic.traits;

struct MathArray(T) if( hasBasicMathOp!T )
{
    T[] data;

    const void check( in MathArray!T b, ptrdiff_t ll=-1 )
    { 
        if( ll < 0 ) enforce( data.length == b.length, "bad length" ); 
        else enforce( b.length == ll, "bad length" ); 
    }

    pure this(this){ data = data.dup; }
    pure this(E)( in E[] b... ) if( is( E : T ) )
    { 
        data.length = b.length;
        foreach( i, ref d; data ) d = b[i];
    }
    pure this(E)( in MathArray!E b ) if( is( E : T ) )
    {
        data.length = b.length;
        foreach( i, ref d; data ) d = b[i];
    }

    pure auto opAssign(E)( in E[] arr )
        if( is( E : T ) )
    {
        data.length = arr.length;
        foreach( i, ref v; data )
            v = arr[i];
        return this;
    }

    pure auto opAssign( in MathArray!T b )
    {
        data = b.data.dup;
        return this;
    }

    pure auto opAssign( ref MathArray!T b )
    {
        data = b.data.dup;
        return this;
    }

    pure auto opAssign(E)( in MathArray!E )
        if( !is( E == T ) && is( E : T ) )
    {
        data.length = b.length;
        foreach( i, ref d; data ) d = b[i];
    }

    @property size_t length() const { return data.length; }
    @property void length( size_t n ) { data.length = n; }

    void setLength( size_t n, in T[] init=[T.init]... )
    {
        auto ll = length;
        data.length = n;
        size_t k = 0;
        for( auto i = ll; i < n; ++i )
            data[i] = init[k++%$];
    }

    ref T opIndex( size_t i ) { return data[i]; }
    ref const(T) opIndex( size_t i ) const { return data[i]; }

    size_t opDollar(size_t p)() const { return length; }

    auto opSlice() const { return MathArray!T(this); }

    auto opSlice( size_t i, size_t j ) const
    {
        MathArray!T ret;
        ret.length = j - i;
        for( auto k=i,m=0; k < j; ++k, ++m )
            ret[m] = data[k];
        return ret;
    }

    auto opSliceAssign(E)( in E b, size_t i, size_t j )
        if( is( E : T ) )
    {
        for( auto k=i; k<j; ++k )
            data[k] = b;
        return this[i .. j];
    }

    auto opSliceAssign(E)( in MathArray!E b, size_t i, size_t j )
        if( is( E : T ) )
    {
        check( b, j-i );
        for( auto k=i, n=0; k<j; ++k,++n )
            data[k] = b[n];
        return this[i .. j];
    }

    auto opSliceOpAssign(string op, E)( in E b, size_t i, size_t j )
        if( is( E : T ) )
    {
        for( auto k=i; k<j; ++k )
            mixin( "data[k] " ~ op ~ "= b;" );
        return this[i .. j];
    }

    auto opSliceOpAssign(string op, E)( in MathArray!E b, size_t i, size_t j )
        if( is( E : T ) )
    {
        check( b, j-i );
        for( auto k=i, n=0; k<j; ++k,++n )
            mixin( "data[k] " ~ op ~ "= b[n];" );
        return this[i .. j];
    }

    auto opUnary(string op)() const if( op == "-" )
    {
        auto ret = MathArray!T(this);
        foreach( ref v; ret.data ) v = -v;
        return ret;
    }

    auto opBinary(string op,E)( in MathArray!E b ) const
        if( is( E : T ) && op == "~" )
    {
        auto ret = MathArray!T(this);
        foreach( v; b.data )
            ret.data ~= cast(T)v;
        return ret;
    }

    auto opBinary(string op,E)( in E[] b ) const
        if( is( E : T ) && op == "~" )
    {
        auto ret = MathArray!T(this);
        foreach( v; b )
            ret.data ~= cast(T)v;
        return ret;
    }

    auto opBinary(string op,E)( in MathArray!E b ) const
        if( is( E : T ) && ( op == "+" || op == "-" || op == "/" || op == "*" ) )
    {
        check( b );
        MathArray!T ret;
        ret.length = length;
        foreach( i, ref v; ret.data )
            mixin( "v = cast(T)( data[i] " ~ op ~ " b[i] );" );
        return ret;
    }

    auto opBinary(string op,E)( in E b ) const
        if( isNumeric!E && ( op == "*" || op == "/" ) )
    {
        MathArray!T ret;
        ret.length = length;
        foreach( i, ref v; ret.data )
            mixin( "v = cast(T)( data[i] " ~ op ~ " b );" );
        return ret;
    }
    
    auto opOpAssign(string op,E)( in E[] b )
        if( is( E : T ) && op == "~" )
    { this = this ~ b; return this; }

    auto opOpAssign(string op,E)( in E b )
        if( is( E : T ) && ( op == "/" || op == "*" ) )
    { mixin( "this = this " ~ op ~ " b;" ); return this; }

    auto opOpAssign(string op,E)( in MathArray!E b )
        if( is( E : T ) && ( op == "+" || op == "-" || op == "/" || op == "*" || op == "~" ) )
    { mixin( "this = this " ~ op ~ " b;" ); return this; }

    @property auto to(E)() const
    {
        E[] ret;
        ret.length = length;
        foreach( i, ref v; ret )
            v = cast(E)data[i];
        return ret;
    }

    static if( isNumeric!T )
    {
        auto opBinary(string op,E)( in MathArray!E b ) const
            if( is( E : T ) && op == "^" )
        {
            check( b );
            T ret = 0;
            foreach( i, v; data )
                ret += v * b[i];
            return ret;
        }

        @property auto len2() const { return this ^ this; }
        @property auto len(E=float)() const if( isFloatingPoint!E )
        { return sqrt( cast(E)(len2) ); }
    }
}

unittest
{
    alias MathArray!float T;

    static assert( isAssignable!(Unqual!T,Unqual!T) );
    static assert( is( typeof(T.init + T.init) == T ) );
    static assert( is( typeof(T.init - T.init) == T ) );
    static assert( is( typeof( cast(T)(T.init * 0.5) ) ) );
    static assert( is( typeof( cast(T)(T.init / 0.5) ) ) );

    static assert( hasBasicMathOp!( MathArray!float ) );
}

//unittest
//{
//    alias MathArray!int T;
//
//    static assert( isAssignable!(Unqual!T,Unqual!T) );
//    static assert( is( typeof(T.init + T.init) == T ) );
//    static assert( is( typeof(T.init - T.init) == T ) );
//    static assert( is( typeof( cast(T)(T.init * 0.5) ) ) );
//    static assert( is( typeof( cast(T)(T.init / 0.5) ) ) );
//
//    static assert( hasBasicMathOp!( MathArray!int ) );
//}

unittest
{
    import desmath.linear.vector;
    static assert( hasBasicMathOp!( MathArray!dvec3 ) );
}

version(unittest)
{
    private
    {
        import std.string;
        alias MathArray!float dynvec;
        alias MathArray!double ddynvec;
        //alias MathArray!int idynvec;
    }
}

unittest
{
    dynvec a;
    assert( a.length == 0 );
    a = dynvec( 3, 1, 4, 5 );
    assert( a.length == 4 );
    auto b = a;
    assert( a == b );
    a[0] = 5;
    assert( a != b );
    //auto c = idynvec( a.to!int );
    //assert( c[0] == a[0] );
}

unittest
{
    auto ai = immutable(dynvec)( 3, 5, 6 );
    auto ac = const(dynvec)( 7, 3, 2 );
    auto ai_c = const(dynvec)( ai );
    auto ac_i = immutable(dynvec)( ac );
    auto bi = dynvec(ai);
    auto bc = dynvec(ac);
    assert( ai == bi );
    assert( ac == bc );
    bi[0] = 10;
    auto c = bi + ac;
    assert( is( typeof(c) == dynvec ) );
    assert( c.length == 3 );
    assert( c.data == [ 17, 8, 8 ], format("%s != %s", c.data, [17,8,8] ) );

    bi.length = 4;
    assert( bi.data[0 .. 3] == [ 10, 5, 6 ] );
    assert( bi.data[3] != bi.data[3] );

    bi.setLength( 5, 1 );
    assert( bi.data[0 .. 3] == [ 10, 5, 6 ] );
    assert( bi.data[3] != bi.data[3] );
    assert( bi.data[4] == 1 );

    bi.setLength( 3, 1 );
    assert( bi.data == [ 10, 5, 6 ], format("%s != %s", bi.data, [10,5,6] ) );

    bi.setLength( 4 );
    assert( bi.data[0 .. 3] == [ 10, 5, 6 ] );
    assert( bi.data[3] != bi.data[3] );

    bi.length = 3;
    bi = -bi;
    assert( bi.data == [ -10, -5, -6 ] );
}

unittest
{
    auto a = dynvec( 4, 3, 2 );
    auto b = dynvec( 2, 3, 1 );

    assert( (a^b) == (8 + 9 + 2) );
    a = [ 3, 4 ];
    assert( a.data == [ 3, 4 ], format( "%s != %s", a.data, [3,4] ) );
    assert( a.len == 5, format( "%s != 5", a.len ) );

    bool except = false;
    try auto c = a + b;
    catch( Throwable t )
        except = true;
    assert( except, "no throw exception if bad length" );

    a.setLength( 5, 2, 1 );
    assert( a.data == [3,4,2,1,2], format("%s != %s", a.data,[3,4,2,1,2]) );

    auto c = a[1 .. 4];
    assert( is( typeof(c) == dynvec ) );
    assert( c.length == 3 );
    assert( c.data == [4,2,1] );

    a[1 .. 4] = 0;
    assert( a.data == [3,0,0,0,2] );

    a[2] = 1;
    a = a[1 .. 3] ~ a[4 .. $] ~ [ 1, 2, 3 ];
    assert( a.data == [0,1,2,1,2,3], format( "%s", a.data ) );

}

unittest
{
    auto a = dynvec( 1,2,3 );
    auto b = dynvec( 5,1,4 );
    a += b;
    assert( a.data == [ 6, 3, 7 ] );
    a ~= b;
    assert( a.data == [ 6, 3, 7, 5, 1, 4 ] );
    a *= 2.0;
    assert( a.data == [ 12, 6, 14, 10, 2, 8 ] );

    a.length = 3;
    int[2] ii = [ 4, 5 ];
    a ~= ii;
    assert( a.data == [12,6,14,4,5] );

    auto c = a[1 .. 3] /= 2;
    assert( c.data == [ 3, 7 ] );
    assert( a.data == [12,3,7,4,5] );

    a.setLength(6,0);
    assert( a.opDollar!0 == 6 );
    auto d = a[3 .. $];
    auto e = a[0 .. 3];
    assert( e.length == 3 );
    assert( d.length == 3 );
    a[0 .. 3] = a[3 .. $];
    assert( a.data == [4,5,0,4,5,0] );
}

unittest
{
    auto a = dynvec( 0,0,0,1,2,3 );
    a[0 .. 3] += a[3 .. $] * 2;
    assert( a.data == [ 2,4,6,1,2,3 ] );
}

unittest
{
    import desmath.linear.vector;
    alias MathArray!dvec3 ddvec3;
    auto a = ddvec3( dvec3(0,1,2), dvec3(2,3,4) );
    a[0] += a[1];
    assert( a.data == [ dvec3(2,4,6), dvec3(2,3,4) ] );
}
