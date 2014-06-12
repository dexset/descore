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

module desmath.linear.vector;

import std.math;
import std.traits;
import std.algorithm;

private import std.string, std.conv;

/++ work with access string +/
private static pure {

    @property bool failFunc( string ctmsg="", int ln=__LINE__ )()
    { 
        version(unittest) enum UTEST = true;
        else enum UTEST = false;

        debug enum DEBUG = true;
        else enum DEBUG = false;

        static if( UTEST && DEBUG && ln >= 0 ) 
            pragma( msg, format( "fails at line %d : %s", ln, ctmsg ) );

        return false; 
    }

    nothrow string toStr( ptrdiff_t x )
    {
        enum ch = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ];
        string buf = x>=0?"":"-";
        x = x>0?x:-x;
        if( x < 10 ) buf ~= ch[x];
        else buf ~= toStr(x/10) ~ ch[x%10];
        return buf;
    }

    unittest
    {
        assert( toStr( 1 ) == "1" );
        assert( toStr( 0 ) == "0" );
        assert( toStr( 12 ) == "12" );
        assert( toStr( -8 ) == "-8" );
        assert( toStr( 15123 ) == "15123" );
    }

    @property nothrow ptrdiff_t getIndex( string str, char m )()
    { return canFind( str, ""~m ) ? str.length - find(str, ""~m ).length : -1; }

    unittest
    {
        static assert( getIndex!("xyz",'y') == 1 );
        static assert( getIndex!("xyz",'x') == 0 );
        static assert( getIndex!("rgba",'a') == 3 );
        static assert( getIndex!("ijka",'a') == 3 );
        static assert( getIndex!("rgb",'y') == -1 );
    }

    @property bool onlyTrueChars( string str, int ln=__LINE__ )()
    {
        bool check( size_t i )()
        {
            static if( str.length <= i ) return true;
            else
            static if( ( 'a' <= str[i] && 'z' >= str[i] ) || 
                       ( 'A' <= str[i] && 'Z' >= str[i] ) )
                return check!(i+1);
            else
                return failFunc!( format( "string '%s' contain bad symbol '%s' at %d position", str, str[i], i ), ln );
        }
        return check!0;
    }

    unittest
    {
        static assert(  onlyTrueChars!( "xyz" ) );
        static assert(  onlyTrueChars!( "rgba" ) );
        static assert(  onlyTrueChars!( "xxxx" ) );
        static assert( !(onlyTrueChars!( "a:b:c", -1 )) );
        static assert( !(onlyTrueChars!( "a b c", -1 )) );
    }

    @property bool trueAccessString( string str, int ln=__LINE__ )()
    {
        bool check( size_t i1, size_t i2 )() if( i1 < i2 )
        {

            static if( str.length > i2 && str.length-1 > i1 ) 
            {
                static if( str[i1] == str[i2] )
                    return failFunc!( format( "access string '%s' have duplicate char '%s' at %d and %d positions", str, str[i1], i1, i2 ), ln );
                else return check!( i1, i2+1 );
            }
            else static if( str.length <= i2 && str.length-1 > i1 ) return check!( i1+1, i1+2 );
            else static if( str.length <= i2 && str.length-1 <= i1 ) return true;
        }

        static if( !onlyTrueChars!( str, ln ) ) 
            return failFunc!( "access string have not true access chars", ln );
        else
            return check!(0,1);
    }

    unittest
    {
        static assert(  trueAccessString!( "xyz" ) );
        static assert(  trueAccessString!( "rgba" ) );
        static assert( !trueAccessString!( "xxxx", -1 ) );
        static assert( !trueAccessString!( "xzz", -1 ) );
        static assert( !trueAccessString!( "xxz", -1 ) );
        static assert( !trueAccessString!( "xyzz", -1 ) );
        static assert( !trueAccessString!( "xyzww", -1 ) );
        static assert( !trueAccessString!( "a:b:c", -1 ) );
        static assert( !trueAccessString!( "a b c", -1 ) );
    }

    @property bool checkIndexAll( string S, string v )()
    {
        bool checkIndex( string S, string c )()
        {
            static if( c.length == 0 ) return true;
            else
            static if( getIndex!(S,c[0]) >= 0 )
                return checkIndex!(S,c[1 .. $]);
            else return false;
        }

        static if( !onlyTrueChars!v ) return false;
        else return checkIndex!(S,v);
    }

    unittest
    {
        static assert( checkIndexAll!( "xyz", "x" ) );
        static assert( checkIndexAll!( "xyz", "xy" ) );
        static assert( checkIndexAll!( "xyz", "xyz" ) );
        static assert( checkIndexAll!( "xyz", "yx" ) );
        static assert( checkIndexAll!( "xyz", "yzx" ) );
        static assert( checkIndexAll!( "xyz", "zyx" ) );
        static assert( checkIndexAll!( "xyz", "zzz" ) );
        static assert( checkIndexAll!( "xyz", "zyz" ) );
        static assert( checkIndexAll!( "ijka", "ijk" ) );
        static assert( checkIndexAll!( "ijka", "a" ) );
        static assert( !checkIndexAll!( "ijk", "zyz" ) );
    }

    @property string dataComp(string S, string v)()
    {
        static if( v.length == 0 ) return "";
        static if( v.length == 1 )
            return "data[" ~ toStr( getIndex!(S,v[0]) ) ~ "]";
        else
            return dataComp!( S, v[0 .. 1] ) ~ "," ~ dataComp!( S, v[1 .. $] );
    }

    unittest
    {
        static assert( dataComp!("xyz","xy") == "data[0],data[1]" );
        static assert( dataComp!("xyz","yz") == "data[1],data[2]" );
        static assert( dataComp!("xyz","xx") == "data[0],data[0]" );
        static assert( dataComp!("xyz","zyyxyz") == "data[2],data[1],data[1],data[0],data[1],data[2]" );
    }
}

version(unittest)
{
    import desmath.linear.matrix;

    bool eq(T,D=float)( in T m1, in T m2, D eps = D.epsilon*4 )
        if( isFloatingPoint!D && ( isMatrix!T || isVector!T ) )
    {
        float k = 0;
        foreach( i; 0 .. m1.data.length )
            k += abs( m1.data[i] - m2.data[i] );
        return k < eps;
    }
}

/++ work with static, dynamic compatible and accessing to data +/
package{

    @property pure nothrow bool isStaticConv(D,T...)() if( T.length > 0 )
    {
        static if( T.length == 1 ) 
        {
            alias T[0] G;
            static if( isNumeric!G ) return is( G : D );
            else static if( isStaticArray!G ) return is( typeof( G.init[0] ) : D );
            else static if( isVector!G ) return is( G.datatype : D );
            else return false;
        }
        else return isStaticConv!(D,T[0]) && isStaticConv!(D,T[1 .. $]);
    }

    @property pure nothrow bool isAllNumeric(T...)() if( T.length > 0 )
    {
        static if( T.length == 1 ) 
        {
            alias T[0] G;
            static if( isNumeric!G ) return true;
            else static if( isStaticArray!G ) return isNumeric!(typeof(G.init[0]));
            else static if( isVector!G ) return true;
            else return false;
        }
        else return isAllNumeric!(T[0]) && isAllNumeric!(T[1 .. $]);
    }

    @property pure nothrow bool hasDynamicArray(T...)() if( T.length > 0 )
    {
        static if( T.length == 1 )
        {
            alias T[0] G;
            static if( isDynamicArray!G ) return true;
            else return false;
        }
        else return hasDynamicArray!(T[0]) || hasDynamicArray!(T[1 .. $]);
    }

    pure auto getStaticData(string src, string dst, T, E) ( ref size_t S, size_t N )
    {
        //import std.string : format;
        enum string typename = T.stringof;
        static if( isNumeric!E ) 
        {
            // OLOLO!! format is not pure
            //return [ format( "%s[%d] = %s%s[%d]", 
            //        dst, S, is(E==T)?"":"cast("~typename~")", src, N ) ];
            return dst ~ "[" ~ toStr(S++) ~ "] = " ~ ( is(E==T) ? "" : "cast("~typename~")" ) ~ src ~ "[" ~ toStr(N) ~ "]";
        }
        else static if( isStaticArray!E ) 
        {
            string[] buf;
            enum string ncast = is( typeof(E[0]) == T )?"":"cast("~typename~")";
            foreach( i; 0 .. E.length )
                // OLOLO!! format is not pure
                //buf ~= format( "%s[%d] = %s%s[%d][%d]", 
                //        dst, S+i, ncast, src, N, i );
                buf ~= dst ~ "[" ~ toStr(S+i) ~ "] = " ~ ncast ~ src ~ "[" ~ toStr(N) ~ "][" ~ toStr(i) ~ "]";
            S+=E.length;
            return buf;
        }
        else static if( isVector!E ) 
        {
            string[] buf;
            enum string ncast = is( typeof(E.data[0]) == T )?"":"cast("~typename~")";
            foreach( i; 0 .. E.length )
                // OLOLO!! format is not pure
                //buf ~= format( "%s[%d] = %s%s[%d].data[%d]", 
                //        dst, S+i, ncast, src, N, i );
                buf ~= dst ~ "[" ~ toStr(S+i) ~ "] = " ~ ncast ~ src ~ "[" ~ toStr(N) ~ "].data[" ~ toStr(i) ~ "]";
            S+=E.length;
            return buf;
        }
        else static assert( 0, "fail getStaticData with " ~ typename );
    }

    pure @property string getAllStaticData(string src, string dst, T, E... )()
        if( E.length >= 1 )
    {
        size_t S = 0;
        string[] retarr;
        foreach( i, e; E )
        {
            auto buf = getStaticData!(src,dst,T,e)(S,i);
            retarr ~= buf;
        }
        return reduce!"a ~ b ~ \";\n\""( "", retarr );
    }

    T[] getDynamicData(T,E)( E data )
    {
        static if( isNumeric!E ) return [ cast(T)data ];
        else static if( isArray!E )
        {
            T[] buf;
            foreach( d; data )
                buf ~= cast(T)d;
            return buf;
        }
        else static if( isVector!E )
        {
            T[] buf;
            foreach( d; data.data )
                buf ~= cast(T)d;
            return buf;
        }
        else 
            static assert( 0, "fail getDynamicData with " ~ E.stringof );
    }

    pure @property nothrow size_t getStaticArgsLength(E...)() if( E.length >= 1 )
    {
        static if( E.length == 1 )
        {
            alias E[0] G;
            static if( isNumeric!G ) return 1;
            else static if( isStaticArray!G ) return E[0].length;
            else static if( isVector!G ) return E[0].length;
            else return 0;
        }
        else
            return getStaticArgsLength!(E[0]) + getStaticArgsLength!(E[1 .. $]);
    }

    pure @property bool isStaticCompatibleArgs(size_t N, T, E... )()
    {
        static if( E.length == 0 ) return false;
        else return ( isAllNumeric!E && N == getStaticArgsLength!(E) );
    }
} 

private static {
    @property string chVecWithVecOpStr( string data, string bvec, string op, size_t N )()
    {
        import std.string : format;
        string buf;
        foreach( i; 0 .. N )
        {
            auto ind = "[" ~ toStr(i) ~ "]";
            buf ~= data ~ ind ~ op ~ bvec ~ "." ~ data ~ ind ~ ";\n";
        }
        return buf;
    }

    unittest
    {
        assert( chVecWithVecOpStr!( "data", "b", "=", 2 ) == 
                "data[0]=b.data[0];\ndata[1]=b.data[1];\n" );
    }
}

private pure nothrow
{
    void isVectorImpl( size_t N, T, string AS)( vec!(N,T,AS) ){}
    void isCompVectorImpl( size_t N, T, E, string AS)
    ( vec!(N,E,AS) ) if( is( E : T ) ) {}
}

@property bool isVector(T)() { return is( typeof( isVectorImpl( T.init ) ) ); }

@property bool isCompVector(size_t N,T,E)()
{ return is( typeof( isCompVectorImpl!(N,T)( E.init ) ) ); }

@property bool isCompVectors(size_t N,T,E...)() if( E.length > 0 )
{
    static if( E.length == 1 )
        return isCompVector!(N,T,E[0]);
    else
        return isCompVector!(N,T,E[0]) && 
            isCompVectors!(N,T,E[1 .. $]);
}

template generalType(T,E)
{ alias typeof( 1?T.init:E.init ) generalType; }

class VecException: Exception 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg,file,line ); } 
}

private string zeros( size_t N )
{
    string[] ret;
    foreach( i; 0 .. N ) ret ~= "0";
    return "[" ~ join(ret,",") ~ "]";
}

package
{
    string generateFor(ptrdiff_t END, ptrdiff_t START=0)( string bodystr )
    {
        string[] ret;
        for( auto i = START; i < END; i++ )
            ret ~= format( bodystr, i );
        return ret.join("\n");
    }

    string generateFor2(size_t A, size_t B)( string bodystr )
    {
        string[] ret;
        foreach( i; 0 .. A )
            foreach( j; 0 .. B )
                ret ~= format( bodystr, i, j );
        return ret.join("\n");
    }
}

struct vec( size_t N, T=float, string AS="" )
    if( ( ( N == AS.length && trueAccessString!AS ) || AS.length == 0 ) && 
        isNumeric!T && N > 0 )
{
    T[N] data = mixin( zeros(N) );
    alias vec!(N,T,AS) selftype;
    alias T datatype;
    alias N length;
    alias AS accessString;

    pure this(E, string bs)( in vec!(N,E,bs) b ) if( is( E : T ) )
    { mixin( chVecWithVecOpStr!( "data","b","=",N ) ); }

    pure this(E...)( in E ext ) 
    {
        static if( isStaticCompatibleArgs!(N,T,E) )
            mixin( getAllStaticData!("ext","data",T,E) );
        else static if( !hasDynamicArray!(E) )
            static assert(0, "bad arguments '" ~ E.stringof ~ "' for " ~ selftype.stringof );
        else
        {
            T[] buf;
            foreach( e; ext )
                buf ~= getDynamicData!T(e);
            if( buf.length != N )
                throw new VecException( "bad size" );
            data[] = buf[];
        }
    }

    pure auto opAssign(E, string bs)( in vec!(N,E,bs) b )
        if( is( E : T ) )
    {
        mixin( chVecWithVecOpStr!( "data", "b", "=", N ) );
        return this;
    }

    @trusted pure auto opUnary(string op)() const 
        if( op == "-" && is( typeof( T.init * (-1) ) : T ) )
    {
        selftype ret;
        mixin( generateFor!N( "ret.data[%1$d] = cast(T)( data[%1$d] * (-1) );" ) );
        return ret;
    }

    @trusted auto elem(string op, E, string bs)( in vec!(N,E,bs) b ) const
        if( op == "*" || op == "/" || op == "^^" )    
    {
        selftype ret;
        mixin( generateFor!N( "ret.data[%1$d] = cast(T)( data[%1$d] " ~ op ~ " b.data[%1$d] );" ) );
        return ret;
    }

    @trusted auto mlt(E, string bs)( in vec!(N,E,bs) b ) const
    { return this.elem!"*"(b); }

    @trusted auto div(E, string bs)( in vec!(N,E,bs) b ) const
    { return this.elem!"/"(b); }

    @trusted auto opBinary(string op, E, string bs)( in vec!(N,E,bs) b ) const
        if( op == "+" || op == "-" )
    {
        selftype ret;
        mixin( generateFor!N( "ret.data[%1$d] = cast(T)( data[%1$d] " ~ op ~ " b.data[%1$d] );" ) );
        return ret;
    }

    @trusted auto opBinary(string op, E)( in E b ) const
        if( !isVector!E && ( op == "*" || op == "/" || op == "^^" ) && is( generalType!(T,E) ) )
    {
        selftype ret;
        mixin( generateFor!N( "ret.data[%1$d] = cast(T)( data[%1$d] " ~ op ~ " b );" ) );
        return ret;
    }

    auto opBinaryRight(string op, E)( in E b ) const 
        if( !isVector!E && ( op == "*" || op == "/" ) && is( generalType!(T,E) ) )
    { return opBinary!op( b ); }

    auto opBinary(string op, E, string bs)( in vec!(N,E,bs) b ) const
        if( op == "^" && is( generalType!(T,E) ) )
    {
        generalType!(T,E) ret = 0;
        mixin( generateFor!N( "ret += data[%1$d] * b.data[%1$d];" ) );
        return ret;
    }

    auto opOpAssign(string op, E, string bs)( in vec!(N,E,bs) b )
    { return (this = opBinary!op(b)); }
    auto opOpAssign(string op,E)( in E b ) 
        if( !isVector!E )
    { return (this = opBinary!op(b)); }

    @property auto len2() const { return opBinary!"^"(this); }
    @property auto len(E=float)() const 
        if( isFloatingPoint!E ) 
    { return sqrt( cast(E)len2 ); }

    static if( isFloatingPoint!T )
        @property auto e() const { return this / len; }

    bool opCast(E)() const if( is( E == bool ) )
    { 
        foreach( v; data ) if( !isFinite(v) ) return false;
        return true;
    }

    E opCast(E)() const if( isCompVector!(N,T,E) ) { return E(this); }

    bool opEquals(E,string bs)( in vec!(N,E,bs) b ) const
        if( is( generalType!(T,E) ) )
    {
        foreach( i, val; data )
            if( val != b.data[i] ) return false;
        return true;
    }

    ref T opIndex( size_t i ){ return data[i]; }
    T opIndex( size_t i ) const { return data[i]; }

    auto opBinary(string op, E, string bs)( in vec!(N,E,bs) b ) const
        if( N == 3 && op == "*" && is( generalType!(T,E) ) )
    {
        alias this a;
        //return vec!(N,generalType!(T,E),AS)( 
        return selftype( 
                b[2] * a[1] - a[2] * b[1],
                b[0] * a[2] - a[0] * b[2],
                b[1] * a[0] - a[1] * b[0]
                );
    }

    static if( N == 2 )
    {
        auto rebase(I,J)( in I x, in J y ) const
            if( isCompVector!(2,T,I) &&
                isCompVector!(2,T,J) )
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
            if( isCompVector!(3,T,I) &&
                isCompVector!(3,T,J) &&
                isCompVector!(3,T,K) )
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

    static if( AS.length == N )
    {
        @property ref T opDispatch(string v)()
            if( v.length == 1 && getIndex!(AS,v[0]) >= 0 )
        { mixin( "return data[" ~ toStr(getIndex!(AS,v[0])) ~ "];" ); }

        @property T opDispatch(string v)() const
            if( v.length == 1 && getIndex!(AS,v[0]) >= 0 )
        { mixin( "return data[" ~ toStr(getIndex!(AS,v[0])) ~ "];" ); }

        @property auto opDispatch(string v)() const
            if( v.length > 1 && checkIndexAll!(AS,v) )
        { 
            static if( trueAccessString!(v,-1) )
                mixin( "return vec!(v.length,T,v)( " ~ dataComp!(AS,v) ~ " );" );
            else
                mixin( "return vec!(v.length,T)( " ~ dataComp!(AS,v) ~ " );" );
        }
    }

    /++ для кватернионов +/
    static if( AS == "ijka" )
    {
        static assert( isFloatingPoint!T, "quaterni must be floating point vector" );

        static selftype fromAngle(E,string bs)( T alpha, in vec!(3,E,bs) b )
            if( isFloatingPoint!E )
        { 
            T a = alpha / cast(T)(2.0);
            return selftype( b * sin(a), cos(a) ); 
        }

        /++ quaterni mul +/
        auto opBinary(string op,E)( in vec!(4,E,AS) b ) const
            if( is( generalType!(T,E) : T ) && op == "*" )
        {
            alias this a;
            auto aijk = a.ijk;
            auto bijk = b.ijk;
            return selftype( aijk * bijk + aijk * b.a + bijk * a.a,
                    a.a * b.a - (aijk ^ bijk) );
        }

        auto rot(E,string bs)( in vec!(3,E,bs) b ) const
            if( is( generalType!(T,E) : T ) )
        { 
            auto res = (this * selftype(b,0) * inv);
            return vec!(3,T,bs)( res.ijk ) ;
        }

        @property {
            T norm() const { return this ^ this; }
            T mag() const { return sqrt( norm ); }
            auto con() const { return selftype( -this.ijk, this.a ); }
            auto inv() const { return con / norm; }
        }
    }

}

alias vec!(2,float,"xy") vec2;
alias vec!(3,float,"xyz") vec3;
alias vec!(4,float,"xyzw") vec4;

alias vec!(4,float,"ijka") quat;

alias vec!(2,double,"xy") dvec2;
alias vec!(3,double,"xyz") dvec3;
alias vec!(4,double,"xyzw") dvec4;

alias vec!(4,double,"ijka") dquat;

alias vec!(3,float,"rgb") col3;
alias vec!(4,float,"rgba") col4;

alias vec!(3,ubyte,"rgb") bcol3;
alias vec!(4,ubyte,"rgba") bcol4;

alias vec!(2,int,"xy") ivec2;
alias vec!(3,int,"xyz") ivec3;
alias vec!(4,int,"xyzw") ivec4;

alias vec!( 2, float, "nf" ) z_vec; 
alias vec!( 2, float, "wh" ) sz_vec; 

unittest 
{ 
    vec!(3,float,"xyz") a;
    assert( a.sizeof == 3 * float.sizeof );
    vec!(32,byte) b;
    assert( b.sizeof == 32 );

    vec2 v2;
    vec3 v3;
    vec4 v4;

    quat q;

    col3 c3;
    col4 c4;

    ivec2 iv2; 
    ivec3 iv3;
    ivec4 iv4;
}

unittest
{
    auto v = vec3(1,2,3);

    auto v2 = cast(dvec3)v;
    assert( is(v2.datatype == double) );
    assert( v2.x == 1 && v2.y == 2 && v2.z == 3 );

    auto v3 = cast(ivec3)v;
    assert( is(v3.datatype == int) );
    assert( v3.x == 1 && v3.y == 2 && v3.z == 3 );
}

///
unittest
{
    auto a = vec!3( [1,2,3] );
    auto b = vec!5( 0, a, 1 );
    assert( b.data == [ 0, 1,2,3, 1 ] );

    auto c = vec!13( 5, a, 1, cast(int[2])[4,8], 666, b );
    assert( c.data == [ 5, 1,2,3, 1, 4,8, 666, 0,1,2,3,1 ] );
}

unittest
{
    auto a = vec3( 1, 2, 3 );
    auto b = vec3( 3, 4, 5 );
    a = b;
    assert( a.data == b.data );
    a.data[0] = 10;
    assert( a.data != b.data );

    alias vec!(3,int) ivec3;
    auto c = ivec3( 5, 6, 7 );
    assert( !is( typeof( c = a ) ) ); 
    assert(  is( typeof( a = c ) ) );
    c = ivec3( a );
    assert( a.data == c.data );
}

unittest
{
    auto a = vec!3( 1, 2, 3 );
    assert( (-a).data == [ -1, -2, -3 ] );
}

///
unittest
{
    auto a = vec!3( 1,2,3 );
    auto b = vec!3( 3,4,5 );

    auto c = a.elem!"*"(b);
    assert( is( typeof(c) == vec!3 ) );
    assert( c.data == [ 3, 8, 15 ] );

    auto x = vec!3( 2, 4, 5 );
    auto d = c.elem!"/"(x);
    assert( is( typeof(d) == vec!3 ) );
    assert( d.data == [ 1.5, 2, 3 ] );
}

unittest
{
    auto r = quat.fromAngle( PI_2, vec3(0,0,1) );

    auto a = vec3( 1,0,0 );
    auto b = r.rot( a );
    assert( is( typeof(b) == vec3 ) );
    assert( b.data == [ 0, 1, 0 ] );
}

///
unittest
{
    /+
        if unittest in struct body:
            Error: forward reference to inferred return type of function call b.opBinary(2.00000)
        +/
    auto a = vec!(3,float)( 1,2,3 );
    auto b = vec!(3,int)( 3,4,5 );
    auto c = a + b;
    assert( is( typeof(c) == vec!(3,float,"") ) );
    assert( c.data == [ 4, 6, 8 ] );

    c += b;
    assert( c.data == [ 7, 10, 13 ] );
    c -= a;
    assert( c.data == [ 6, 8, 10 ] );

    auto d = b * 2.0f;
    //assert( is( typeof(d) == vec!(3,float) ) );
    assert( is( typeof(d) == vec!(3,int) ) );
    assert( d.data == [ 6, 8, 10 ] );

    auto e = b * 2;
    assert( is( typeof(e) == vec!(3,int) ) );
    assert( e.data == [ 6, 8, 10 ] );

    auto f = 2 * b;
    assert( is( typeof(f) == vec!(3,int) ) );
    assert( f.data == [ 6, 8, 10 ] );

    auto g = 2.0 * b;
    assert( is( typeof(g) == vec!(3,int) ) );
    assert( g.data == [ 6, 8, 10 ] );

    auto x = b ^ g;
    assert( is( typeof(x) == int ) );
    assert( x == 100 );
}

///
unittest
{
    auto a = vec!3( 1,2,3 );
    assert( float.epsilon < 1e-6 );
    assert( abs( a.e.len - 1 ) < float.epsilon );
}

///
unittest
{
    vec!3 a;
    assert( a );
    a = vec!3( 1,2,3 );
    assert( a );
    a[0] = float.nan;
    assert( !a );
    assert( a[0] is float.nan );
}

///
unittest
{
    auto x = vec!3( 1, 0, 0 );
    auto y = vec!3( 0, 1, 0 );
    auto z = x * y;
    assert( z.data == [ 0, 0, 1 ] );
    assert( (x * z).data == [  0, -1, 0 ] );
    assert( (y * z).data == [  1,  0, 0 ] );
    assert( (z * y).data == [ -1,  0, 0 ] );
    x *= y;
    assert( x == z );
}

unittest
{
    auto pos = vec3( 1, 2, 3 );
    assert( pos.x == 1 );
    assert( pos.y == 2 );
    assert( !is( typeof( pos.t ) ) );
    pos.z = 10;
    assert( pos.z == 10 );
}

unittest
{
    /+
        if unittest in struct body:
            dmd: struct.c:741: virtual void StructDeclaration::semantic(Scope*): Assertion `type->ty != Tstruct || ((TypeStruct *)type)->sym == this' failed.
        +/

    auto pos = vec3( 1, 2, 10 );
    auto pxy = pos.xy;
    assert( is( typeof( pxy ) == vec!(2,float,"xy") ) );
    assert( pxy[0] == 1 && pxy[1] == 2 );
    assert( pxy.x == 1 && pxy.y == 2 );
    auto pxzz = pos.xzz;
    assert( is( typeof( pxzz ) == vec!(3,float) ) );
    assert( pxzz[0] == 1 && pxzz[1] == 10 && pxzz[2] == 10 );
}

unittest
{
    auto x = vec3(2,2,0);
    auto y = vec3(0,1,0);
    auto z = vec3(0,0,1);

    auto px = vec3(2,4,.5);

    auto g = px.rebase( x,y,z );

    assert( g.x == 1 &&
            g.y == 2 &&
            g.z == .5 );
}

unittest
{
    auto x = vec2(1,2);
    auto y = vec2(0,1);

    auto px = vec2(1,4);
    auto g = px.rebase( x,y );

    assert( g.x == 1 && g.y == 2 );
}

///
unittest
{
    auto a = vec3( 1,2,3 );
    auto b = ivec3( 2,3,4 );

    auto c = a + b;
    assert( is( typeof(c) == vec3 ) );

    auto d = a ^ b;
    assert( is( typeof(d) == float ) );

    auto e = a * b;
    assert( is( typeof(e) == vec3 ) );

    auto f = b.elem!"/"( a );
    //assert( is( typeof(f) == vec3 ) );
    assert( is( typeof(f) == ivec3 ) );

    auto g = b * 2;
    assert( is( typeof(g) == ivec3 ) );

    auto i = b * 2.0;
    assert( is( typeof(i) == ivec3 ) );

    auto j = 2.0 * a;
    assert( is( typeof(j) == vec3 ) );

    a += j;
    a *= i;

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

    a = b;
    assert( a == b );

    a.z = 10;
    a.x = float.nan;
    assert( !a );

    a[0] = 1;
    assert( a );

    auto x = vec3( 1,1,0 );
    auto y = vec3( 0,1,1 );
    auto z = vec3( 1,0,1 );
    auto ra = a.rebase( x,y,z );

    auto o1 = a.xy;
    assert( is( typeof(o1) == vec!(2,float,"xy") ) );

    auto o2 = a.zx;
    assert( is( typeof(o2) == vec!(2,float,"zx") ) );

    assert( !is( typeof( a.rgb ) ) );

    auto p = a.xxzzyzx;
    assert( is( typeof(p) == vec!(7,float,"") ) );

    auto r = quat.fromAngle( PI_2, vec3(0,0,1) );

    auto q1 = r.rot( vec3(1,0,0) );
    assert( q1 == vec3( 0,1,0 ) );

    auto q2 = r.inv.rot( vec3(1,0,0) );
    assert( q2 == vec3( 0,-1,0 ) );

    assert( is( typeof(q1) == vec3 ) );
}
