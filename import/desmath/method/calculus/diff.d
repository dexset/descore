module desmath.method.calculus.diff;

import desmath.linear;
import std.traits;

import desutil.testsuite;

auto df(size_t N, size_t M, T, E=T, alias string A, alias string B)
    ( Vector!(M,T,B) delegate( in Vector!(N,T,A) ) f, in Vector!(N,T,A) p, E step=E.epsilon*10 )
    if( isFloatingPoint!T && isFloatingPoint!E )
{
    Matrix!(M,N,T) ret;

    T dstep = 2.0 * step;
    foreach( i; 0 .. N )
    {
        Vector!(N,T,A) p1 = p;
        p1[i] -= step;
        Vector!(N,T,A) p2 = p;
        p2[i] += step;

        auto r1 = f(p1);
        auto r2 = f(p2);

        ret.setCol( i, (r2-r1) / dstep );
    }

    return ret;
}

version(unittest) import std.math;

unittest
{
    auto func( in dvec2 p ) { return dvec3( p.x^^2, sqrt(p.y) * p.x, 3 ); }

    auto res = df( &func, dvec2(18,9), 1e-5 );
    auto must = Matrix!(3,2,double)( [ 36, 0, 3, 3, 0, 0 ] );

    assert( eq_approx( res.asArray, must.asArray, 1e-5 ) );
}

auto df_scalar(T,K,E=T)( T delegate(T) f, K p, E step=E.epsilon*2 )
    if( isFloatingPoint!T && isFloatingPoint!E && is( K : T ) )
{
    Vector!(1,T) f_vec( in Vector!(1,T) p_vec )
    { return Vector!(1,T)( f( p_vec[0] ) ); }
    return df( &f_vec, Vector!(1,T)(p), step )[0][0];
}

unittest
{
    auto pow2( double x ){ return x^^2; }
    auto res1 = df_scalar( &pow2, 1 );
    auto res2 = df_scalar( &pow2, 3 );
    auto res3 = df_scalar( &pow2, -2 );
    assert( abs(res1 - 2.0) < 2e-6 );
    assert( abs(res2 - 6.0) < 2e-6 );
    assert( abs(res3 + 4.0) < 2e-6 );
}
