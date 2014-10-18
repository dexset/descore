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

module des.math.linear.vector;

import std.math;
import std.algorithm;
import std.array;
import std.traits;
import std.exception;
import std.string;

import des.util.testsuite;
import des.util.accessstring;
import des.util.flatdata;

version(unittest) import std.stdio;

private pure void isVectorImpl(size_t N,T,alias string AS)( in Vector!(N,T,AS) ) {}
pure bool isVector(E)() { return is( typeof(isVectorImpl(E.init)) ); }

pure bool isStaticVector(E)()
{
    static if( !isVector!E ) return false;
    else return E.isStatic;
}

pure bool isDynamicVector(E)()
{
    static if( !isVector!E ) return false;
    else return E.isDynamic;
}

unittest
{
    static assert( !isStaticVector!float );
    static assert( !isDynamicVector!float );
}

pure bool isCompatibleVector(size_t N,T,E)()
{
    static if( !isVector!E ) return false;
    else return E.init.length == N && is( E.datatype : T );
}

pure bool isValidOp(string op,T,E,K=T)()
{ mixin( `return is( typeof( T.init ` ~ op ~ ` E.init ) : K );` ); }

pure bool hasCompMltAndSum(T,E)()
{ return is( typeof( T(T.init * E.init) ) ) && is( typeof( T.init + T.init ) == T ); }

private enum SEP = " ";

pure @property string spaceSep(string str) { return str.split("").join(SEP); }

private @property string zerosVectorData(size_t N)()
{
    string[] ret;
    foreach( j; 0 .. N )
        ret ~= format( "%d", 0 );
    return "[" ~ ret.join(",") ~ "]";
}

struct Vector( size_t N, T, alias string AS="")
    if( isCompatibleArrayAccessString(N,AS,SEP) || AS.length == 0 )
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
        pure @property auto length() const { return data.length; }

        pure @property auto length( size_t nl )
        {
            data.length = nl;
            return data.length;
        }
    }
    else enum length = N;

    this(E...)( in E vals )
        if( E.length > 0 && is(typeof(flatData!T(vals))) )
    {
        auto buf = flatData!T(vals);

        static if( isStatic )
            enforce( buf.length == length, "bad args length" );
        else
            length = buf.length;

        data[] = buf[];
    }

    static if( isStatic ) this(E)( in E val ) if( is(typeof(T(val))) ) { data[] = T(val); }

    static if( isDynamic ) this(this) { data = this.data.dup; }

    auto opAssign( size_t K, E, alias string oas )( in Vector!(K,E,oas) b )
        if( (K==N||K==0||N==0) && is( typeof(T(E.init)) ) )
    {
        static if( isDynamic ) length = b.length;
        foreach( i; 0 .. length ) data[i] = T(b[i]);
        return this;
    }

    auto opUnary(string op)() const
        if( op == "-" && is( typeof( T.init * (-1) ) : T ) )
    {
        selftype ret;
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            ret[i] = this[i] * -1;
        return ret;
    }

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

    auto opBinary(string op, E)( in E b ) const
        if( isValidOp!(op,T,E) && op != "+" && op != "-" )
    {
        selftype ret;
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            mixin( `ret[i] = this[i] ` ~ op ~ ` b;` );
        return ret;
    }

    auto opOpAssign(string op, E)( in E b )
        if( mixin( `is( typeof( this ` ~ op ~ ` b ) )` ) )
    { mixin( `return this = this ` ~ op ~ ` b;` ); }

    auto opBinaryRight(string op, E)( in E b ) const
        if( isValidOp!(op,E,T,T) && op == "*" )
    { mixin( "return this " ~ op ~ " b;" ); }

    bool opCast(E)() const if( is( E == bool ) )
    { 
        foreach( v; data ) if( !isFinite(v) ) return false;
        return true;
    }

    const @property
    {
        static if( is( typeof( dot(selftype.init,selftype.init) ) ) )
        {
            auto len2() { return dot(this,this); }

            static if( is( typeof( sqrt(CommonType!(T,float)(this.len2)) ) ) )
                auto len(E=CommonType!(T,float))() { return sqrt( E(len2) ); }

            static if( is( typeof( this / len ) == typeof(this) ) )
                auto e() { return this / len; }
        }
    }

    static if( N == 2 )
    {
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
            ref T opDispatch(string v)()
                if( oneOfAccess(AS,v,SEP) )
            { mixin( format( "return data[%d];", getIndex(AS,v,SEP) ) ); }

            T opDispatch(string v)() const
                if( oneOfAccess(AS,v,SEP) )
            { mixin( format( "return data[%d];", getIndex(AS,v,SEP) ) ); }
        }

        static if( isOneSymbolPerFieldAccessString(AS,SEP) )
        {
            @property auto opDispatch(string v)() const
                if( v.length > 1 && oneOfAccessAll(AS,v,SEP) )
            {
                mixin( format( `return Vector!(v.length,T,"%s")(%s);`,
                            isCompatibleArrayAccessString(v.length,v)?v.split("").join(SEP):"",
                            array( map!(a=>format( `data[%d]`,getIndex(AS,a,SEP)))(v.split("")) ).join(",")
                            ));
            }
        }
    }

    /++ для кватернионов +/
    static if( AS == "i j k a" )
    {
        static assert( isFloatingPoint!T, "quaterni must be floating point vector" );

        static selftype fromAngle(E,alias string bs)( T alpha, in Vector!(3,E,bs) b )
            if( isFloatingPoint!E )
        { 
            T a = alpha / cast(T)(2.0);
            return selftype( b * sin(a), cos(a) ); 
        }

        /++ quaterni mul +/
        auto quatMlt(E)( in Vector!(4,E,AS) b ) const
            if( is( CommonType!(T,E) : T ) )
        {
            alias this a;
            auto aijk = a.ijk;
            auto bijk = b.ijk;
            return selftype( cross(aijk, bijk) + aijk * b.a + bijk * a.a,
                    a.a * b.a - dot(aijk, bijk) );
        }

        auto rot(size_t K,E,alias string bs)( in Vector!(K,E,bs) b ) const
            if( (K==0||K==3) && is( CommonType!(T,E) : T ) )
        {
            static if( K==0 ) enforce( b.length == 3, "wrong length" );
            auto res = (this.quatMlt( selftype(b,0).quatMlt(inv) ));
            return Vector!(K,T,bs)( res.ijk );
        }

        @property {
            T norm() const { return dot(this,this); }
            T mag() const { return sqrt( norm ); }
            auto con() const { return selftype( -this.ijk, this.a ); }
            auto inv() const { return con / norm; }
        }
    }
}

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

alias Vector!(2,float,"x y") vec2;
alias Vector!(3,float,"x y z") vec3;
alias Vector!(4,float,"x y z w") vec4;

alias Vector!(4,float,"i j k a") quat;
alias Vector!(4,double,"i j k a") dquat;

alias Vector!(2,double,"x y") dvec2;
alias Vector!(3,double,"x y z") dvec3;
alias Vector!(4,double,"x y z w") dvec4;

alias Vector!(2,int,"x y") ivec2;
alias Vector!(3,int,"x y z") ivec3;
alias Vector!(4,int,"x y z w") ivec4;

alias Vector!(3,float,"r g b") col3;
alias Vector!(4,float,"r g b a") col4;

alias Vector!(3,ubyte,"r g b") ubcol3;
alias Vector!(4,ubyte,"r g b a") ubcol4;

alias Vector!(0,float) vecD;
alias Vector!(0,int) ivecD;
alias Vector!(0,double) dvecD;

unittest
{
    static assert( isVector!vec2 );
    static assert( isVector!vec3 );
    static assert( isVector!vec4 );
    static assert( isVector!quat );
    static assert( isVector!dquat );
    static assert( isVector!dvec2 );
    static assert( isVector!dvec3 );
    static assert( isVector!dvec4 );
    static assert( isVector!ivec2 );
    static assert( isVector!ivec3 );
    static assert( isVector!ivec4 );
    static assert( isVector!col3 );
    static assert( isVector!col4 );
    static assert( isVector!ubcol3 );
    static assert( isVector!ubcol4 );
    static assert( isVector!vecD );
    static assert( isVector!ivecD );
    static assert( isVector!dvecD );
}

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

unittest
{
    assert( eq( Vector!(3,float)(1,2,3), [1,2,3] ) );

    auto a = Vector!(3,float)(1,2,3);
    assert( eq( Vector!(5,int)(0,a,4), [0,1,2,3,4] ) );

    assert( mustExcept( { auto v = Vector!(2,int)(1,2,3); } ) );
    assert( !mustExcept( { auto v = Vector!(0,int)(1,2,3); } ) );
    assert( !mustExcept( { auto v = Vector!(3,int)(1); } ) );
    auto b = Vector!(0,float)(1,2,3);
    assert( b.length == 3 );
    
    auto c = Vector!(3,float)(1);
    assert( eq( c, [1,1,1] ) );
    auto d = c;
    assert( eq( c, d ) );
}

unittest
{
    static struct Test1 { float x,y,z; }
    static assert( !__traits(compiles,Vector!(3,float)(Test1.init)) );

    static struct Test2 { float[3] data; }
    static assert( __traits(compiles,Vector!(3,float)(Test2.init)) );
}

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

unittest
{
    auto a = vec3(2);
    assert( eq( -a, [-2,-2,-2] ) );
}

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

unittest
{
    auto a = vec3(1,2,3);
    auto b = vecD(1,2,3);

    assert( eq( dot(a,b), 1+4+9 ) );
}

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

unittest
{
    auto a = vec3(2,2,1);
    assert( eq(a.rebase(vec3(2,0,0),vec3(0,2,0),vec3(0,0,2)), [1,1,.5] ) );
}

unittest
{
    auto a = vec3(1,2,3);

    assert( a.opDispatch!"x" == 1 );
    assert( a.y == 2 );
    assert( a.z == 3 );

    a.x = 2;
    assert( a.x == 2 );
}

unittest
{
    alias Vector!(4,float,"x y dx dy") vec2p;

    auto a = vec2p(1,2,0,0);

    assert( a.opDispatch!"x" == 1 );
    assert( a.dx == 0 );
}

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

unittest
{
    auto r = quat.fromAngle( PI_2, vec3(0,0,1) );

    auto a = vec3( 1,0,0 );
    auto b = r.rot(a);
    assert( is( typeof(b) == vec3 ) );
    assert( eq( b.data, [ 0, 1, 0 ] ) );
}

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

unittest
{
    alias Vector!(3,cfloat) cvec3;

    auto a = cvec3( 1-1i, 2, 3i );
    static assert( __traits(compiles, a.e) );
    assert( !mustExcept({ auto k = a.e; }) );
}

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

unittest
{
    auto a = vec3(1,2,3);
    auto b = a;
    assert( eq(a,b) );
    b[0] = 111;
    assert( !eq(a,b) );
}
