## `math.method`

### `math.method.approx.interp`

Provides some interpolation functions and help types

#### Linear interpolation

```d
struct InterpolateTableData(T) if( hasBasicMathOp!T ) { float key; T val; }

auto lineInterpolate(T)( in InterpolateTableData!T[] tbl, float k, bool line_end=false )
    if( hasBasicMathOp!T );
```

Example:

```d
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
```
```d
    auto tbl =
        [
        TT( 0, 0 ),
        TT( 1, 1 ),
        TT( 2, 3 ),
        TT( 3, 4 )
        ];
    assert( lineInterpolate( tbl, 5, true ) == 6 );
    assert( lineInterpolate( tbl, -3, true ) == -3 );
```
```d
    alias InterpolateTableData!vec3 TC;
    auto tbl =
        [
        TC( 0, vec3(1,0,0) ),
        TC( 1, vec3(0,1,0) ),
        TC( 2, vec3(0,0,1) )
        ];

    assert( lineInterpolate( tbl, -1 )  == vec3(1,0,0) );
    assert( lineInterpolate( tbl, 0 )   == vec3(1,0,0) );
    assert( lineInterpolate( tbl, 0.5 ) == vec3(0.5,0.5,0) );
    assert( lineInterpolate( tbl, 3 )   == vec3(0,0,1) );
```

#### Bezier interpolation

```d
@property bool canBezierInterpolate(T,F)()
{ return is( typeof( T.init * F.init + T.init * F.init ) == T ) && isNumeric!F; }

pure nothrow auto bezierInterpolation(T,F=float)( in T[] pts, F t )
if( canBezierInterpolate!(T,F) )
in
{
    assert( t >= 0 && t <= 1 );
    assert( pts.length > 0 );
}
```

Exapmle: 

```d
    auto pts = [ vec2(0,0), vec2(2,2), vec2(4,0) ];
    assert( bezierInterpolation( pts, 0.5 ) == vec2(2,1) );
```

### `math.method.calculus.diff`

Vector derivative

```d
Matrix!(M,N,T) df(size_t N, size_t M, T, E=T, alias string A, alias string B)
    ( Vector!(M,T,B) delegate( in Vector!(N,T,A) ) f, in Vector!(N,T,A) p, E step=E.epsilon*10 )
    if( isFloatingPoint!T && isFloatingPoint!E )
```

Example:

```d
    auto func( in dvec2 p ) { return dvec3( p.x^^2, sqrt(p.y) * p.x, 3 ); }

    auto res = df( &func, dvec2(18,9), 1e-5 );
    auto must = Matrix!(3,2,double)( [ 36, 0, 3, 3, 0, 0 ] );

    assert( eq_approx( res.asArray, must.asArray, 1e-5 ) );
```

Scalar derivative

```d
auto df_scalar(T,K,E=T)( T delegate(T) f, K p, E step=E.epsilon*2 )
    if( isFloatingPoint!T && isFloatingPoint!E && is( K : T ) )
```

Example:

```d
    auto pow2( double x ){ return x^^2; }
    auto res1 = df_scalar( &pow2, 1 );
    auto res2 = df_scalar( &pow2, 3 );
    auto res3 = df_scalar( &pow2, -2 );
    assert( abs(res1 - 2.0) < 2e-6 );
    assert( abs(res2 - 6.0) < 2e-6 );
    assert( abs(res3 + 4.0) < 2e-6 );
```

### `math.method.calculus.integ`

Provides 2 methods:

- `T euler(T)( in T x, T delegate(in T,double) f, double time, double h ) if( hasBasicMathOp!T )` -
    simple euler integration method

- `T runge(T)( in T x, T delegate(in T,double) f, double time, double h ) if( hasBasicMathOp!T )` -
    RK4

Example:

```d
struct Pos
{
    double x=0, y=0;
    mixin( BasicMathOp!"x y" );
}

struct Point
{
    Pos pos, vel;
    mixin( BasicMathOp!"pos vel" );
}

Pos acc( in Pos p ) { return Pos( -(p.x * abs(p.x)), -(p.y * abs(p.y)) ); }

Point rpart( in Point p, double time ) { return Point( p.vel, acc(p.pos) ); }

auto state1 = Point( Pos(50,10), Pos(5,15) );
auto state2 = Point( Pos(50,10), Pos(5,15) );

double t = 0, ft = 10, dt = 0.01;

foreach( i; 0 .. cast(size_t)(ft/dt) )
{
    state1 = euler( state1, &rpart, t+=dt, dt );
    state2 = runge( state2, &rpart, t+=dt, dt );
}
```

### `math.method.stat.randn`

Provides normal distibution

```d
double normal( double mu=0.0, double sigma=1.0 );
```
