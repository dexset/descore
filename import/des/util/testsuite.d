module des.util.testsuite;

import std.traits;
import std.typetuple;
import std.math;

import std.stdio;
import std.string;
import std.exception;
import core.exception : AssertError;

///
template isElemHandler(A)
{
    enum isElemHandler = !is( Unqual!A == void[] ) &&
                          is( typeof(A.init[0]) ) &&
                         !is( Unqual!(typeof(A.init[0])) == void ) &&
                          is( typeof( A.init.length ) == size_t );
}

///
unittest
{
    static assert(  isElemHandler!(int[]) );
    static assert(  isElemHandler!(float[]) );
    static assert(  isElemHandler!(string) );
    static assert( !isElemHandler!int );
    static assert( !isElemHandler!float );
    static assert( !isElemHandler!(immutable(void)[]) );
}

///
bool eq(A,B)( in A a, in B b ) pure
{
    static if( allSatisfy!(isElemHandler,A,B) )
    {
        if( a.length != b.length ) return false;
        foreach( i; 0 .. a.length )
            if( !eq(a[i],b[i]) ) return false;
        return true;
    }
    else static if( ( is( A == class ) || is( A == interface ) ) &&
                    ( is( B == class ) || is( B == interface ) ) )
        return a is b;
    else static if( allSatisfy!(isNumeric,A,B) && anySatisfy!(isFloatingPoint,A,B) )
    {
        static if( isFloatingPoint!A && !isFloatingPoint!B )
            auto epsilon = A.epsilon;
        else static if( isFloatingPoint!B && !isFloatingPoint!A )
            auto epsilon = B.epsilon;
        else
            auto epsilon = fmax( A.epsilon, B.epsilon );
        return abs(a-b) < epsilon;
    }
    else return a == b;
}

///
unittest
{
    assert(  eq( 1, 1.0 ) );
    assert(  eq( "hello", "hello"w ) );
    assert( !eq( cast(void[])"hello", cast(void[])"hello"w ) );
    assert(  eq( cast(void[])"hello", cast(void[])"hello" ) );
    assert(  eq( cast(void[])"hello", "hello" ) );
    assert( !eq( cast(void[])"hello", "hello"w ) );
    assert(  eq( [[1,2],[3,4]], [[1.0f,2],[3.0f,4]] ) );
    assert( !eq( [[1,2],[3,4]], [[1.1f,2],[3.0f,4]] ) );
    assert( !eq( [[1,2],[3,4]], [[1.0f,2],[3.0f]] ) );
    assert(  eq( [1,2,3], [1.0,2,3] ) );
    assert(  eq( [1.0f,2,3], [1.0,2,3] ) );
    assert(  eq( [1,2,3], [1,2,3] ) );
    assert( !eq( [1.0000001,2,3], [1,2,3] ) );
    assert(  eq( ["hello","world"], ["hello","world"] ) );
    assert( !eq( "hello", [1,2,3] ) );
    static assert( !__traits(compiles, eq(["hello"],1)) );
    static assert( !__traits(compiles, eq(["hello"],[1,2,3])) );
}

///
bool eq_approx(A,B,E)( in A a, in B b, in E eps ) pure
    if( allSatisfy!(isNumeric,A,B,E) || allSatisfy!(isElemHandler,A,B) )
{
    static if( allSatisfy!(isElemHandler,A,B) )
    {
        if( a.length != b.length ) return false;
        foreach( i; 0 .. a.length )
            if( !eq_approx(a[i],b[i],eps) ) return false;
        return true;
    }
    else return abs(a-b) < eps;
}

///
unittest
{
    assert(  eq_approx( [1.1f,2,3], [1,2,3], 0.2 ) );
    assert( !eq_approx( [1.1f,2,3], [1,2,3], 0.1 ) );
    assert( !eq_approx( [1.0f,2], [1,2,3], 1 ) );
}

///
bool mustExcept(E=Exception)( void delegate() fnc, bool throwUnexpected=false )
if( is( E : Throwable ) )
in { assert( fnc ); } body
{
    static if( !is( E == Throwable ) )
    {
        try fnc();
        catch( E e ) return true;
        catch( Throwable t )
            if( throwUnexpected ) throw t;
        return false;
    }
    else
    {
        try fnc();
        catch( Throwable t ) return true;
        return false;
    }
}

///
unittest
{
    assert( mustExcept!Exception( { throw new Exception("test"); } ) );
    assert( !mustExcept!Exception( { throw new Throwable("test"); } ) );
    assert( !mustExcept!Exception( { auto a = 4; } ) );
}

import std.conv : to;

string toSF(T)( in T val )
{
    static if( is( typeof( to!string( val ) )) )
        return to!string( val );
    else static if( isArray!T )
    {
        string[] rr;
        foreach( v; val )
            rr ~= toSF( v );
        return "[ " ~ rr.join(", ") ~ " ]";
    }
    else static if( is( T == typeof(null) ) ) return null;
    else static if( is( T == interface ) || is( T == class ) )
    {
        if( val is null ) return "null";
        else return to!string( cast(void*)val );
    }
    else return val.stringof;
}

unittest
{
    assert( eq( toSF([0,4]), "[0, 4]" ) );
    assert( eq( toSF(null), "null" ) );
    assert( eq( toSF(0), "0" ) );

    Object a = null;
    assert( eq( toSF(a), "null" ) );
}

auto throwError(Args...)( string file, size_t line, string fmt, Args args )
{ return new AssertError( format( fmt, args ), file, line ); }

///
void assertEq(A,B,string file=__FILE__,size_t line=__LINE__)( in A a, in B b, lazy string fmt="" )
if( is( typeof( eq(a,b) ) ) )
{
    enforce( eq(a,b), throwError( file, line,
                ( fmt.length ? fmt : "assertEq fails: %s != %s" ),
                toSF(a), toSF(b) ) );
}

///
void assertNotEq(A,B,string file=__FILE__,size_t line=__LINE__)( in A a, in B b, lazy string fmt="" )
if( is( typeof( eq(a,b) ) ) )
{
    enforce( !eq(a,b), throwError( file, line,
                ( fmt.length ? fmt : "assertNotEq fails: %s == %s" ),
                toSF(a), toSF(b) ) );
}

///
void assertNull(A,string file=__FILE__,size_t line=__LINE__)( in A a, lazy string fmt="" )
{
    enforce( a is null, throwError( file, line,
                ( fmt.length ? fmt : "assertNull fails: %s !is null" ),
                toSF(a) ) );
}

///
void assertNotNull(A,string file=__FILE__,size_t line=__LINE__)( in A a, lazy string fmt="" )
{
    enforce( a !is null, throwError( file, line,
                ( fmt.length ? fmt : "assertNotNull fails: %s is null" ),
                toSF(a) ) );
}
