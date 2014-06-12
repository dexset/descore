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

module desmath.linear.poly;

import std.traits;
import desmath.linear.vector;
import desmath.linear.matrix;
import desmath.linear.segment;
import desmath.basic;

struct Poly(T) if( isFloatingPoint!T )
{
    alias vec!(3,T,"xyz") vectype;
    vectype[3] pnt;

    pure this( in vectype P0, in vectype P1, in vectype P2 )
    {
        pnt[0] = P0;
        pnt[1] = P1;
        pnt[2] = P2;
    }

    @property
    {
        vectype perp() const { return ( pnt[1] - pnt[0] ) * ( pnt[2] - pnt[0] ); }
        vectype norm() const { return perp.e; }
        T area() const { return perp.len / 2.0; }
        vectype center() const { return (pnt[0] + pnt[1] + pnt[2]) / 3.0f; }
    }

    auto tr(X)( in mat!(4,4,X) mtr ) const
    {
        return Poly!T( (mtr * vec!(4,T,"xyzw")( pnt[0], 1 )).xyz,
                       (mtr * vec!(4,T,"xyzw")( pnt[1], 1 )).xyz,
                       (mtr * vec!(4,T,"xyzw")( pnt[2], 1 )).xyz );
    }

    Segment!(T)[3] toSegments() const
    {
        alias Segment!T st;
        return [ st.fromPoints( pnt[0], pnt[1] ),
                 st.fromPoints( pnt[1], pnt[2] ),
                 st.fromPoints( pnt[2], pnt[0] ) ];
    }

    /+ высота проведённая из точки это отрезок, 
       соединяющий проекцию точки на плоскость и 
       саму точку (Segment) +/
    auto altitude( in vectype pp ) const
    {
        auto n = norm;
        auto dst = n * ( n ^ ( pp - pnt[0] ) );
        return Segment!T( pp - dst, dst );
    }

    auto project(F)( in Segment!F seg ) const
    {
        auto n = norm;
        auto dst1 = n ^ ( seg.pnt - pnt[0] );
        auto dst2 = n ^ ( seg.end - pnt[0] );
        auto diff = dst1 - dst2;
        return Segment!T( seg.png - n * dst1,
                          seg.dir + n * diff );
    }

    auto intersect(F)( in Segment!F seg ) const
    { return seg.intersect( project(seg) ); }
}

alias Poly!float  fPoly;
alias Poly!double dPoly;
alias Poly!real   rPoly;

unittest
{
    auto poly = fPoly( vec3(0,0,0), vec3(1,0,0), vec3(0,1,0) );
    assert( poly.area == 0.5f );
    assert( poly.norm == vec3(0,0,1) );

    auto pnt = vec3( 2,2,2 );
    auto a = poly.altitude( pnt );
    assert( a.pnt == vec3(2,2,0) );
    assert( a.dir == vec3(0,0,2) );
}
