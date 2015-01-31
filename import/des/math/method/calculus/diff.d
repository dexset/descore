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

module des.math.method.calculus.diff;

import des.math.linear;
import std.traits;

import des.util.testsuite;

version(unittest) import std.math;

///
auto df(size_t N, size_t M, T, E=T)
    ( Vector!(M,T) delegate( in Vector!(N,T) ) f, in Vector!(N,T) p, E step=E.epsilon*10 )
    if( isFloatingPoint!T && isFloatingPoint!E )
{
    Matrix!(M,N,T) ret;

    T dstep = 2.0 * step;
    foreach( i; 0 .. N )
    {
        Vector!(N,T) p1 = p;
        p1[i] -= step;
        Vector!(N,T) p2 = p;
        p2[i] += step;

        auto r1 = f(p1);
        auto r2 = f(p2);

        ret.setCol( i, (r2-r1) / dstep );
    }

    return ret;
}

///
unittest
{
    auto func( in dvec2 p ) { return dvec3( p.x^^2, sqrt(p.y) * p.x, 3 ); }

    auto res = df( &func, dvec2(18,9), 1e-5 );
    auto must = Matrix!(3,2,double)( 36, 0, 3, 3, 0, 0 );

    assert( eq_approx( res.asArray, must.asArray, 1e-5 ) );
}

///
auto df_scalar(T,K,E=T)( T delegate(T) f, K p, E step=E.epsilon*2 )
    if( isFloatingPoint!T && isFloatingPoint!E && is( K : T ) )
{
    Vector!(1,T) f_vec( in Vector!(1,T) p_vec )
    { return Vector!(1,T)( f( p_vec[0] ) ); }
    return df( &f_vec, Vector!(1,T)(p), step )[0][0];
}

///
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
