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

module des.il.region;

import std.algorithm;
import std.string;
import std.traits;
import des.math.linear.vector;

/// rectangle region of space
struct Region(size_t N,T)
    if( N >= 1 && isNumeric!T )
{
    static if( N <= 3 )
    {
        /// `if( N <= 3 )`
        alias Vector!(N,T,"xyz"[0..N].spaceSep) ptype;
        /// `if( N <= 3 )`
        alias Vector!(N*2,T,("xyz"[0..N]~"whd"[0..N]).spaceSep) rtype;
    }
    else
    {
        ///
        alias Vector!(N,T) ptype;
        ///
        alias Vector!(N*2,T) rtype;
    }

    ///
    alias Region!(N,T) selftype;

    union
    {
        /// in union with [pt](des/il/region/Region.pt.html)
        rtype vr;
        /// in union with [vr](des/il/region/Region.vr.html)
        ptype[2] pt;
    }

    ///
    alias vr this;

    ///
    pure this(K)( in Region!(N,K) e ) { vr = e.vr; }

    ///
    pure this(E...)( in E ext )
        if( is( typeof( rtype(ext) ) ) )
    { vr = rtype(ext); }

    @property
    {
        ///
        ref ptype pos() { return pt[0]; }
        ///
        ref ptype size() { return pt[1]; }

        ///
        ptype pos() const { return pt[0]; }
        ///
        ptype size() const { return pt[1]; }

        ///
        ptype lim() const { return pt[0] + pt[1]; }
        ///
        ptype lim( in ptype nl )
        {
            pt[1] = nl - pt[0];
            return nl;
        }
    }

    ///
    bool opBinaryRight(string op, E, alias string AS)( in Vector!(N,E,AS) p ) const
        if( op == "in" && is(typeof(typeof(p).init[0] > rtype.init[0])) )
    { 
        foreach( i; 0 .. N )
            if( p[i] < vr[i] || p[i] >= vr[i] + vr[i+N] )
                return false;
        return true;
    }

    static if(N==1)
    {
        bool opBinaryRight(string op, E)( in E p ) const
            if( isNumeric!E && op == "in" )
        { return p >= vr[0] && p < vr[0] + vr[1]; }
    }

    ///
    bool opBinaryRight(string op, E)( in Region!(N,E) p ) const
        if( is( generalType!(T,E) ) && op == "in" )
    { return ( p.pt[0] in this ) && ( p.pt[1] in this ); }

    /// logic and
    auto overlap(E)( in Region!(N,E) reg ) const
    {
        ptype r1, r2;

        foreach( i; 0 .. N )
        {
            r1[i] = min( max( pos[i], reg.pos[i] ), lim[i] );
            r2[i] = max( min( lim[i], reg.lim[i] ), pos[i] );
        }

        return selftype( r1, r2 - r1 );
    }

    ///
    auto overlapLocal(E)( in Region!(N,E) reg ) const
    {
        auto buf = overlap( selftype( ptype(reg.pt[0]) + pt[0], reg.pt[1] ) );
        return selftype( buf.pt[0] - pt[0], buf.pt[1] );
    }

    ///
    auto expand(E)( in Region!(N,E) reg ) const
    {
        ptype r1, r2;

        foreach( i; 0 .. N )
        {
            r1[i] = min( pos[i], reg.pos[i], lim[i], reg.lim[i] );
            r2[i] = max( pos[i], reg.pos[i], lim[i], reg.lim[i] );
        }

        return selftype( r1, r2 - r1 );
    }

    ///
    auto expand(E)( in E pnt ) const
        if( isCompatibleVector!(N,T,E) )
    {
        ptype r1, r2;

        foreach( i; 0 .. N )
        {
            r1[i] = min( pos[i], lim[i], pnt[i] );
            r2[i] = max( pos[i], lim[i], pnt[i] );
        }

        return selftype( r1, r2 - r1 );
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
    assert( a.expand(b) = fRegion1(1,5) );
}

unittest
{
    auto a = fRegion3( vec3(0,0,0), vec3(1,1,1) );
    assert( vec3(.5,.2,.8) in a );
    assert( a == a.expand( vec3(.2,.3,.4) ) );
    assert( a != a.expand( vec3(1.2,.3,.4) ) );
    assert( fRegion3( vec3(0,0,0), vec3(1.2,1,1) ) == 
             a.expand( vec3(1.2,.3,.4) ) );
}

///
unittest
{
    alias Region!(5,float) MSR; // MultiSpaceRegtion
    alias MSR.ptype msrvec;
    auto a = MSR( msrvec(1,0,3,4,3), msrvec(3,2,4,8,4) );
    assert( msrvec(2,1,4,5,5) in a );
}
