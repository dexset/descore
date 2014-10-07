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

module des.math.basic.traits;

import std.traits;
/* for debug
    static assert( isAssignable!(Unqual!T,Unqual!T) );
    static assert( is( typeof(T.init + T.init) == T ) );
    static assert( is( typeof(T.init - T.init) == T ) );
    static assert( is( typeof( cast(T)(T.init * 0.5) ) ) );
    static assert( is( typeof( cast(T)(T.init / 0.5) ) ) );
 */

bool isComplex(T)()
{
    alias Unqual!T UT;
    return is( UT == cfloat ) ||
           is( UT == cdouble ) ||
           is( UT == creal );
}

bool isImaginary(T)()
{
    alias Unqual!T UT;
    return is( UT == ifloat ) ||
           is( UT == idouble ) ||
           is( UT == ireal );
}

unittest
{
    static assert( isComplex!(typeof(4+3i)) );
    static assert( isImaginary!(typeof(3i)) );
}

@property pure bool hasBasicMathOp(T)()
{
    return isAssignable!(Unqual!T,T) &&
        is( typeof(T.init + T.init) == T ) &&
        is( typeof(T.init - T.init) == T ) &&
        is( typeof( (T.init * 0.5) ) : T ) &&
        is( typeof( (T.init / 0.5) ) : T );
}

unittest
{
    //static assert(  hasBasicMathOp!int );
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
        auto opBinary(string op)( in TTest v ) const if( op=="+" )
        { return TTest(x+v.x,y+v.y); }
    }

    static assert( !hasBasicMathOp!FTest );
}
