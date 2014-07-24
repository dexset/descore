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

module desil.region;

import std.algorithm;
import std.traits;
import desmath.linear.vector;

struct region(size_t N,T)
    if( N >= 1 && isNumeric!T )
{
    alias vec!(N,T,N<4?("xyz"[0..N]):"") ptype;
    alias vec!(N*2,T,N<4?("xyz"[0..N]~"whd"[0..N]):"") rtype;

    alias region!(N,T) selftype;

    union
    {
        rtype vr;
        ptype[2] pt;
    }

    alias vr this;

    pure this(K)( in region!(N,K) e ) { vr = e.vr; }

    pure this(E...)( in E ext )
        if( is( typeof( rtype(ext) ) ) )
    { vr = rtype(ext); }

    @property
    {
        ref ptype pos(){ return pt[0]; }
        ref ptype size(){ return pt[1]; }

        ptype pos() const { return pt[0]; }
        ptype size() const { return pt[1]; }

        ptype lim() const { return pt[0] + pt[1]; }
        ptype lim( in ptype nl )
        {
            pt[1] = nl - pt[0];
            return nl;
        }
    }

    bool opBinaryRight(string op, E)( in E p ) const
        if( isCompVector!(N,T,E) && op == "in" )
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

    bool opBinaryRight(string op, E)( in region!(N,E) p ) const
        if( is( generalType!(T,E) ) && op == "in" )
    { return ( p.pt[0] in this ) && ( p.pt[1] in this ); }

    /+ logic and +/
    auto overlap(E)( in region!(N,E) reg ) const
        if( is( generalType!(T,E) ) )
    {
        ptype r1, r2;

        foreach( i; 0 .. N )
        {
            r1[i] = min( max( pos[i], reg.pos[i] ), lim[i] );
            r2[i] = max( min( lim[i], reg.lim[i] ), pos[i] );
        }

        return selftype( r1, r2 - r1 );
    }

    auto overlapLocal(E)( in region!(N,E) reg ) const
    {
        auto buf = overlap( selftype( reg.pt[0] + pt[0], reg.pt[1] ) );
        return selftype( buf.pt[0] - pt[0], buf.pt[1] );
    }

    auto expand(E)( in region!(N,E) reg ) const
    {
        ptype r1, r2;

        foreach( i; 0 .. N )
        {
            r1[i] = min( pos[i], reg.pos[i], lim[i], reg.lim[i] );
            r2[i] = max( pos[i], reg.pos[i], lim[i], reg.lim[i] );
        }

        return selftype( r1, r2 - r1 );
    }

    auto expand(E)( in E pnt ) const
        if( isCompVector!(N,T,E) )
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

alias region!(1,float) fregion1d;
alias region!(2,float) fregion2d;
alias region!(3,float) fregion3d;

alias region!(1,int) iregion1d;
alias region!(2,int) iregion2d;
alias region!(3,int) iregion3d;

unittest
{
    auto a = fregion1d( 1, 5 );
    assert( 2 in a );
    assert( 8 !in a );
    assert( a.lim[0] == 6 );
    auto b = fregion1d( 2, 3 );
    assert( b in a );
}

unittest
{
    auto a = fregion1d(1,5);
    auto b = fregion1d(2,5);
    assert( a.overlap(b) == b.overlap(a) );
    assert( a.overlap(b) == fregion1d(2,4) );

    assert( a.overlapLocal(b) == fregion1d(2,3) );
}

unittest
{
    auto a = fregion1d(1,2);
    auto b = fregion1d(4,2);
    assert( a.expand(b) = fregion1d(1,5) );
}

unittest
{
    auto a = fregion3d( vec3(0,0,0), vec3(1,1,1) );
    assert( vec3(.5,.2,.8) in a );
    assert( a == a.expand( vec3(.2,.3,.4) ) );
    assert( a != a.expand( vec3(1.2,.3,.4) ) );
    assert( fregion3d( vec3(0,0,0), vec3(1.2,1,1) ) == 
             a.expand( vec3(1.2,.3,.4) ) );
}
