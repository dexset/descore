module desutil.testsuite;

import std.traits;
import std.math;

bool isLikeArray(A)()
{ return is( typeof( A.init[0] ) ) && is( typeof( A.init.length ) == size_t ); }

bool eq(A,B)( in A a, in B b )
    if( is(typeof(A.init!=B.init)) && !isLikeArray!A && !isLikeArray!B )
{
    static if( isFloatingPoint!A || isFloatingPoint!B )
    {
        static if( isFloatingPoint!A && !isFloatingPoint!B )
            auto epsilon = A.epsilon;
        else static if( isFloatingPoint!B && !isFloatingPoint!A )
            auto epsilon = B.epsilon;
        else
            auto epsilon = fmax( A.epsilon, B.epsilon );
        if( abs( a - b ) > epsilon ) return false;
    }
    else
    {
        if( a != b ) return false;
    }
    return true;
}

unittest
{
    assert( eq(1,1.0) );
    assert( eq("hello","hello"w) );
}

bool eq(A,B)( in A a, in B b )
    if( isLikeArray!A && isLikeArray!B && is(typeof(A.init[0]!=B.init[0])) )
{
    static if( is(Unqual!A == void[] ) )
        return a == b; 
    else
    {
        if( a.length != b.length ) return false;
        foreach( i; 0 .. a.length )
            if( !eq(a[i],b[i]) ) return false;
        return true;
    }
}

unittest
{
    assert( eq( [1,2,3], [1.0,2,3] ) );
    assert( eq( [1.0f,2,3], [1.0,2,3] ) );
    assert( eq( [1,2,3], [1,2,3] ) );
    assert( !eq( [1.0000001,2,3], [1,2,3] ) );
    assert( eq( ["hello","world"], ["hello","world"] ) );
    static assert( !__traits(compiles, eq(["hello"],1)) );
}

bool eq_approx(A,B,E)( in A a, in B b, in E eps )
    if( isLikeArray!A && isLikeArray!B && 
        is(typeof(-E.init)) &&
        is(typeof( (A.init[0]-B.init[0]) < eps )) )
{
    if( a.length != b.length ) return false;
    foreach( i; 0 .. a.length )
        if( !eq_approx(a[i],b[i],eps) ) return false;
    return true;
}

bool eq_approx(A,B,E)( in A a, in B b, in E eps )
    if( is(typeof( (A.init-B.init) < eps )) )
{ return (a-b < eps) && (a-b > -eps); }

bool mustExcept(E=Exception)( void delegate() fnc, bool throwUnexpected=false )
if( is( E : Throwable ) )
in { assert( fnc ); } body
{
    try fnc();
    catch( E e ) return true;
    catch( Throwable t )
        if( throwUnexpected ) throw t;
    return false;
}

unittest
{
    assert( mustExcept!Exception( { throw new Exception("test"); } ) );
    assert( !mustExcept!Exception( { throw new Throwable("test"); } ) );
    assert( !mustExcept!Exception( { auto a = 4; } ) );
}
