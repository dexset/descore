module des.math.linear.triangle;

import std.traits;
import des.math.linear.vector;
import des.math.linear.matrix;
import des.math.linear.ray;
import des.math.basic;

///
struct Triangle(T) if( isFloatingPoint!T )
{
    ///
    alias Vector3!T vectype;

    ///
    vectype[3] pnt;

pure:

    ///
    this( in vectype P0, in vectype P1, in vectype P2 )
    {
        pnt[0] = P0;
        pnt[1] = P1;
        pnt[2] = P2;
    }

    @property
    {
        ///
        vectype perp() const { return cross( pnt[1]-pnt[0], pnt[2]-pnt[0] ); }
        ///
        vectype norm() const { return perp.e; }
        ///
        T area() const { return perp.len / 2.0; }
        ///
        vectype center() const { return (pnt[0] + pnt[1] + pnt[2]) / 3.0f; }
    }

    /// affine transform
    auto tr(X)( in Matrix!(4,4,X) mtr ) const
    {
        return Triangle!T( (mtr * vec!(4,T,"x y z w")( pnt[0], 1 )).xyz,
                           (mtr * vec!(4,T,"x y z w")( pnt[1], 1 )).xyz,
                           (mtr * vec!(4,T,"x y z w")( pnt[2], 1 )).xyz );
    }

    ///
    Ray!(T)[3] toRays() const
    {
        alias Ray!T st;
        return [ st.fromPoints( pnt[0], pnt[1] ),
                 st.fromPoints( pnt[1], pnt[2] ),
                 st.fromPoints( pnt[2], pnt[0] ) ];
    }

    /+ высота проведённая из точки это отрезок, 
       соединяющий проекцию точки на плоскость и 
       саму точку (Ray) +/
    ///
    auto altitude( in vectype pp ) const
    {
        auto n = norm;
        auto dst = n * dot( n, pp-pnt[0] );
        return Ray!T( pp - dst, dst );
    }

    ///
    auto project(F)( in Ray!F seg ) const
    {
        auto n = norm;
        auto dst1 = dot( n, seg.pos-pnt[0] );
        auto dst2 = dot( n, seg.end-pnt[0] );
        auto diff = dst1 - dst2;
        return Ray!T( seg.png - n * dst1,
                          seg.dir + n * diff );
    }

    ///
    auto intersect(F)( in Ray!F seg ) const
    { return seg.intersect( project(seg) ); }
}

///
alias Triangle!float  fTriangle;
///
alias Triangle!double dTriangle;
///
alias Triangle!real   rTriangle;

///
unittest
{
    auto poly = fTriangle( vec3(0,0,0), vec3(1,0,0), vec3(0,1,0) );
    assert( poly.area == 0.5f );
    assert( poly.norm == vec3(0,0,1) );

    auto pnt = vec3( 2,2,2 );
    auto a = poly.altitude( pnt );
    assert( a.pos == vec3(2,2,0) );
    assert( a.dir == vec3(0,0,2) );
}
