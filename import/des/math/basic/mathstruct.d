module des.math.basic.mathstruct;

import std.string;
import std.array;
import std.traits;

import des.math.util;
import des.math.basic.traits;

private enum SEP = " ";

@property string BasicMathOp( string fields_str )()
    if( isArrayAccessString( fields_str, SEP, true ) )
{
    auto fields = fields_str.split(SEP);
    string bmctorname = "__basic_math_ctor";
    return format(`
    import std.traits;
    alias Unqual!(typeof(this)) self;

    %1$s
    %2$s
    `,
        basicMathCtor( fields, bmctorname ),
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
        bmctorname,
        opSelf( fields, "+" ),
        opSelf( fields, "-" ),
        opEach( fields, "*" ),
        opEach( fields, "/" )
    );
}

private
{
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
            rb ~= format( "%1$s %2$s %3$s", f, op, b );
        return rb.join(",");
    }

    unittest
    {
        assert( opEach( "pnt rot".split, "+", "vv" ), "pnt + vv, rot + vv" );
        assert( opEach( "a b c".split, "*", "x" ), "a * x, b * x, c * x" );
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
            ret ~= format(`static assert( hasBasicMathOp!(typeof(%1$s)), "member '%1$s' hasn't basic math ops" );`, f );
        return ret;
    }
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
    import des.math.linear.vector;
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
