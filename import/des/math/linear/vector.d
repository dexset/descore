/+
 + License:
 + The MIT License (MIT)
 + 
 +     Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>
 + 
 +     Permission is hereby granted, free of charge, to any person obtaining a copy
 +     of this software and associated documentation files (the "Software"), to deal
 +     in the Software without restriction, including without limitation the rights
 +     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 +     copies of the Software, and to permit persons to whom the Software is
 +     furnished to do so, subject to the following conditions:
 + 
 +     The above copyright notice and this permission notice shall be included in
 +     all copies or substantial portions of the Software.
 + 
 +     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 +     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 +     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 +     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 +     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 +     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 +     THE SOFTWARE.
 +/

/++
    Provides work with vector and some aliases and functions.
+/

module des.math.linear.vector;

import std.math;
import std.algorithm;
import std.array;
import std.traits;
import std.exception;
import std.string;

import des.util.testsuite;

import des.math.util;

version(unittest) import std.stdio;

///Checks, if type is vector
template isVector(E)
{
    enum isVector = is( typeof(impl(E.init)) );
    void impl(size_t N,T,alias string AS)( in Vector!(N,T,AS) ) {}
}

///Checks, if type is static vector
template isStaticVector(E)
{
    static if( !isVector!E )
        enum isStaticVector = false;
    else enum isStaticVector = E.isStatic;
}

///Checks, if type is dynamic vector
template isDynamicVector(E)
{
    static if( !isVector!E )
        enum isDynamicVector = false;
    else enum isDynamicVector = E.isDynamic;
}

unittest
{
    static assert( !isStaticVector!float );
    static assert( !isDynamicVector!float );
}

///Checks, if N(dims) and T(type) is compatible to vector E
template isCompatibleVector(size_t N,T,E)
{
    static if( !isVector!E )
        enum isCompatibleVector = false;
    else enum isCompatibleVector = E.dims == N && is( E.datatype : T );
}

bool isValidOp(string op,T,E,K=T)() pure
{ mixin( `return is( typeof( T.init ` ~ op ~ ` E.init ) : K );` ); }

bool hasCompMltAndSum(T,E)() pure
{ return is( typeof( T(T.init * E.init) ) ) && is( typeof( T.init + T.init ) == T ); }

private enum SEP1 = " ";
private enum SEP2 = "|";

pure @property string spaceSep(string str) { return str.split("").join(SEP1); }

private @property string zerosVectorData(size_t N)()
{
    string[] ret;
    foreach( j; 0 .. N )
        ret ~= format( "%d", 0 );
    return "[" ~ ret.join(",") ~ "]";
}

/++
Params:
    N   = Number of dimmensions. 
          Vector can be dynamic (`N==0`) or static (`N>0`).
    T   = Vector data type.
    AS  = Access string.
          Must be valid access string with space or '|' separator or must be an empty string.

          One can assess static vector data by names:
          ---
          alias Vector!(4,float,"x y Vx Vy") Phase;
          auto a = Phase( 1,2,3,4 );
          a.x = 10;
          a.Vy = 12;
          ---
          $(BIG See Also:) opDispatch
+/
struct Vector( size_t N, T, alias string AS="")
    if( isCompatibleArrayAccessStrings(N,AS,SEP1,SEP2) || AS.length == 0 )
{
    enum isDynamic = N == 0;
    enum isStatic = N != 0;
    enum dims = N;

    static if( isStatic ) 
    {
        static if( isNumeric!T )
            T[N] data = mixin( zerosVectorData!N );
        else
            T[N] data;
    }
    else T[] data;

    alias data this;

    alias T datatype;
    alias AS access_string;
    alias Vector!(N,T,AS) selftype;

pure:

    static if( isDynamic )
    {
        /++
            Length of elements. 
            Enum, if vector is static.
         +/
        pure @property auto length() const { return data.length; }

        ///ditto
        pure @property auto length( size_t nl )
        {
            data.length = nl;
            return data.length;
        }
    }
    else enum length = N;

    /++
        Vector can be constructed with different ways:

        $(LI from single values)
        $(LI from arrays)
        $(LI from other vectors)
        This ways can be combined:
        ---
            alias Vector!(8,float) MegaVector;

            auto v2 = vec2(1,2);
            auto v3 = vec3(3,4,5);

            auto a = MegaVector( 0, v2, v3, [6,7] );
            assert( eq( a, [0,1,2,3,4,5,6,7] ) );
        ---
        And static vector can be constructed from one value:
        ---
            auto a = vec4(1);
            assert( eq( a, [1,1,1,1] ) );
        ---
     +/
    this(E...)( in E vals )
    {
        // not work with dynamic vectors
        static assert( is(typeof(flatData!T(vals))), "args not compatible" );

        static if( isStatic )
        {
            static if( hasNoDynamic!E && E.length > 1 )
            {
                static assert( getElemCount!E == N * getElemCount!T, "wrong args count" );
                static assert( isConvertable!(T,E), "wrong args type" );
                mixin( vectorStaticFill!("T","data","vals",T,E) );
            }
            else
            {
                auto buf = flatData!T(vals);

                if( buf.length == length )
                    data[] = buf[];
                else if( buf.length == 1 )
                    data[] = buf[0];
                else enforce( false, "bad args length" );
            }
        }
        else data = flatData!T(vals);
    }

    static if( isDynamic ) this(this) { data = this.data.dup; }

    /++
      Any binary operations that allowed from type of element allowed
      from vector and exec per element:

      ---
      auto a = vec3(1,2,3);
      auto b = vec3(2,3,4);
      auto c = a + b; // [3,5,7]
      auto d = a * b; // [2,6,12]
      auto e = a * 3; // [3,6,9]
      a *= 2;
      a /= 0.5;
      auto f = b ^^ 2; // [4,9,16]
      ---
     +/
    auto opAssign( size_t K, E, alias string oas )( in Vector!(K,E,oas) b )
        if( (K==N||K==0||N==0) && is( typeof(T(E.init)) ) )
    {
        static if( isDynamic ) length = b.length;
        foreach( i; 0 .. length ) data[i] = T(b[i]);
        return this;
    }

    ///ditto
    auto opUnary(string op)() const
        if( op == "-" && is( typeof( T.init * (-1) ) : T ) )
    {
        selftype ret;
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            ret[i] = this[i] * -1;
        return ret;
    }

    ///ditto
    auto opBinary(string op, size_t K, E, alias string oas )
        ( in Vector!(K,E,oas) b ) const
        if( isValidOp!(op,T,E) && (K==N||K==0||N==0) )
    {
        selftype ret;
        static if( isDynamic || b.isDynamic )
            enforce( length == b.length, "wrong length" );
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            mixin( `ret[i] = this[i] ` ~ op ~ ` b[i];` );
        return ret;
    }

    ///ditto
    auto opBinary(string op, E)( in E b ) const
        if( isValidOp!(op,T,E) && op != "+" && op != "-" )
    {
        selftype ret;
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            mixin( `ret[i] = this[i] ` ~ op ~ ` b;` );
        return ret;
    }

    ///ditto
    auto opOpAssign(string op, E)( in E b )
        if( mixin( `is( typeof( this ` ~ op ~ ` b ) )` ) )
    { mixin( `return this = this ` ~ op ~ ` b;` ); }

    ///ditto
    auto opBinaryRight(string op, E)( in E b ) const
        if( isValidOp!(op,E,T,T) && op == "*" )
    { mixin( "return this " ~ op ~ " b;" ); }

    /// Checks, if all elements is finite
    bool opCast(E)() const if( is( E == bool ) )
    { return all!isFinite( data.dup ); }

    const @property
    {
        static if( is( typeof( dot(selftype.init,selftype.init) ) ) )
        {
            /++
                Square of euclidean length of the vector.

                Available only if( is( typeof( dot(selftype.init,selftype.init) ) ) )
            +/
            auto len2() { return dot(this,this); }

            static if( is( typeof( sqrt(CommonType!(T,float)(this.len2)) ) ) )
            {
                /++
                    Euclidean length of the vector

                    Available if( is( typeof( sqrt(CommonType!(T,float)(this.len2)) ) ) )
                +/
                auto len(E=CommonType!(T,float))() { return sqrt( E(len2) ); }
            }

            static if( is( typeof( this / len ) == typeof(this) ) )
            {
                /++ Unit length of the vector

                    Available if( is( typeof( this / len ) == typeof(this) ) )
                +/
                auto e() { return this / len; }
            }
        }
    }

    static if( N == 2 )
    {
        /++
            Convert static vector to new coordinate system.

            Available only if( N == 2 || N == 3 )

            Example:
            For N == 2
            ---
                auto a = vec2(1,1);
                auto nx = vec2(2,0);
                auto ny = vec2(0,2);
                auto b = a.rebase(nx,ny);
                assert( eq( b, [0.5,0.5] ) );
            ---
            For N == 3
            ---
                auto a = vec3(1,1,1);
                auto nx = vec3(2,0,0);
                auto ny = vec3(0,2,0);
                auto nz = vec3(0,0,2);
                auto b = a.rebase(nx,ny,nz);
                assert( eq( b, [0.5,0.5,0.5] ) );
            ---
         +/
        auto rebase(I,J)( in I x, in J y ) const
            if( isCompatibleVector!(2,T,I) &&
                isCompatibleVector!(2,T,J) )
        {
            alias this m;

            auto  d = x[0] * y[1] - y[0] * x[1];
            auto rx = m[0] * y[1] - y[0] * m[1];
            auto ry = x[0] * m[1] - m[0] * x[1];

            return selftype( rx/d, ry/d );
        }
    }

    static if( N == 3 )
    {
        ///ditto
        auto rebase(I,J,K)( in I x, in J y, in K z ) const
            if( isCompatibleVector!(3,T,I) &&
                isCompatibleVector!(3,T,J) &&
                isCompatibleVector!(3,T,K) )
        {
            alias this m;

            auto a1 =  (y[1] * z[2] - z[1] * y[2]);
            auto a2 = -(x[1] * z[2] - z[1] * x[2]);
            auto a3 =  (x[1] * y[2] - y[1] * x[2]);

            auto x2 = -(m[1] * z[2] - z[1] * m[2]);
            auto x3 =  (m[1] * y[2] - y[1] * m[2]);

            auto y1 =  (m[1] * z[2] - z[1] * m[2]);
            auto y3 =  (x[1] * m[2] - m[1] * x[2]);

            auto z1 =  (y[1] * m[2] - m[1] * y[2]);
            auto z2 = -(x[1] * m[2] - m[1] * x[2]);

            auto ad1 = x[0] * a1;
            auto ad2 = y[0] * a2;
            auto ad3 = z[0] * a3;

            auto d  = x[0] * a1 + y[0] * a2 + z[0] * a3;

            auto nxd = m[0] * a1 + y[0] * x2 + z[0] * x3;
            auto nyd = x[0] * y1 + m[0] * a2 + z[0] * y3;
            auto nzd = x[0] * z1 + y[0] * z2 + m[0] * a3;

            return selftype( nxd/d, nyd/d, nzd/d );
        }
    }

    static if( AS.length > 0 )
    {
        @property
        {
            /++
                Get/set element data by access string.

                Available if( AS.length > 0 )
            +/
            ref T opDispatch(string v)()
                if( getIndex(AS,v,SEP1,SEP2) != -1 )
            { mixin( format( "return data[%d];", getIndex(AS,v,SEP1,SEP2) ) ); }

            ///ditto
            T opDispatch(string v)() const
                if( getIndex(AS,v,SEP1,SEP2) != -1 )
            { mixin( format( "return data[%d];", getIndex(AS,v,SEP1,SEP2) ) ); }

            static if( isOneSymbolPerFieldForAnyAccessString(AS,SEP1,SEP2) )
            {
                /++
                    Get/set vector by access string.

                    Available if( AS.length > 0 && isOneSymbolPerFieldForAnyAccessString(AS,SEP1,SEP2) )
                    Example:
                    ---
                        auto a = Vector!(3,float,"x y z")(1,2,3);
                        auto b = a.zy; // equals vec2( a.z, a.y );

                        a.xz = a.yx; // a == [ 2, 2, 1 ]
                    ---
                +/
                auto opDispatch(string v)() const
                    if( v.length > 1 && oneOfAnyAccessAll(AS,v,SEP1,SEP2) )
                {
                    mixin( format( `return Vector!(v.length,T,"%s")(%s);`,
                                isCompatibleArrayAccessString(v.length,v)?v.split("").join(SEP1):"",
                                array( map!(a=>format( `data[%d]`,getIndex(AS,a,SEP1,SEP2)))(v.split("")) ).join(",")
                                ));
                }

                ///ditto
                auto opDispatch( string v, U )( in U b )
                    if( v.length > 1 && oneOfAnyAccessAll(AS,v,SEP1,SEP2) && isCompatibleArrayAccessString(v.length,v) &&
                            ( isCompatibleVector!(v.length,T,U) || ( isDynamicVector!U && is(typeof(T(U.datatype.init))) ) ) )
                {
                    static if( b.isDynamic ) enforce( v.length == b.length );
                    foreach( i; 0 .. v.length )
                        data[getIndex(AS,""~v[i],SEP1,SEP2)] = T( b[i] );
                    return opDispatch!v;
                }
            }
        }
    }
}

///Dot multiplication for compaitable vectors.
auto dot( size_t N, size_t K, T,E, alias string S1, alias string S2 )( in Vector!(N,T,S1) a, in Vector!(K,E,S2) b )
    if( (N==K||K==0||N==0) && hasCompMltAndSum!(T,E) )
{
    static if( a.isDynamic || b.isDynamic )
    {
        enforce( a.length == b.length, "wrong length" );
        enforce( a.length > 0, "zero length" );
    }
    T ret = a[0] * b[0];
    foreach( i; 1 .. a.length )
        ret = ret + T( a[i] * b[i] );
    return ret;
}

///Cross multiplication for compaitable vectors.
auto cross( size_t N, size_t K, T,E, alias string S1, alias string S2 )( in Vector!(N,T,S1) a, in Vector!(K,E,S2) b )
    if( ((K==3||K==0)&&(N==3||N==0)) && hasCompMltAndSum!(T,E) )
{
    static if( a.isDynamic ) enforce( a.length == 3, "wrong length a" );
    static if( b.isDynamic ) enforce( b.length == 3, "wrong length b" );

    a.selftype ret;
    static if( a.isDynamic ) ret.length = 3;
    ret[0] = T(a[1] * b[2]) - T(a[2] * b[1]);
    ret[1] = T(a[2] * b[0]) - T(a[0] * b[2]);
    ret[2] = T(a[0] * b[1]) - T(a[1] * b[0]);
    return ret;
}

private enum AS2D = "x y|u v";
private enum AS3D = "x y z|u v t|r g b";
private enum AS4D = "x y z w";

alias Vector2(T) = Vector!(2,T,AS2D); ///A bundle of aliases
alias Vector3(T) = Vector!(3,T,AS3D); ///ditto
alias Vector4(T) = Vector!(4,T,AS4D); ///ditto

alias Vector2!float vec2; ///ditto
alias Vector3!float vec3; ///ditto
alias Vector4!float vec4; ///ditto

alias Vector2!double dvec2; ///ditto
alias Vector3!double dvec3; ///ditto
alias Vector4!double dvec4; ///ditto

alias Vector2!real rvec2; ///ditto
alias Vector3!real rvec3; ///ditto
alias Vector4!real rvec4; ///ditto

alias Vector2!int ivec2; ///ditto
alias Vector3!int ivec3; ///ditto
alias Vector4!int ivec4; ///ditto

alias Vector2!uint uivec2; ///ditto
alias Vector3!uint uivec3; ///ditto
alias Vector4!uint uivec4; ///ditto

alias Vector!(3,float,"r g b") col3; ///ditto
alias Vector!(4,float,"r g b a") col4; ///ditto

alias Vector!(3,ubyte,"r g b") ubcol3; ///ditto
alias Vector!(4,ubyte,"r g b a") ubcol4; ///ditto

unittest
{
    static assert( is( Vector2!float == vec2 ) );
    static assert( is( Vector3!real == rvec3 ) );
    static assert( is( Vector4!float == vec4 ) );
}

alias Vector!(0,byte)   bvecD; ///ditto
alias Vector!(0,ubyte) ubvecD; ///ditto
alias Vector!(0,int)    ivecD; ///ditto
alias Vector!(0,uint)  uivecD; ///ditto
alias Vector!(0,short)  svecD; ///ditto
alias Vector!(0,ushort)usvecD; ///ditto
alias Vector!(0,long)   lvecD; ///ditto
alias Vector!(0,ulong) ulvecD; ///ditto
alias Vector!(0,float)   vecD; ///ditto
alias Vector!(0,double) dvecD; ///ditto
alias Vector!(0,real)   rvecD; ///ditto

unittest
{
    static assert(  isVector!vec2 );
    static assert(  isVector!vec3 );
    static assert(  isVector!vec4 );
    static assert(  isVector!dvec2 );
    static assert(  isVector!dvec3 );
    static assert(  isVector!dvec4 );
    static assert(  isVector!ivec2 );
    static assert(  isVector!ivec3 );
    static assert(  isVector!ivec4 );
    static assert(  isVector!col3 );
    static assert(  isVector!col4 );
    static assert(  isVector!ubcol3 );
    static assert(  isVector!ubcol4 );
    static assert(  isVector!vecD );
    static assert(  isVector!ivecD );
    static assert(  isVector!dvecD );

    static assert(  isCompatibleVector!(2,float,vec2) );
    static assert(  isCompatibleVector!(3,float,vec3) );
    static assert(  isCompatibleVector!(4,float,vec4) );
    static assert(  isCompatibleVector!(2,double,dvec2) );
    static assert(  isCompatibleVector!(3,double,dvec3) );
    static assert(  isCompatibleVector!(4,double,dvec4) );
    static assert(  isCompatibleVector!(2,int,ivec2) );
    static assert(  isCompatibleVector!(3,int,ivec3) );
    static assert(  isCompatibleVector!(4,int,ivec4) );
    static assert(  isCompatibleVector!(3,float,col3) );
    static assert(  isCompatibleVector!(4,float,col4) );
    static assert(  isCompatibleVector!(3,ubyte,ubcol3) );
    static assert(  isCompatibleVector!(4,ubyte,ubcol4) );
    static assert( !isCompatibleVector!(2,ubyte,ubcol3) );
    static assert( !isCompatibleVector!(3,ubyte,ubcol4) );
}

///
unittest
{
    static assert( Vector!(3,float).isStatic == true );
    static assert( Vector!(3,float).isDynamic == false );

    static assert( Vector!(0,float).isStatic == false );
    static assert( Vector!(0,float).isDynamic == true );

    static assert( isVector!(Vector!(3,float)) );
    static assert( isVector!(Vector!(0,float)) );

    static assert( !__traits(compiles,Vector!(3,float,"x y")) );
    static assert( !__traits(compiles,Vector!(3,float,"x y")) );
    static assert(  __traits(compiles,Vector!(3,float,"x y z")) );

    static assert( Vector!(3,float,"x y z").sizeof == float.sizeof * 3 );
    static assert( Vector!(0,float).sizeof == (float[]).sizeof );

    static assert( Vector!(3,float,"x y z").length == 3 );
}

///
unittest
{
    assert( eq( Vector!(3,float)(1,2,3), [1,2,3] ) );

    auto a = Vector!(3,float)(1,2,3);
    assert( eq( Vector!(5,int)(0,a,4), [0,1,2,3,4] ) );

    static assert( !__traits(compiles, { auto v = Vector!(2,int)(1,2,3); } ) );
    assert( !mustExcept( { auto v = Vector!(0,int)(1,2,3); } ) );
    assert( !mustExcept( { auto v = Vector!(3,int)(1); } ) );
    auto b = Vector!(0,float)(1,2,3);
    assert( b.length == 3 );
    
    auto c = Vector!(3,float)(1);
    assert( eq( c, [1,1,1] ) );
    auto d = c;
    assert( eq( c, d ) );
}

///
unittest
{
    static struct Test1 { float x,y,z; }
    static assert( !__traits(compiles,Vector!(3,float)(Test1.init)) );

    static struct Test2 { float[3] data; }
    static assert( __traits(compiles,Vector!(3,float)(Test2.init)) );
}

///
unittest
{
    auto a = vec3(1,2,3);

    auto a1 = const vec3(a);
    auto a2 = const vec3(1,2,3);
    auto a3 = const vec3(1);

    auto a4 = shared vec3(a);
    auto a5 = shared vec3(1,2,3);
    auto a6 = shared vec3(1);

    auto a7 = immutable vec3(a);
    auto a8 = immutable vec3(1,2,3);
    auto a9 = immutable vec3(1);

    auto a10 = shared const vec3(a);
    auto a11 = shared const vec3(1,2,3);
    auto a12 = shared const vec3(1);

    assert( eq( a, a1 ) );
    assert( eq( a, a4 ) );
    assert( eq( a, a7 ) );
    assert( eq( a, a10 ) );

    a = vec3(a4.data);
}

///
unittest
{
    auto a = ivec2(1,2);
    auto b = vec2(a);
    assert( eq( a, b ) );
}

///
unittest
{
    auto a = vec3(2);
    assert( eq( -a, [-2,-2,-2] ) );
}

///
unittest
{
    auto a = Vector!(3,int,"x y z|u v t|r g b")(1,2,3);
    assert( a.x == a.r );
    assert( a.y == a.g );
    assert( a.z == a.b );
    assert( a.x == a.u );
    assert( a.y == a.v );
    assert( a.z == a.t );

    auto b = Vector!(2,int,"near far|n f")(1,100);
    assert( b.near == b.n );
    assert( b.far  == b.f );

    b.nf = ivec2( 10,20 );
    assert( b.near == 10 );
    assert( b.far == 20 );
}

///
unittest
{
    auto a = vec3(1,2,3);
    auto b = vecD(1,2,3);
    auto c = a + b;
    assert( is( typeof(c) == vec3 ) );
    auto d = b + a;
    assert( is( typeof(d) == vecD ) );
    assert( eq(c,d) );
    auto f = ivec3(1,2,3);
    auto c1 = a + f;
    assert( is( typeof(c1) == vec3 ) );
    auto d1 = ivec3(f) + ivec3(a);
    assert( is( typeof(d1) == ivec3 ) );
    assert( eq(c1,d) );
    assert( eq(c,d1) );

    a *= 2;
    b *= 2;
    auto e = b *= 2;
    assert( eq(a,[2,4,6]) );
    assert( eq(b,a*2) );

    auto x = 2 * a;
    assert( eq(x,[4,8,12]) );

    assert( !!x );
    x[0] = float.nan;
    assert( !x );
}

///
unittest
{
    auto a = vecD(1,2,3);

    auto b = vec3(a);
    auto c = vecD(b);

    assert( eq( a, b ) );
    assert( eq( a, c ) );
}

///
unittest
{
    auto a = vec3(1,2,3);
    auto b = vecD(1,2,3);

    assert( eq( dot(a,b), 1+4+9 ) );
}

///
unittest
{
    auto x = vec3(1,0,0);
    auto y = vecD(0,1,0);
    auto z = vecD(0,0,1);

    assert( eq( cross(x,y), z ) );
    assert( eq( cross(y,z), x ) );
    assert( eq( cross(y,x), -z ) );
    assert( eq( cross(x,z), -y ) );
    assert( eq( cross(z,x), y ) );

    auto fy = vecD(0,1,0,0);
    assert( mustExcept({ auto fz = x * fy; }) );
    auto cfy = vec4(0,1,0,0);
    static assert( !__traits(compiles,x*cfy) );
}

///
unittest
{
    auto a = vec3(2,2,1);
    assert( eq(a.rebase(vec3(2,0,0),vec3(0,2,0),vec3(0,0,2)), [1,1,.5] ) );
}

///
unittest
{
    auto a = vec3(1,2,3);

    assert( a.opDispatch!"x" == 1 );
    assert( a.y == 2 );
    assert( a.z == 3 );

    a.x = 2;
    assert( a.x == 2 );
}

///
unittest
{
    alias Vector!(4,float,"x y dx dy") vec2p;

    auto a = vec2p(1,2,0,0);

    assert( a.opDispatch!"x" == 1 );
    assert( a.dx == 0 );
}

///
unittest
{
    auto a = vec3(1,2,3);

    auto b = a.opDispatch!"xy";
    auto c = a.xx;
    auto d = a.xxxyyzyx;

    static assert( is(typeof(b) == Vector!(2,float,"x y") ) );
    static assert( is(typeof(c) == Vector!(2,float) ) );
    static assert( is(typeof(d) == Vector!(8,float) ) );

    assert( eq( b, [1,2] ) );
    assert( eq( c, [1,1] ) );
    assert( eq( d, [1,1,1,2,2,3,2,1] ) );
}

///
unittest
{
    auto a = vec3(1,2,3);
    auto b = dvec4(4,5,6,7);
    auto c = vecD( 9, 10 );
    a.xz = b.yw;
    assert( eq( a, [5,2,7] ) );
    a.zy = c;
    assert( eq( a, [5,10,9] ) );
    static assert( !__traits(compiles, a.xy=vec3(1,2,3)) );
    static assert( !__traits(compiles, a.xx=vec2(1,2)) );
    auto d = a.zxy = b.wyx;
    static assert( d.access_string == "z x y" );
    static assert( is( d.datatype == float ) );
    assert( eq( d, [ 7,5,4 ] ) );
    assert( eq( a, [ 5,4,7 ] ) );
    a.yzx = a.zxz;
    assert( eq( a, [ 7,7,5 ] ) );
}

///
unittest
{
    auto a = vec3(1,2,3);
    auto b = ivec3(1,2,3);
    auto k = a.len2;
    assert( is( typeof(k) == float ) );

    auto l = b.len2;
    assert( is( typeof(l) == int ) );

    auto m = b.len;
    assert( is( typeof(m) == float ) );

    auto n = b.len!real;
    assert( is( typeof(n) == real ) );

    assert( is( typeof( vec3( 1, 2, 3 ).e ) == vec3 ) );
    assert( abs( a.e.len - 1 ) < float.epsilon );
}

///
unittest
{
    alias Vector!(3,cfloat) cvec3;

    auto a = cvec3( 1-1i, 2, 3i );
    static assert( __traits(compiles, a.e) );
    assert( !mustExcept({ auto k = a.e; }) );
}

///
unittest
{
    alias Vector!(3,Vector!(3,float)) mat3;
    auto a = mat3( vec3(1,0,0), vec3(0,1,0), vec3(0,0,1) );

    a *= 2;
    a += a;

    assert( a[0][0] == 4 );
    assert( a[1][1] == 4 );
    assert( a[2][2] == 4 );

    assert( a[0][1] == 0 );
    assert( a[1][2] == 0 );
    assert( a[2][1] == 0 );

    a ^^= 2;

    assert( a[0][0] == 16 );
    assert( a[1][1] == 16 );
    assert( a[2][2] == 16 );

    auto b = -a;

    assert( b[0][0] == -16 );
    assert( b[1][1] == -16 );
    assert( b[2][2] == -16 );
}

///
unittest
{
    auto a = vecD(1,2,3);
    auto b = a;
    assert( eq(a,b) );
    b[0] = 111;
    assert( !eq(a,b) );

    vecD c;
    c = b;
    assert( eq(c,b) );
    b[0] = 222;
    assert( !eq(c,b) );
}

///
unittest
{
    auto a = vec3(1,2,3);
    auto b = a;
    assert( eq(a,b) );
    b[0] = 111;
    assert( !eq(a,b) );
}
