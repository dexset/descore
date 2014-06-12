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

module desmath.basic.traits;

import std.traits;
/* for debug
    static assert( isAssignable!(Unqual!T,Unqual!T) );
    static assert( is( typeof(T.init + T.init) == T ) );
    static assert( is( typeof(T.init - T.init) == T ) );
    static assert( is( typeof( cast(T)(T.init * 0.5) ) ) );
    static assert( is( typeof( cast(T)(T.init / 0.5) ) ) );
 */

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

import std.string;
import std.array;

private
{
    bool isTrueFieldsStr( string str )
    {
        bool checkFields( string[] fields )
        {
            foreach( field; fields )
            {
                foreach( i, c; field )
                    switch( c )
                    {
                        case 'a': .. case 'z':
                        case 'A': .. case 'Z': 
                        case '_': 
                                  break;
                        case '0': .. case '9':
                            if( i ) break;
                            else goto default;
                        case '.':
                            if( i && i != field.length-1 && 
                                    checkFields( split(field,".") ) ) break;
                            else goto default;
                        default:
                            return false;
                    }
            }
            return true;
        }

        return checkFields( split( str ) ) ;
    }

    unittest
    {
        auto fstr = "pos.x pos.y vel.x vel.y";
        assert( split( fstr ) == [ "pos.x", "pos.y", "vel.x", "vel.y" ] );

        assert(  isTrueFieldsStr( "pos vel" ) );
        assert(  isTrueFieldsStr( "abcd" ) );
        assert(  isTrueFieldsStr( "a1 a2" ) );
        assert(  isTrueFieldsStr( "ok.no" ) );
        assert(  isTrueFieldsStr( fstr ) );
        assert( !isTrueFieldsStr( fstr[0 .. $-1] ) );
        assert( !isTrueFieldsStr( "ok.1" ) );
        assert( !isTrueFieldsStr( "1abcd" ) );
        assert( !isTrueFieldsStr( "not 2ok" ) );
    }

    string opSelf( string[] fields, string op, string b="b" )
    {
        string[] rb;
        foreach( f; fields )
            rb ~= format( "%1$s %2$s %3$s.%1$s", f, op, b );
        return rb.join(", ");
    }

    unittest
    {
        assert( opSelf( "pnt rot".split, "+", "vv" ), "pnt + vv.pnt, rot + vv.rot" );
        assert( opSelf( "a b c".split, "*", "x" ), "a * x.a, b * x.b, c * x.c" );
    }

    string opEach( string[] fields, string op, string b="b" )
    {
        string[] rb;
        foreach( f; fields )
            rb ~= format( "cast(typeof(%1$s))(%1$s %2$s %3$s)", f, op, b );
        return rb.join(",");
    }

    unittest
    {
        assert( opEach( "pnt rot".split, "+", "vv" ), "pnt + vv, rot + vv" );
        assert( opEach( "a b c".split, "*", "x" ), "cast(typeof(a))(a * x), cast(typeof(b))(b * x), cast(typeof(c))(c * x)" );
    }

    string argName( string f )
    {
        return format( "arg_%s", f.split(".").join("_") );
    }

    unittest
    {
        assert( argName( "pos" ) == "arg_pos" );
        assert( argName( "Pos" ) == "arg_Pos" );
        assert( argName( "Pos.x" ) == "arg_Pos_x" );
        assert( argName( "P.s.x" ) == "arg_P_s_x" );
    }

    string basicMathCtor( string[] fields, string name )
    {
        string args[];
        string cbody = "auto ret = cast(self)(this); ";
        foreach( field; fields )
        {
            auto arg = argName( field );
            args ~= format( "in typeof(%s) %s", field, arg );
            cbody ~= format( "ret.%1$s = %2$s; ", field, arg );
        }
        cbody ~= "return ret;";
        return format( "self %s( %s ) const { %s }", name, args.join(", "), cbody );
    }

    unittest
    {
        assert( basicMathCtor( ["p", "v"], "b" ) ==
        "self b( in typeof(p) arg_p, in typeof(v) arg_v ) const { auto ret = cast(self)(this); ret.p = arg_p; ret.v = arg_v; return ret; }" );
    }

    string staticAsserts( string[] fields )
    {
        string ret;
        foreach( f; fields )
            ret ~= format("static assert( hasBasicMathOp!(typeof(%1$s)), \"member (%1$s) has not basic math ops\" );", f );
        return ret;
    }
}


@property string BasicMathOp( string fields_str )()
    if( isTrueFieldsStr( fields_str ) )
{
    auto fields = split( fields_str );
    string bmctor = "__basic_math_ctor";
    return format(`
    import std.traits;
    alias Unqual!(typeof(this)) self;

    %1$s
    %2$s
    `, 
        basicMathCtor( fields, bmctor ),
        staticAsserts( fields )
    ) ~ format(`

    auto opAdd( in self b ) const { return %1$s( %2$s ); }
    auto opSub( in self b ) const { return %1$s( %3$s ); }
    auto opMul( double b ) const { return %1$s( %4$s ); }
    auto opDiv( double b ) const { return %1$s( %5$s ); }

    auto opOpAssign(string op)( in self b )
    { mixin( "return this = this " ~ op ~ " b;" ); }

    auto opOpAssign(string op)( double b )
    { mixin( "return this = this " ~ op ~ " b;" ); }
    `,
        bmctor,
        opSelf( fields, "+" ),
        opSelf( fields, "-" ),
        opEach( fields, "*" ),
        opEach( fields, "/" )
    );
}

unittest
{
    static struct Val
    {
        float v1 = 0;
        double v2 = 0;
        mixin( BasicMathOp!"v1 v2" );
    }

    static assert( isAssignable!(Unqual!Val,Unqual!Val) );
    static assert( is( typeof(Val.init + Val.init) == Val ) );
    static assert( is( typeof(Val.init - Val.init) == Val ) );
    static assert( is( typeof( cast(Val)(Val.init * 0.5) ) ) );
    static assert( is( typeof( cast(Val)(Val.init / 0.5) ) ) );

    static assert( hasBasicMathOp!Val );

    auto p1 = Val( 1, 2 );
    auto p2 = Val( 2, 3 );

    assert( p1 + p2 == Val(3,5) );
    assert( p2 - p1 == Val(1,1) );
    assert( p1 * 3 == Val(3,6) );
    assert( p1 / 2 == Val(0.5,1) );

    static struct Comp
    {
        string str;
        float val; 
        float time = 0;
        mixin( BasicMathOp!"val" );
    }

    static assert( hasBasicMathOp!Comp );

    auto c1 = Comp( "ololo", 10, 1.3 );
    auto c2 = Comp( "valav", 5, .8 );

    assert( c1 + c2 == Comp("ololo", 15, 1.3) );
}

unittest
{
    static struct Val
    {
        float v1 = 0;
        double v2 = 0;
        mixin( BasicMathOp!"v1 v2" );
    }

    auto p1 = Val( 1, 2 );
    auto p2 = Val( 2, 3 );

    auto p3 = p1 + p2;
    p1 += p2;
    assert( p1 == p3 );
}

unittest
{
    static struct Vec
    {
        double x = 0, y = 0;
        mixin( BasicMathOp!"x y" );
    }

    static assert( hasBasicMathOp!Vec );

    static struct Point
    {
        Vec pos, vel;
        this( in Vec p, in Vec v )
        {
            pos = p;
            vel = v;
        }
        mixin( BasicMathOp!"pos vel" );
    }

    static assert( hasBasicMathOp!Vec );
}

unittest
{
    import desmath.linear.vector;
    static assert( hasBasicMathOp!dvec3 );
    static assert( hasBasicMathOp!vec3 );

    static struct Point 
    { 
        vec3 pos, vel; 
        mixin( BasicMathOp!"pos vel" );
    }

    static assert( hasBasicMathOp!Point );
}

unittest
{
    static struct Vec { double x=0, y=0; }
    static assert( !hasBasicMathOp!Vec );
    static struct Point 
    { 
        Vec pos, vel; 
        string str;
        float val;
        mixin( BasicMathOp!"pos.x pos.y vel.x vel.y val" ); 
    }
    static assert( hasBasicMathOp!Point );
    auto a = Point( Vec(1,2), Vec(2,3), "hello", 3 );
    assert( a + a == Point( Vec(2,4), Vec(4,6), "hello", 6 ) );
    assert( a * 2 == Point( Vec(2,4), Vec(4,6), "hello", 6 ) );
}
