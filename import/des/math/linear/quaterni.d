module des.math.linear.quaterni;

import des.math.linear.vector;
import des.math.linear.matrix;

import std.traits;
import std.exception : enforce;
import std.math;

import des.util.testsuite;

import des.math.util;
import des.math.basic;

///
struct Quaterni(T) if( isFloatingPoint!T )
{
    ///
    alias vectype = Vector!(4,T);
    ///
    vectype data;
    ///
    alias data this;
    ///
    alias selftype = Quaterni!T;

pure:
    ///
    this(E...)( in E vals ) if( is( typeof( vectype(vals) ) ) )
    { data = vectype(vals); }

    mixin accessByString!(4,T,"data.data","i j k a");
    mixin( BasicMathOp!"data" );

    ///
    static selftype fromAngle(size_t K,E)( T alpha, in Vector!(K,E) axis )
        if( (K==0||K==3) && isFloatingPoint!E )
    {
        static if( K==0 ) enforce( axis.length == 3, "wrong length" );
        T a = alpha / cast(T)(2.0);
        auto vv = axis * sin(a);
        return selftype( vv[0], vv[1], vv[2], cos(a) );
    }

    ///
    auto opMul(E)( in Quaterni!E b ) const
    {
        alias this a;
        auto aijk = a.ijk;
        auto bijk = b.ijk;
        auto vv = cross( aijk, bijk ) + aijk * b.a + bijk * a.a;
        return Quaterni!T( vv[0], vv[1], vv[2], a.a * b.a - dot(aijk, bijk) );
    }

    ///
    auto rot(size_t K,E)( in Vector!(K,E) b ) const
        if( (K==0||K==3) && is( CommonType!(T,E) : T ) )
    {
        static if( K==0 ) enforce( b.length == 3, "wrong length" );
        auto res = this * selftype(b,0) * inv;
        return Vector!(K,T)( res.ijk );
    }

    const @property
    {
        ///
        T norm() { return dot( this, this ); }
        ///
        T mag() { return sqrt( norm ); }
        ///
        auto con() { return selftype( -this.ijk, this.a ); }
        ///
        auto inv() { return selftype( con / norm ); }

        auto len2() { return data.len2; }
    }
}

///
alias Quaterni!float quat;
///
alias Quaterni!double dquat;
///
alias Quaterni!real rquat;

///
unittest
{
    auto q = quat.fromAngle( PI_2, vec3(0,0,1) );
    auto v = vec3(1,0,0);
    auto e = vec3(0,1,0);
    auto r = q.rot(v);
    assert( eq( r, e ) );
}
