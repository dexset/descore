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

module des.math.linear.ray;

import std.math;
import std.traits;
import des.util.testsuite;
import des.math.linear.vector;
import des.math.linear.matrix;
import des.math.basic;

version(unittest)
{
    bool eq_seg(A,B,E=float)( in Ray!A a, in Ray!B b, in E eps=E.epsilon )
    { return eq_approx( a.pos.data ~ a.dir.data, b.pos.data ~ b.dir.data, eps ); }
}

///
struct Ray(T) if( isFloatingPoint!T )
{
    ///
    alias Vector3!T vectype;

    ///
    vectype pos, dir;

    mixin( BasicMathOp!"pos dir" );

pure:
    ///
    static auto fromPoints(A,B)( in Vector!(3,A) start, in Vector!(3,B) end )
        if( is(typeof(vectype(start))) && is(typeof(vectype(start))) )
    { return Ray!T( start, end - start ); }

    ///
    this(A,B)( in Vector!(3,A) a, in Vector!(3,B) b )
        if( is(typeof(vectype(a))) && is(typeof(vectype(b))) )
    {
        pos = a;
        dir = b;
    }

    @property
    {
        ///
        ref vectype start() { return pos; }
        ///
        ref const(vectype) start() const { return pos; }
        ///
        vectype end() const { return pos + dir; }
        ///
        vectype end( in vectype p )
        {
            dir = p - pos;
            return p;
        }

        ///
        auto revert() const
        { return Ray!(T).fromPoints( end, start ); }

        ///
        T len2() const { return dir.len2; }
        ///
        T len() const { return dir.len; }
    }

    /// affine transform
    auto tr(X)( in Matrix!(4,4,X) mtr ) const
    {
        return Ray!T( (mtr * Vector4!T( pos, 1 )).xyz,
                      (mtr * Vector4!T( dir, 0 )).xyz );
    }

    /+ высота проведённая из точки это отрезок, 
       соединяющий проекцию точки на прямую и 
       саму точку (Ray) +/
    ///
    auto altitude( in vectype pp ) const
    {
        auto n = dir.e;
        auto dd = pos + n * dot(n,(pp-pos));
        return Ray!T( dd, pp - dd );
    }

    /+ общий перпендикуляр +/
    ///
    auto altitude(F)( in Ray!F seg ) const
    {
        /+ находим нормаль для паралельных 
        плоскостей в которых лежат s1 и s2 +/
        auto norm = cross(dir,seg.dir).e;

        /+ расстояние между началами точками на прямых +/
        auto mv = pos - seg.pos;

        /+ нормальный вектор, длиной в расстояние между плоскостями +/
        auto dist = norm * dot(norm,mv);

        /+ переносим отрезок на плоскость первой прямой
           и сразу находим пересечение +/
        auto pp = calcIntersection( Ray!T( seg.pos + dist, seg.dir ) );

        return Ray!T( pp, -dist );
    }

    /+ пересечение с другой прямой 
       если она в той же плоскости +/
    ///
    auto intersect(F)( in Ray!F seg ) const
    {
        auto a = altitude( seg );
        return a.pos + a.dir * 0.5;
    }

    ///
    auto calcIntersection(F)( in Ray!F seg ) const
    {
        auto a = pos;
        auto v = dir;

        auto b = seg.pos;
        auto w = seg.dir;

        static T resolve( T a0, T r, T a1, T q, T b0, T p, T b1, T s )
        {
            T pq = p * q, rs = r * s;
            return ( a0 * pq + ( b1 - b0 ) * r * q - a1 * rs ) / ( pq - rs );
        }

        auto x = resolve( a.x, v.x, b.x, w.x,  a.y, v.y, b.y, w.y );
        auto y = resolve( a.y, v.y, b.y, w.y,  a.x, v.x, b.x, w.x );
        auto z = resolve( a.z, v.z, b.z, w.z,  a.y, v.y, b.y, w.y );

        x = isFinite(x) ? x : resolve( a.x, v.x, b.x, w.x,  a.z, v.z, b.z, w.z );
        y = isFinite(y) ? y : resolve( a.y, v.y, b.y, w.y,  a.z, v.z, b.z, w.z );
        z = isFinite(z) ? z : resolve( a.z, v.z, b.z, w.z,  a.x, v.x, b.x, w.x );

        if( !isFinite(x) ) x = pos.x;
        if( !isFinite(y) ) y = pos.y;
        if( !isFinite(z) ) z = pos.z;

        return vectype( x, y, z );
    }
}

///
alias Ray!float  fRay;
///
alias Ray!double dRay;
///
alias Ray!real   rRay;

///
unittest
{
    auto r1 = fRay( vec3(1,2,3), vec3(2,3,4) );
    auto r2 = fRay( vec3(4,5,6), vec3(5,2,3) );
    auto rs = fRay( vec3(5,7,9), vec3(7,5,7) );
    assert( r1 + r2 == rs );
}

unittest
{
    auto a = vec3(1,2,3);
    auto b = vec3(2,3,4);
    auto r1 = fRay( a, b );
    assert( r1.start == a );
    assert( r1.end == a + b );
    r1.start = b;
    assert( r1.start == b );
    r1.start = a;
    assert( r1.len == b.len );
    r1.end = a;
    assert( r1.len == 0 );
}

unittest
{
    import des.math.linear.matrix;
    auto mtr = mat4( 2, 0.1, 0.04, 2,
                     0.3, 5, 0.01, 5,
                     0.1, 0.02, 3, 1,
                     0, 0, 0, 1 );

    auto s = fRay( vec3(1,2,3), vec3(2,3,4) );
    
    auto ta = (mtr * vec4(s.start,1)).xyz;
    auto tb = (mtr * vec4(s.end,1)).xyz;
    auto ts = s.tr( mtr );

    assert( eq( ts.start, ta ) );
    assert( eq_approx( ts.end, tb, 1e-5 ) );
}

///
unittest
{
    auto s = fRay( vec3(2,0,0), vec3(-4,4,0) );
    auto p = vec3( 0,0,0 );
    auto r = s.altitude(p);
    assert( eq( p, r.end ) );
    assert( eq( r.pos, vec3(1,1,0) ) );
}

unittest
{
    auto s = fRay( vec3(2,0,0), vec3(0,4,0) );
    auto p = vec3( 0,0,0 );
    auto r = s.altitude(p).len;
    assert( r == 2.0f );
}

unittest
{
    auto s1 = fRay( vec3(0,0,1), vec3(2,2,0) );
    auto s2 = fRay( vec3(2,0,-1), vec3(-4,4,0) );
    auto a1 = s1.altitude(s2);
    auto a2 = s2.altitude(s1);
    assert( eq_seg( a1, a2.revert ) );
    assert( a1.len == 2 );
    assert( eq( a1.pos, vec3(1,1,1) ) );
    assert( eq( a1.dir, vec3(0,0,-2) ) );
}

///
unittest
{
    auto s1 = fRay( vec3(-2,0,0), vec3(1,0,0) );
    auto s2 = fRay( vec3(0,0,2), vec3(0,1,-1) );

    auto a1 = s1.altitude(s2);
    assert( eq_seg( a1, fRay(vec3(0,0,0), vec3(0,1,1)) ) );
}

///
unittest
{
    auto s1 = fRay( vec3(0,0,0), vec3(2,2,0) );
    auto s2 = fRay( vec3(2,0,0), vec3(-4,4,0) );
    assert( eq( s1.intersect(s2), s2.intersect(s1) ) );
    assert( eq( s1.intersect(s2), vec3(1,1,0) ) );
}
