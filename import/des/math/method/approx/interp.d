module des.math.method.approx.interp;

import std.algorithm;
import std.exception;
import std.math;
import std.traits;

version(unittest) import des.math.linear.vector;

import des.math.combin;
public import des.math.basic.traits;

///
struct InterpolateTableData(T) if( hasBasicMathOp!T ) { float key; T val; }

///
auto lineInterpolate(T)( in InterpolateTableData!T[] tbl, float k, bool line_end=false )
    if( hasBasicMathOp!T )
{
    enforce( tbl.length > 1 );
    size_t i = tbl.length - find!"a.key > b"( tbl, k ).length;
    if( !line_end )
    {
        if( i <= 0 ) return tbl[0].val;
        else if( i >= tbl.length ) return tbl[$-1].val;
    }
    else
    {
        if( i < 1 ) i = 1;
        else if( i > tbl.length-1 ) i = tbl.length-1;
    }

    auto a = tbl[i-1];
    auto b = tbl[i];
    return cast(T)( a.val + ( b.val - a.val ) * ( ( k - a.key ) / ( b.key - a.key ) ) );
}

///
unittest
{
    alias InterpolateTableData!float TT;
    auto tbl =
        [
        TT( 0, 10 ),
        TT( 10, 18 ),
        TT( 25, 20 ),
        TT( 50, 13 ),
        TT( 55, 25 )
        ];

    assert( lineInterpolate( tbl, 0 ) == 10 );
    assert( lineInterpolate( tbl, 5 ) == 14 );
    assert( lineInterpolate( tbl, 10 ) == 18 );
    assert( lineInterpolate( tbl, -10 ) == 10 );
    assert( lineInterpolate( tbl, 80 ) == 25 );
}

unittest
{
    alias InterpolateTableData!double TD;
    auto tbl =
        [
        TD( 0, 0 ),
        TD( 1, 1 ),
        TD( 2, 3 ),
        TD( 3, 4 )
        ];
    assert( lineInterpolate( tbl, 5, true ) == 6 );
    assert( lineInterpolate( tbl, -3, true ) == -3 );
}

unittest
{
    alias InterpolateTableData!vec3 TC;
    auto tbl =
        [
        TC( 0, vec3(1,0,0) ),
        TC( 1, vec3(0,1,0) ),
        TC( 2, vec3(0,0,1) )
        ];

    assert( lineInterpolate( tbl, -1 ) == vec3(1,0,0) );
    assert( lineInterpolate( tbl, 0 ) == vec3(1,0,0) );
    assert( lineInterpolate( tbl, 0.5 ) == vec3(0.5,0.5,0) );
    assert( lineInterpolate( tbl, 3 ) == vec3(0,0,1) );
}

@property bool canBezierInterpolate(T,F)()
{ return is( typeof( T.init * F.init + T.init * F.init ) == T ) && isNumeric!F; }

pure nothrow auto bezierInterpolation(T,F=float)( in T[] pts, F t )
if( canBezierInterpolate!(T,F) )
in
{
    assert( t >= 0 && t <= 1 );
    assert( pts.length > 0 );
}
body
{
    auto N = pts.length-1;
    auto omt = 1.0 - t;
    T res = pts[0] * pow(omt,N) + pts[$-1] * pow(t,N);
    for( auto i=1; i < N; i++ )
        res = res + pts[i] * pow(t,i) * pow(omt,N-i) * combination(N,i);
    return res;
}

unittest
{
    auto pts = [ vec2(0,0), vec2(2,2), vec2(4,0) ];
    assert( bezierInterpolation( pts, 0.5 ) == vec2(2,1) );
}

pure nothrow auto fixBezierSpline(T,F=float)( in T[] pts, size_t steps )
{
    auto step = cast(F)(1.0) / cast(F)(steps-1);
    auto res = new T[](steps);
    for( auto i=0; i < steps; i++ )
        res[i] = bezierInterpolation( pts, step * i );
    return res;
}

interface BezierSplineInterpolator(T,F=float)
if( canBezierInterpolate!(T,F) )
{ T[] opCall( in T[] ); }

class FixStepsBezierSplineInterpolator(T,F=float) : BezierSplineInterpolator!(T,F)
{
    size_t steps;
    this( size_t steps ) { this.steps = steps; }

    T[] opCall( in T[] pts )
    { return fixBezierSpline!(T,F)( pts, steps ); }
}

unittest
{
    enum size_t len = 100;
    auto fbi = new FixStepsBezierSplineInterpolator!(vec2)(len);
    auto pts = [ vec2(0,0), vec2(2,2), vec2(4,0) ];
    auto res = fbi( pts );
    assert( res.length == len );
}

/+ функция критеря должна быть функцией хевисада +/
auto criteriaBezierSpline(T,F=float)( in T[] pts, bool delegate(in T[], in T) criteria, F min_step=1e-5 )
if( canBezierInterpolate!(T,F) )
in
{
    assert( pts.length > 1 );
    assert( criteria !is null );
    assert( min_step > 0 );
    assert( min_step < cast(F)(.25) / cast(F)(pts.length-1) );
}
body
{
    F step = cast(F)(.25) / cast(F)(pts.length-1);

    auto ret = [ bezierInterpolation( pts, 0 ), bezierInterpolation( pts, min_step ) ];

    auto t = min_step;
    auto o = step;

    while( true )
    {
        if( 1-t < o ) o = 1-t;
        auto buf = bezierInterpolation( pts, t+o );

        if( criteria( ret, buf ) )
        {
            t += o;
            if( t >= 1 ) return ret ~ bezierInterpolation( pts, 1 );
            continue;
        }
        else
        {
            o /= 2.0;
            if( o > min_step ) continue;
            else t += o;
        }

        buf = bezierInterpolation( pts, t );

        if( t > 1 ) return ret ~ bezierInterpolation( pts, 1 );

        ret ~= buf;
        o = step;
    }
}

/+ функция критеря должна быть функцией хевисада +/
auto filterBezierSpline(T,F=float)( in T[] pts, bool delegate(in T[], in T) criteria )
if( canBezierInterpolate!(T,F) )
in
{
    assert( pts.length > 1 );
    assert( criteria !is null );
}
body
{
    auto ret = [ pts[0] ];

    for( auto i = 1; i < pts.length; i++ )
    {
        while( i < pts.length && criteria(ret, pts[i]) ) i++;

        if( ret[$-1] == pts[i-1] )
            ret ~= pts[i];
        else
            ret ~= pts[i-1];
    }

    if( ret[$-1] != pts[$-1] )
        ret ~= pts[$-1];

    return ret;
}

auto angleSplineCriteria(T)( float angle )
    if( isSpecVector!(2,float,T) || isSpecVector!(3,float,T) )
{
    auto cos_angle = cos( angle );
    return ( in T[] accepted, in T newpoint )
    {
        if( accepted.length < 2 ) return false;

        auto cc = [ accepted[$-2], accepted[$-1], newpoint ];

        auto a = (cc[1]-cc[0]).e;
        auto b = (cc[2]-cc[1]).e;

        return dot(a,b) >= cos_angle;
    };
}

auto lengthSplineCriteria(T)( float len )
if( isSpecVector!(2,float,T) || isSpecVector!(3,float,T) )
in{ assert( len > 0 ); } body
{
    return ( in T[] accepted, in T newpoint )
    { return (accepted[$-1] - newpoint).len2 <= len*len; };
}

unittest
{
    auto pts = [ vec2(0,0), vec2(5,2), vec2(-1,2), vec2(4,0) ];
    auto pp = criteriaBezierSpline( pts, angleSplineCriteria!vec2(0.05) );

    assert( pp.length > pts.length );
    assert( pp[0] == pts[0] );
    assert( pp[$-1] == pts[$-1] );
}

unittest
{
    auto pts = [ vec2(0,0), vec2(5,2), vec2(-1,2), vec2(4,0) ];
    auto pp = filterBezierSpline( fixBezierSpline( pts, 1000 ), lengthSplineCriteria!vec2(0.05) );

    assert( pp.length > pts.length );
    assert( pp[0] == pts[0] );
    assert( pp[$-1] == pts[$-1] );
}
