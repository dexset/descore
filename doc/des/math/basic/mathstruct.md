### Using mathstruct

Example:

```d
struct Val
{
    float v1 = 0;
    double v2 = 0;
    mixin( BasicMathOp!"v1 v2" );
}

static assert( isAssignable!(Unqual!Val,Unqual!Val) );
static assert( is( typeof(Val.init + Val.init) == Val ) );
static assert( is( typeof(Val.init - Val.init) == Val ) );
static assert( is( typeof( cast(Val)(Val.init * 0.5) ) ) );
static assert( is( typeof( cast(Val)(Val.init / 0.5) ) ) );

auto p1 = Val( 1, 2 );
auto p2 = Val( 2, 3 );

assert( p1 + p2 == Val(3,5) );
assert( p2 - p1 == Val(1,1) );
assert( p1 * 3 == Val(3,6) );
assert( p1 / 2 == Val(0.5,1) );
```

```d
struct Comp
{
    string str;
    float val; 
    float time = 0;
    mixin( BasicMathOp!"val" );
}

static assert( hasBasicMathOp!Comp );

auto c1 = Comp( "ololo", 10, 1.3 );
auto c2 = Comp( "valav", 5, .8 );

assert( c1 + c2 == Comp("ololo", 15, 1.3) );
```

```d
struct Vec { double x=0, y=0; }
static assert( !hasBasicMathOp!Vec );

struct Point 
{ 
    Vec pos, vel; 
    string str;
    float val;
    mixin( BasicMathOp!"pos.x pos.y vel.x vel.y val" ); 
}
static assert( hasBasicMathOp!Point );

auto a = Point( Vec(1,2), Vec(2,3), "hello", 3 );

assert( a + a == Point( Vec(2,4), Vec(4,6), "hello", 6 ) );
assert( a * 2 == Point( Vec(2,4), Vec(4,6), "hello", 6 ) );
```
