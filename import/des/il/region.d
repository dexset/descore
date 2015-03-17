module des.il.region;

import std.algorithm;
import std.string;
import std.traits;
import des.math.linear.vector;
import des.util.testsuite;
import std.exception;

import des.il.util;

/// rectangle region of space
struct Region(size_t N,T) if( isNumeric!T )
{
    ///
    alias Vector!(N,T) vec_t;

    ///
    alias Region!(N,T) self_t;

    ///
    vec_t pos, size;

    static if( N == 0 )
    {
        invariant
        {
            enforce( pos.length == size.length, "pos and size dimension mismatch" );
        }
    }

    ///
    pure this(size_t Z,K)( in Region!(Z,K) e )
        if( (Z==0||N==0||Z==N) )
    {
        pos = vec_t( e.pos );
        size = vec_t( e.size );
    }

    ///
    pure this(E...)( in E ext )
        //if( is( typeof( Vector!(N*2,T)(ext) ) ) )
    {
        auto vr = Vector!(N*2,T)(ext);
        static if( N == 0 )
            enforce( vr.length % 2 == 0, "wrong size of input" );
        pos = vec_t( vr.data[0..$/2] );
        size = vec_t( vr.data[$/2..$] );
    }

    @property
    {
        ///
        vec_t lim() const { return pos + size; }
        ///
        vec_t lim( in vec_t nl )
        {
            size = nl - pos;
            return vec_t( nl );
        }

        ///
        size_t dims() const
        {
            static if( N == 0 ) return pos.length;
            else return N;
        }

        static if( N == 0 )
        {
            size_t dims( size_t ndim )
            {
                pos.length = ndim;
                size.length = ndim;
                return ndim;
            }
        }
    }

    ///
    bool opBinaryRight(string op, size_t Z, E)( in Vector!(Z,E) pnt ) const
        if( (Z==0||N==0||Z==N) && op == "in" && is(typeof(E.init>T.init)) )
    {
        static if( N==0 || Z==0 )
            enforce( pnt.length == dims, "dimension mismatch" );

        foreach( i; 0 .. dims )
            if( pnt[i] < pos[i] || pnt[i] >= pos[i] + size[i] )
                return false;

        return true;
    }

    static if( N==1 )
    {
        bool opBinaryRight(string op, E)( in E p ) const
            if( isNumeric!E && op == "in" )
        { return p >= pos[0] && p < pos[0] + size[0]; }
    }

    ///
    bool opBinaryRight(string op, size_t Z, E)( in Region!(Z,E) reg ) const
        if( (Z==0||N==0||Z==N) && op == "in" && is(typeof(E.init>T.init)) )
    {
        static if( N==0 || Z==0 )
            enforce( reg.pos.length == dims, "dimension mismatch" );

        return ( reg.pos in this ) && ( reg.lim in this );
    }

    /// logic and
    auto overlap(size_t Z, E)( in Region!(Z,E) reg ) const
        if( (Z==0||N==0||Z==N) )
    {
        static if( N==0 || Z==0 )
            enforce( reg.pos.length == dims, "dimension mismatch" );

        vec_t r1, r2;

        static if( N==0 )
        {
            r1.length = dims;
            r2.length = dims;
        }

        auto lll = lim;
        auto reg_lim = reg.lim;

        foreach( i; 0 .. dims )
        {
            r1[i] = min( max( pos[i], reg.pos[i] ), lll[i] );
            r2[i] = max( min( lll[i], reg_lim[i] ), pos[i] );
        }

        return self_t( r1, r2 - r1 );
    }

    ///
    auto overlapLocal(size_t Z, E)( in Region!(Z,E) reg ) const
        if( (Z==0||N==0||Z==N) )
    {
        static if( N==0 || Z==0 )
            enforce( reg.pos.length == dims, "dimension mismatch" );

        auto buf = overlap( self_t( vec_t(reg.pos) + pos, reg.size ) );
        return self_t( buf.pos - pos, buf.size );
    }

    ///
    auto expand(size_t Z, E)( in Region!(Z,E) reg ) const
        if( (Z==0||N==0||Z==N) )
    {
        static if( N==0 || Z==0 )
            enforce( reg.pos.length == dims, "dimension mismatch" );

        vec_t r1, r2;

        static if( N==0 )
        {
            r1.length = dims;
            r2.length = dims;
        }

        auto self_lim = lim;
        auto reg_lim = reg.lim;

        foreach( i; 0 .. dims )
        {
            r1[i] = min( pos[i], reg.pos[i], self_lim[i], reg_lim[i] );
            r2[i] = max( pos[i], reg.pos[i], self_lim[i], reg_lim[i] );
        }

        return self_t( r1, r2 - r1 );
    }

    ///
    auto expand(size_t Z, E)( in Vector!(Z,E) pnt ) const
        if( (Z==0||N==0||Z==N) )
    {
        static if( N==0 || Z==0 )
            enforce( pnt.length == dims, "dimension mismatch" );

        vec_t r1, r2;

        static if( N==0 )
        {
            r1.length = dims;
            r2.length = dims;
        }

        auto self_lim = lim;

        foreach( i; 0 .. dims )
        {
            r1[i] = min( pos[i], self_lim[i], pnt[i] );
            r2[i] = max( pos[i], self_lim[i], pnt[i] );
        }

        return self_t( r1, r2 - r1 );
    }
}

///
alias Region!(1,float) fRegion1;
///
alias Region!(2,float) fRegion2;
///
alias Region!(3,float) fRegion3;

///
alias Region!(1,int) iRegion1;
///
alias Region!(2,int) iRegion2;
///
alias Region!(3,int) iRegion3;

unittest
{
    auto a = fRegion1( 1, 5 );
    assert( 2 in a );
    assert( 8 !in a );
    assert( a.lim[0] == 6 );
    auto b = fRegion1( 2, 3 );
    assert( b in a );
}

///
unittest
{
    auto a = fRegion1(1,5);
    auto b = fRegion1(2,5);
    assert( a.overlap(b) == b.overlap(a) );
    assert( a.overlap(b) == fRegion1(2,4) );

    assert( a.overlapLocal(b) == fRegion1(2,3) );
}

///
unittest
{
    auto a = fRegion1(1,2);
    auto b = fRegion1(4,2);
    assert( a.expand(b) == fRegion1(1,5) );
}

unittest
{
    auto a = fRegion3( vec3(0,0,0), vec3(1,1,1) );
    //assert( vec3(.5,.2,.8) in a );
    assert( a.opBinaryRight!"in"( vec3(.5,.2,.8) ) );
    assert( a == a.expand( vec3(.2,.3,.4) ) );
    assert( a != a.expand( vec3(1.2,.3,.4) ) );
    assert( fRegion3( vec3(0,0,0), vec3(1.2,1,1) ) ==
             a.expand( vec3(1.2,.3,.4) ) );
}

///
unittest
{
    alias Region!(5,float) MSR; // MultiSpaceRegtion
    alias MSR.vec_t msrvec;
    auto a = MSR( msrvec(1,0,3,4,3), msrvec(3,2,4,8,4) );
    assert( msrvec(2,1,4,5,5) in a );
}

///
unittest
{
    alias NReg = Region!(0,float);
    auto r1 = NReg( 1,2,3,4 );
    assertEq( r1.dims, 2 );
    assertEq( r1.pos.data, [1,2] );
    assertEq( r1.size.data, [3,4] );

    assert( vec2(2,3) in r1 );

    auto r2 = NReg( 1,2 );
    assertEq( r2.dims, 1 );
    assertEq( r2.pos.data, [1] );
    assertEq( r2.size.data, [2] );

    assert( Vector!(0,float)(1.4) in r2 );
    r2.dims = 3;
    r2.pos = vec3(1,2,3);
    r2.size = vec3(1,2,3);
    //mustExcept({ r2.size = vec2(1,2); }); // uncatcable exception from invariant
    r2 = NReg( vec2(1,2), vec2(3,2) );
    assert( vec2(2,3) in r2 );
}
