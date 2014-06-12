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

module desil.rect;

import std.math : abs;
import std.traits : isNumeric;
import desmath.linear.vector;

struct vrect(T) if( isNumeric!T )
{
    alias vec!(2,T,"xy") ptype;
    alias vec!(4,T,"xywh") rtype;

    union {
        rtype vr;
        ptype[2] pt;
    }

    alias vr this;

    pure this(K)( in vrect!K e ) { vr = e.vr; }

    pure this(E...)( in E ext )
        if( is( typeof( rtype(ext) ) ) )
    { vr = rtype( ext ); }

    @property ref ptype pos(){ return pt[0]; }
    @property ref ptype size(){ return pt[1]; }
    @property ptype pos() const { return pt[0]; }
    @property ptype size() const { return pt[1]; }

    @property T area() const { return abs( w * h ); }

    bool opBinaryRight(string op, E)( in E p ) const
        if( isCompVector!(2,T,E) && op == "in" )
    { 
        return p[0] >= x && p[0] < x+w &&
               p[1] >= y && p[1] < y+h;
    }

    bool opBinaryRight(string op, E)( in vrect!E r ) const
        if( is( generalType!(T,E) ) && op == "in" )
    {
        return ( r.pos in this ) && 
            ( ( r.pos + r.size ) in this );
    }

    auto scale(E)( in E v ) const
        if( isCompVector!(2,T,E) || isCompVector!(4,T,E) )
    {
        auto buf = vrect!(generalType!(T,E.datatype))( this );
        buf.x *= v[0];
        buf.y *= v[1];
        static if( v.length == 2 )
        {
            buf.w *= v[0];
            buf.h *= v[1];
        }
        else
        {
            buf.w *= v[2];
            buf.h *= v[3];
        }
        return buf;
    }

    @property E[8] points(E=float)() const
        if( is( generalType!(T,E) ) )
    {
        alias this t;
        return [ cast(E)(t.x), t.y,       t.x+t.w, t.y,
                         t.x,  t.y+t.h,   t.x+t.w, t.y+t.h ];
    }

    auto overlap(E)( in vrect!E rect ) const
        if( is( generalType!(T,E) ) )
    {
        auto test(F)( in F p, in F lu, in F rd ) if( isCompVector!(2,T,F) )
        {
            return vec!(2,T,"xy")( 
                    p[0] > lu[0] ? ( p[0] < rd[0] ? p[0] : rd[0] ) : lu[0],
                    p[1] > lu[1] ? ( p[1] < rd[1] ? p[1] : rd[1] ) : lu[1] );
        }

        auto lu = this.pos;
        auto rd = this.pos + this.size;

        auto p1 = test( rect.pos, lu, rd );
        auto p2 = test( rect.pos + rect.size, lu, rd );

        return vrect!T( p1, p2 - p1 );
    }

    auto overlapLocal(E)( in vrect!E r ) const
    {
        auto test(F)( in F p ) if( isCompVector!(2,T,F) )
        {
            return vec!(2,T,"xy")( 
                    p[0] > 0 ? ( p[0] < this.w ? p[0] : this.w ) : 0 ,
                    p[1] > 0 ? ( p[1] < this.h ? p[1] : this.h ) : 0 );
        }

        auto p1 = test( r.pos );
        auto p2 = test( r.pos + r.size );

        return vrect!T( p1, p2 - p1 );
    }

    auto expand(E)( in vrect!E r ) const
    {
        auto p1 = r.pos;
        auto p2 = r.pos + r.size;

        auto p3 = this.pos;
        auto p4 = this.pos + this.size;

        import std.algorithm;

        auto x1 = min( p1[0], p2[0], p3[0], p4[0] );
        auto y1 = min( p1[1], p2[1], p3[1], p4[1] );
        auto x2 = max( p1[0], p2[0], p3[0], p4[0] );
        auto y2 = max( p1[1], p2[1], p3[1], p4[1] );

        return vrect!T( x1, y1, x2-x1, y2-y1 );
    }
}

alias vrect!int irect;
alias vrect!float frect;

unittest
{
    auto r1 = irect( 1,2, 4,4 );
    assert( r1.pt[0].data == [ 1, 2 ] );
    assert( r1.pt[1].data == [ 4, 4 ] );

    auto r2 = frect( r1 );
    r1.pt[0] = ivec2( 2,2 );
    assert( r2.pt[0].data == [ 1, 2 ] );
    assert( r2.pt[1].data == [ 4, 4 ] );

    auto r3 = frect( quat( 1, 2, 3, 3 ) );
    assert( r3.pt[0].data == [ 1, 2 ] );
    assert( r3.pt[1].data == [ 3, 3 ] );

    auto r4 = frect( ivec2(1,4), ivec2(3,2) );
    assert( r4.pt[0].data == [ 1, 4 ] );
    assert( r4.pt[1].data == [ 3, 2 ] );

    auto r5 = frect( 1, ivec2(4,3), 2 );
    assert( r5.pt[0].data == [ 1, 4 ] );
    assert( r5.pt[1].data == [ 3, 2 ] );

    assert( frect.sizeof == 4 * float.sizeof );
}

///
unittest
{
    auto r1 = irect( 1,2, 4,4 );
    assert( r1.x == 1 );
    r1.h = 10;
    assert( r1.h == 10 );
    assert( r1.area == 40 );

    assert( ivec2( 2,2 ) in irect( 1,1, 2,2 ) );
    assert( ivec2( 1,1 ) in irect( 1,1, 2,2 ) );
    assert( ivec2( 1,0 ) !in irect( 1,1, 2,2 ) );
    assert( irect( 1,1,1,1 ) in irect( 0,0, 3,3 ) );
    assert( irect( 1,1,2,2 ) !in irect( 0,0, 3,3 ) );

    assert( irect(1,1,1,1).scale( ivec2(2,4) ) == irect( 2,4,2,4 ) );
    assert( irect(1,1,1,1).scale( ivec4(2,4,6,8) ) == irect( 2,4,6,8 ) );

    assert( irect(1,1,2,2).points == [ 1.0f, 1, 3, 1, 1, 3, 3, 3 ] );
    assert( is( typeof(irect(1,1,2,2).points[0] ) == float ) );

    assert( irect( -1,-1,8,4 ).overlap( irect( 1,1,6,2 ) ) == irect( 1,1,6,2 ) );
    assert( irect( -1,-1,8,4 ).overlap( irect( -2,1,6,2 ) ) == irect( -1,1,5,2 ) );
    assert( irect( -1,-1,8,4 ).overlap( irect( 1,1,10,2 ) ) == irect( 1,1,6,2 ) );
    assert( irect( -1,-1,8,4 ).overlap( irect( 2,1,4,6 ) ) == irect( 2,1,4,2 ) );

    assert( irect( 1,1,8,4 ).overlapLocal( irect( 2,2,8,6 ) ) == irect( 2,2,6,2 ) );
    assert( irect( 1,1,8,4 ).overlapLocal( irect( -2,-2,10,6 ) ) == irect( 0,0,8,4 ) );
}

unittest
{
    auto r1 = irect( 1,1, 2,2 );
    auto r2 = irect( 0,0, 2,2 );

    assert( r1.expand(r2) == r2.expand(r1) );
    assert( r1.expand(r2) == irect(0,0,3,3) );

    auto r3 = irect( 2,2, 2,2 );
    assert( r1.expand(r3) == r3.expand(r1) );
    assert( r1.expand(r3) == irect(1,1,3,3) );

    assert( r2.expand(r3) == r3.expand(r2) );
    assert( r2.expand(r3) == irect(0,0,4,4) );

    auto r4 = irect(10,10,-1,-1);
    assert( r4.expand(r1) == r1.expand(r4) );
    assert( r4.expand(r1) == irect(1,1,9,9) );

    auto m1 = irect( 1, -5, 3, 7 );
    auto m2 = irect( 5, -3, 4, 2 );
    auto m3 = irect( 5, -3, 4, 9 );

    assert( m1.expand(m2) == m2.expand(m1) );
    assert( m1.expand(m2) == irect(1,-5,8,7) );

    assert( m1.expand(m3) == m3.expand(m1) );
    assert( m1.expand(m3) == irect(1,-5,8,11) );

    auto m4 = irect( -2, -7, 1, 1 );
    assert( m1.expand(m4) == m4.expand(m1) );
    assert( m1.expand(m4) == irect(-2,-7,6,9) );
}
