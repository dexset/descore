/++
    Provides work with linear algebra vector and some aliases and functions.
+/
module des.math.linear.vector;

import std.exception;
import std.traits;
import std.typetuple;
import std.string;
import std.math;
import std.algorithm;

import des.util.testsuite;

import des.math.util;

import des.math.linear.matrix;

/// checks type is vector
template isVector(E)
{
    enum isVector = is( typeof(impl(E.init)) );
    void impl(size_t N,T)( in Vector!(N,T) ) {}
}

/// checks type is static vector
template isStaticVector(E)
{
    static if( !isVector!E )
        enum isStaticVector = false;
    else enum isStaticVector = E.isStatic;
}

/// checks type is dynamic vector
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

/++
    validate operation between types `T` and `E`
code:
    mixin( `return is( typeof( T.init ` ~ op ~ ` E.init ) : K );` );
 +/
bool isValidOp(string op,T,E,K=T)() pure
{ mixin( `return is( typeof( T.init ` ~ op ~ ` E.init ) : K );` ); }

private string zerosVectorData( size_t N ) @property
{
    string[] ret;
    foreach( j; 0 .. N ) ret ~= "0";
    return "[" ~ ret.join(",") ~ "]";
}

/// сhecks type E is vector and E.dims == N and E.datatype can casted to T
template isSpecVector(size_t N,T,E)
{
    static if( !isVector!E ) enum isSpecVector = false;
    else enum isSpecVector = E.dims == N && is( E.datatype : T );
}

/++
Params:
    N = Number of dimensions, if 0 then vector is dynamic
    T = data type
+/
struct Vector(size_t N,T)
{
    /// `N == 0`
    enum bool isDynamic = N == 0;
    /// `N != 0`
    enum bool isStatic = N != 0;
    /// equals `N`
    enum size_t dims = N;

    /// 
    static if( isStatic ) 
    {
        static if( !isNumeric!T )
            /// if `isStatic` ( fills by zeros if `isNumeric!T` )
            T[N] data;
        else T[N] data = mixin( zerosVectorData(N) );
    }
    else T[] data; /// if `isDynamic`

    ///
    alias data this;

    ///
    alias datatype = T;

    ///
    alias selftype = Vector!(N,T);

    /// `isSpecVector!(N,T)`
    template isCompatible(E) { enum isCompatible = isSpecVector!(N,T,E); }

pure:

    static if( isDynamic )
    {
        @property
        {
            /++
                Length of elements. 
                Enum, if vector `isStatic`.
            +/
            auto length() const { return data.length; }

            ///ditto
            auto length( size_t nl ) { data.length = nl; return nl; }
        }
    }
    else enum length = N;

    /++
     + Vector can be constructed with different ways:

     + * from single values
     + * from arrays
     + * from other vectors
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

                if( buf.length == length ) data[] = buf[];
                else if( buf.length == 1 ) data[] = buf[0];
                else enforce( false, "bad args length" );
            }
        }
        else data = flatData!T(vals);
    }

    static if( isDynamic )
    {
        this(this) { data = data.dup; }

        ///
        static selftype fill(E...)( size_t K, in E vals )
        {
            selftype ret;
            ret.length = K;
            if( E.length )
            {
                auto d = flatData!T(vals);
                foreach( i, ref val; ret.data ) val = d[i%$];
            }
            else
            {
                static if( isNumeric!T ) ret.data[] = 0;
            }
            return ret;
        }

        ///
        static selftype fillOne(E...)( size_t K, in E vals )
        {
            selftype ret;
            ret.length = K;
            if( E.length )
            {
                auto d = flatData!T(vals);
                foreach( i; 0 .. K )
                    ret.data[i] = d[min(i,$-1)];
            }
            else
            {
                static if( isNumeric!T ) ret.data[] = 0;
            }
            return ret;
        }
    }

    ///
    auto opAssign(size_t K,E)( in Vector!(K,E) b )
        if( (K==N||K==0||N==0) && is( typeof(T(E.init)) ) )
    {
        static if( isDynamic ) length = b.length;
        foreach( i; 0 .. length ) data[i] = T(b[i]);
        return this;
    }

    static if( N == 2 || N == 3 || N == 4 )
    {
        static if( N == 2 ) enum AccessString = "x y|w h|u v";
        else
        static if( N == 3 ) enum AccessString = "x y z|w h d|u v t|r g b";
        else
        static if( N == 4 ) enum AccessString = "x y z w|r g b a";

        mixin accessByString!( N, T, "data", AccessString );
    }

    /// 
    auto opUnary(string op)() const
        if( op == "-" && is( typeof( T.init * (-1) ) : T ) )
    {
        selftype ret;
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            ret[i] = this[i] * -1;
        return ret;
    }

    /++
     + Any binary operations execs per element
     +/
    auto opBinary(string op,size_t K,E)( in Vector!(K,E) b ) const
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

    /// ditto
    auto opBinary(string op,E)( in E b ) const
        if( isValidOp!(op,T,E) && op != "+" && op != "-" )
    {
        selftype ret;
        static if( isDynamic ) ret.length = length;
        foreach( i; 0 .. length )
            mixin( `ret[i] = this[i] ` ~ op ~ ` b;` );
        return ret;
    }

    /// ditto
    auto opOpAssign(string op, E)( in E b )
        if( mixin( `is( typeof( this ` ~ op ~ ` b ) )` ) )
    { mixin( `return this = this ` ~ op ~ ` b;` ); }

    /// only mul allowed
    auto opBinaryRight(string op, E)( in E b ) const
        if( isValidOp!(op,E,T,T) && op == "*" )
    { mixin( "return this " ~ op ~ " b;" ); }

    /// checks all elements is finite
    bool opCast(E)() const if( is( E == bool ) )
    {
        foreach( v; data ) if( !isFinite(v) ) return false;
        return true;
    }

    ///
    const(E) opCast(E)() const if( is( T[] == E ) ) { return data.dup; }

    const @property
    {
        static if( is( typeof( dot( selftype.init, selftype.init ) ) ) )
        {
            /++ Square of euclidean length of the vector.

                only:
                if( is( typeof( dot(selftype.init,selftype.init) ) ) )
            +/
            auto len2() { return dot(this,this); }

            static if( is( typeof( sqrt(CommonType!(T,float)(this.len2)) ) ) )
            {
                /++ Euclidean length of the vector

                    only:
                    if( is( typeof( sqrt(CommonType!(T,float)(this.len2)) ) ) )
                +/
                auto len(E=CommonType!(T,float))() { return sqrt( E(len2) ); }
            }

            static if( is( typeof( this / len ) == typeof(this) ) )
            {
                /++ normalized vector

                    only:
                    if( is( typeof( this / len ) == typeof(this) ) )
                +/
                auto e() { return this / len; }
            }
        }
    }

    auto rebase(Args...)( Args e ) const
        if( allSatisfy!(isCompatible,Args) && Args.length == N )
    {
        auto m = Matrix!(N,N,T)(e).T.inv;
        return m * this;
    }
}

///
alias Vector2(T) = Vector!(2,T);
///
alias Vector3(T) = Vector!(3,T);
///
alias Vector4(T) = Vector!(4,T);

///
alias fvec(size_t N) = Vector!(N,float);
///
alias vec2 = fvec!2;
///
alias vec3 = fvec!3;
///
alias vec4 = fvec!4;

///
alias dvec(size_t N) = Vector!(N,double);
///
alias dvec2 = dvec!2;
///
alias dvec3 = dvec!3;
///
alias dvec4 = dvec!4;

///
alias rvec(size_t N) = Vector!(N,real);
///
alias rvec2 = rvec!2;
///
alias rvec3 = rvec!3;
///
alias rvec4 = rvec!4;

///
alias bvec(size_t N) = Vector!(N,byte);
///
alias bvec2 = bvec!2;
///
alias bvec3 = bvec!3;
///
alias bvec4 = bvec!4;

///
alias ubvec(size_t N) = Vector!(N,ubyte);
///
alias ubvec2 = ubvec!2;
///
alias ubvec3 = ubvec!3;
///
alias ubvec4 = ubvec!4;

///
alias ivec(size_t N) = Vector!(N,int);
///
alias ivec2 = ivec!2;
///
alias ivec3 = ivec!3;
///
alias ivec4 = ivec!4;

///
alias uivec(size_t N) = Vector!(N,uint);
///
alias uivec2 = uivec!2;
///
alias uivec3 = uivec!3;
///
alias uivec4 = uivec!4;

///
alias lvec(size_t N) = Vector!(N,long);
///
alias lvec2 = lvec!2;
///
alias lvec3 = lvec!3;
///
alias lvec4 = lvec!4;

///
alias ulvec(size_t N) = Vector!(N,ulong);
///
alias ulvec2 = ulvec!2;
///
alias ulvec3 = ulvec!3;
///
alias ulvec4 = ulvec!4;

unittest
{
    static assert( is( Vector2!float == vec2 ) );
    static assert( is( Vector3!real == rvec3 ) );
    static assert( is( Vector4!double == dvec4 ) );
}

///
alias Vector!(0,byte)   bvecD;
///
alias Vector!(0,ubyte) ubvecD;
///
alias Vector!(0,int)    ivecD;
///
alias Vector!(0,uint)  uivecD;
///
alias Vector!(0,short)  svecD;
///
alias Vector!(0,ushort)usvecD;
///
alias Vector!(0,long)   lvecD;
///
alias Vector!(0,ulong) ulvecD;
///
alias Vector!(0,float)   vecD;
///
alias Vector!(0,double) dvecD;
///
alias Vector!(0,real)   rvecD;

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
    static assert(  isVector!vecD );
    static assert(  isVector!ivecD );
    static assert(  isVector!dvecD );

    static assert(  isSpecVector!(2,float,vec2) );
    static assert(  isSpecVector!(3,float,vec3) );
    static assert(  isSpecVector!(4,float,vec4) );
    static assert(  isSpecVector!(2,double,dvec2) );
    static assert(  isSpecVector!(3,double,dvec3) );
    static assert(  isSpecVector!(4,double,dvec4) );
    static assert(  isSpecVector!(2,int,ivec2) );
    static assert(  isSpecVector!(3,int,ivec3) );
    static assert(  isSpecVector!(4,int,ivec4) );
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

    static assert( Vector!(3,float).sizeof == float.sizeof * 3 );
    static assert( Vector!(0,float).sizeof == (float[]).sizeof );

    static assert( Vector!(3,float).length == 3 );
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

/// convert vectors
unittest
{
    auto a = ivec2(1,2);
    auto b = vec2(a);
    assert( eq( a, b ) );
    auto c = ivec2(b);
    assert( eq( a, c ) );
}

unittest
{
    auto a = vec3(2);
    assert( eq( -a, [-2,-2,-2] ) );
}

///
unittest
{
    auto a = Vector!(3,int)(1,2,3);
    assert( a.x == a.r );
    assert( a.y == a.g );
    assert( a.z == a.b );
    assert( a.x == a.u );
    assert( a.y == a.v );
    assert( a.z == a.t );
}

///
unittest
{
    auto a = vec3(1,2,3);

    assert( a.opDispatch!"x" == 1 );
    assert( a.y == 2 );
    assert( a.z == 3 );

    a.opDispatch!"x" = 2;
    a.x = 2;
    assert( a.x == 2 );
}

///
unittest
{
    auto a = vec3(1,2,3);

    auto b = a.opDispatch!"xy";
    auto c = a.xx;
    auto d = a.xxxyyzyx;

    static assert( is(typeof(b) == Vector!(2,float) ) );
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
    a.opDispatch!"xz"( b.yw );
    assert( eq( a, [5,2,7] ) );
    a.zy = c;
    assert( eq( a, [5,10,9] ) );
    static assert( !__traits(compiles, a.xy=vec3(1,2,3)) );
    static assert( !__traits(compiles, a.xx=vec2(1,2)) );
    auto d = a.zxy = b.wyx;
    static assert( is( d.datatype == double ) );
    assert( eq( d, [ 7,5,4 ] ) );
    assert( eq( a, [ 5,4,7 ] ) );
    a.yzx = a.zxz;
    assert( eq( a, [ 7,7,5 ] ) );
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
    auto a = vec3(2,2,1);
    assert( eq(a.rebase(vec3(2,0,0),vec3(0,2,0),vec3(0,0,2)), [1,1,.5] ) );
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

/// dot multiplication for compaitable vectors.
auto dot(size_t N,size_t K,T,E)( in Vector!(N,T) a, in Vector!(K,E) b )
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

///
unittest
{
    auto a = vec3(1,2,3);
    auto b = vecD(1,2,3);

    assert( eq( dot(a,b), 1+4+9 ) );
}

bool hasCompMltAndSum(T,E)() pure
{ return is( typeof( T(T.init * E.init) ) ) && is( typeof( T.init + T.init ) == T ); }

/// cross multiplication for compaitable vectors.
auto cross(size_t N,size_t K,T,E)( in Vector!(N,T) a, in Vector!(K,E) b )
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
mixin template accessByString( size_t N, T, string data, string AS, string VVASES=" ", string VVASVS="|")
    if( isCompatibleArrayAccessStrings(N,AS,VVASES,VVASVS) )
{
    pure @property
    {
        import std.string;
        import des.math.util;

        T opDispatch(string v)() const
            if( getIndex(AS,v,VVASES,VVASVS) != -1 )
        { mixin( format( "return this.%s[%d];", data, getIndex(AS,v,VVASES,VVASVS) ) ); }

        ref T opDispatch(string v)()
            if( getIndex(AS,v,VVASES,VVASVS) != -1 )
        { mixin( format( "return this.%s[%d];", data, getIndex(AS,v,VVASES,VVASVS) ) ); }

        static if( isOneSymbolPerFieldForAnyAccessString(AS,VVASES,VVASVS) )
        {
            auto opDispatch(string v)() const
                if( v.length > 1 && oneOfAnyAccessAll(AS,v,VVASES,VVASVS) )
            {
                static string gen()
                {
                    string[] res;
                    foreach( i, sym; v )
                        res ~= format( "this.%s[%d]", data, getIndex( AS, ""~sym, VVASES, VVASVS ) );
                    return res.join(",");
                }

                mixin( `return Vector!(v.length,T)(` ~ gen() ~ `);` );
            }

            auto opDispatch(string v,U)( in U b )
                if( v.length > 1 && oneOfAnyAccessAll(AS,v,VVASES,VVASVS) && isCompatibleArrayAccessString(v.length,v) &&
                        ( isSpecVector!(v.length,T,U) || ( isDynamicVector!U && is(typeof(T(U.datatype.init))) ) ) )
            {
                static if( b.isDynamic ) enforce( v.length == b.length );

                static string gen()
                {
                    string[] res;
                    foreach( i, sym; v )
                        res ~= format( "this.%s[%d] = T( b[%d] );", data,
                                    getIndex( AS, ""~sym, VVASES, VVASVS ), i );
                    return res.join("\n");
                }

                mixin( gen() );
                return b;
            }
        }
    }
}

///
unittest
{
    struct NF
    {
        ivec2 data;
        this(E...)( E e ) if( is(typeof(ivec2(e))) ) { data = ivec2(e); }
        mixin accessByString!( 2,int,"data", "near far|n f" );
    }

    auto b = NF(1,100);
    assert( b.near == b.n );
    assert( b.far  == b.f );

    b.nf = ivec2( 10,20 );
    assert( b.near == 10 );
    assert( b.far == 20 );
}

unittest
{
    auto a = Vector!(0,float).fill(5,1,2);
    assertEq( a.length, 5 );
    assertEq( a.data, [1,2,1,2,1] );

    auto b = vecD.fillOne( 10, a, 666 );
    assertEq( b.length, 10 );
    assertEq( b.data, [1,2,1,2,1,666,666,666,666,666] );
}
