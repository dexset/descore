module des.math.method.calculus.integ;

public import des.math.basic.traits;
public import des.math.basic.mathstruct;

import std.math;

///
T euler(T)( in T x, T delegate(in T,double) f, double time, double h )
    if( hasBasicMathOp!T )
{
    return x + f( x, time ) * h;
}

///
T runge(T)( in T x, T delegate(in T,double) f, double time, double h )
    if( hasBasicMathOp!T )
{
    T k1 = f( x, time ) * h;
    T k2 = f( x + k1 * 0.5, time + h * 0.5 ) * h;
    T k3 = f( x + k2 * 0.5, time + h * 0.5 ) * h;
    T k4 = f( x + k3, time + h ) * h;
    return cast(T)( x + ( k1 + k2 * 2.0 + k3 * 2.0 + k4 ) / 6.0 );
}

unittest
{
    double a1 = 0, a2 = 0, pa = 5;
    double time = 0, ft = 10, step = .01;

    auto rpart( in double A, double time ) { return pa; }

    foreach( i; 0 .. cast(ulong)(ft/step) )
    {
        a1 = euler( a1, &rpart, time+=step, step );
        a2 = runge( a1, &rpart, time+=step, step );
    }

    import std.math;
    auto va = ft * pa;
    assert( abs( va - a1 ) <= step * 2 * pa );
    assert( abs( va - a2 ) <= step * pa );

    auto rpart2( in float A, double time ) { return pa; }

    static assert( !is(typeof( euler( a1, &rpart2, 0, 0 ) )));
}

unittest
{
    static struct Pos
    {
        double x=0, y=0;
        mixin( BasicMathOp!"x y" );
    }

    static struct Point
    {
        Pos pos, vel;
        mixin( BasicMathOp!"pos vel" );
    }

    Pos acc( in Pos p )
    {
        return Pos( -(p.x * abs(p.x)), -(p.y * abs(p.y)) );
    }

    Point rpart( in Point p, double time )
    {
        return Point( p.vel, acc(p.pos) );
    }

    auto state1 = Point( Pos(50,10), Pos(5,15) );
    auto state2 = Point( Pos(50,10), Pos(5,15) );

    double t = 0, ft = 10, dt = 0.01;

    foreach( i; 0 .. cast(size_t)(ft/dt) )
    {
        state1 = euler( state1, &rpart, t+=dt, dt );
        state2 = runge( state2, &rpart, t+=dt, dt );
    }
}

///
unittest
{
    import des.math.linear.vector;

    static struct Point 
    { 
        vec3 pos, vel; 
        mixin( BasicMathOp!"pos vel" );
    }

    auto v1 = Point( vec3(10,3,1), vec3(5,4,3) );
    auto v2 = Point( vec3(10,3,1), vec3(5,4,3) );
    assert( v1 + v2 == Point( vec3(20,6,2), vec3(10,8,6) ) );
    assert( v1 * 2.0 == Point( vec3(20,6,2), vec3(10,8,6) ) );

    Point rpart( in Point p, double time )
    { return Point( p.vel, vec3(0,0,0) ); }

    auto v = Point( vec3(10,3,1), vec3(5,4,3) );

    double time = 0, ft = 10, step = .01;
    foreach( i; 0 .. cast(ulong)(ft/step+1) )
        v = runge( v, &rpart, time+=step, step );

    assert( (v.pos - vec3(60,43,31)).len2 < 1e-5 );
}
