module des.math.basic.traits;

import std.traits;
/* for debug
    static assert( isAssignable!(Unqual!T,Unqual!T) );
    static assert( is( typeof(T.init + T.init) == T ) );
    static assert( is( typeof(T.init - T.init) == T ) );
    static assert( is( typeof( cast(T)(T.init * 0.5) ) ) );
    static assert( is( typeof( cast(T)(T.init / 0.5) ) ) );
 */

///
template isComplex(T)
{
    alias Unqual!T UT;
    enum isComplex = is( UT == cfloat ) ||
                     is( UT == cdouble ) ||
                     is( UT == creal );
}

///
template isImaginary(T)
{
    alias Unqual!T UT;
    enum isImaginary = is( UT == ifloat ) ||
                       is( UT == idouble ) ||
                       is( UT == ireal );
}

unittest
{
    static assert( isComplex!(typeof(4+3i)) );
    static assert( isImaginary!(typeof(3i)) );
}

///
template hasBasicMathOp(T)
{
    enum hasBasicMathOp =
        isAssignable!(Unqual!T,T) &&
        is( typeof(T.init + T.init) == T ) &&
        is( typeof(T.init - T.init) == T ) &&
        is( typeof( (T.init * 0.5) ) : T ) &&
        is( typeof( (T.init / 0.5) ) : T );
}

///
unittest
{
    static assert( !hasBasicMathOp!int );
    static assert(  hasBasicMathOp!float );
    static assert(  hasBasicMathOp!double );
    static assert(  hasBasicMathOp!real );
    static assert(  hasBasicMathOp!cfloat );
    static assert( !hasBasicMathOp!char );
    static assert( !hasBasicMathOp!string );

    struct TTest
    {
        float x,y;
        auto opBinary(string op)( in TTest v ) const 
            if( op=="+" || op=="-" )
        { return TTest(x+v.x,y+v.y); }
        auto opBinary(string op)( double v ) const 
            if( op=="*" || op=="/" )
        { return TTest(x*v,y*v); }
    }

    static assert(  hasBasicMathOp!TTest );

    struct FTest
    {
        float x,y;
        auto opAdd( in TTest v ) const { return TTest(x+v.x,y+v.y); }
    }

    static assert( !hasBasicMathOp!FTest );
}
