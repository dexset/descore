### Using vector

```d
struct Vector( size_t N, T, alias string AS="")
    if( isCompatibleArrayAccessString(N,AS,SEP) || AS.length == 0 );
```

Vector can be dynamic (N=0) and static (N>0).

Vector has `alias data this` and can used as array.

Vector has aliases and enums (static fields):

```d
alias Vector!(3,float,"x y z") vec3;
alias Vector!(0,float) vecD;

assert( is( vec3.datatype == float ) );
assert( is( vecD.datatype == float ) );
assert( vec3.access_string == "x y z" );
assert( vecD.access_string == "" ); // not allowed for dynamic vectors
assert( is( vec3.selftype == vec3 ) );
assert( is( vecD.selftype == vecD ) );

assert( vec3.isDynamic == false );
assert( vecD.isDynamic == true );
assert( vec3.isStatic == true );
assert( vecD.isStatic == false );
assert( vec3.dims == 3 );
assert( vecD.dims == 0 );

assert( vec3.length == 3 );
assert( !__traits(__compiles,vecD.length) ); // for dynamic its a property
auto a = vecD(1,2);
assert( a.length == 2 );
```
Static vector inits by zeros if `isNumeric!datatype`

Vector can construct with different ways:

- from single values

- from arrays

- from other vectors

they ways can combined:

```d
alias Vector!(8,float) MegaVector;

auto v2 = vec2(1,2);
auto v3 = vec3(3,4,5);

auto a = MegaVector( 0, v2, v3, [6,7] );
assert( eq( a, [0,1,2,3,4,5,6,7] ) );
```

and static vector can construct from one value:

```d
auto a = vec4(1);
assert( eq( a, [1,1,1,1] ) );
```

For static vector data can access by names.

```d
alias Vector!(4,float,"x y Vx Vy") Phase;
auto a = Phase( 1,2,3,4 );
a.x = 10;
a.Vy = 12;
```

If access string has one symbol per element
vector can return vector from elements:

```d
auto a = Vector!(3,float,"x y z")(1,2,3);
auto b = a.zy; // equals vec2( a.z, a.y )
```

Provides some aliases:

`alias Vector!(<N>,<Type>,<Access>) <T>vec<N>` where:

- `<N>` - `size_t` - element count [0,2,3,4,D] where `D` is dynamic
- `<T>` type id, associated with `<Type>` as:

    - NoID : `float`
    - `d`  : `double`
    - `r`  : `real`
    - `i`  : `int`
    - `ui` : `uint`
    - `b`  : `byte`
    - `ub` : `ubyte`

- `<Access>` only for static "x y z w"[0..N]

Example:
```d
alias Vector!(3,float,"x y z") vec3;
alias Vector!(2,double,"x y") dvec2;
```

and some special:

```d
alias Vector!(4,float,"i j k a") quat;
alias Vector!(4,double,"i j k a") dquat;

alias Vector!(3,float,"r g b") col3;
alias Vector!(4,float,"r g b a") col4;

alias Vector!(3,ubyte,"r g b") ubcol3;
alias Vector!(4,ubyte,"r g b a") ubcol4;
```

Static vectors store data in static arrays:

```d
assert( Vector!(4,float).sizeof == float.sizeof * 4 );
```

#### Math operations

Any binary operations that allowed from type of element allowed
from vector and exec per element:

```d
auto a = vec3(1,2,3);
auto b = vec3(2,3,4);
auto c = a + b; // [3,5,7]
auto d = a * b; // [2,6,12]
auto e = a * 3; // [3,6,9]
a *= 2;
a /= 0.5;
auto f = b ^^ 2; // [4,9,16]
```

Only multiplication `*` allows as opBinaryRight, and works per element.

Cast to `bool` checks all elements is finite.

If type of vector elements allows self multiplication and summation:

`dot(a,b)` dot mul operation for compatible vetors (by length and type)

`cross(a,b)` cross mul operation for vectors with length == 3

If allows dot mul vectors has some const properties:

```d
auto a = ivec3(1,2,3);
auto l2 = a.len2; // sqr of cartesian length (int)
auto l = a.len; // cartesian length (float)
auto b = dvec3(1,2,3);
auto lb = b.len; // double
auto ae = a.e; // identity-length vector
```

`rebase` convert static vector to new coord system

If static vector dims == 2
```d
auto a = vec2(1,1);
auto nx = vec2(2,0);
auto ny = vec2(0,2);
auto b = a.rebase(nx,ny);
assert( eq( b, [0.5,0.5] ) );
```

And for vectors with dims == 3
```d
auto a = vec3(1,1,1);
auto nx = vec3(2,0,0);
auto ny = vec3(0,2,0);
auto nz = vec3(0,0,2);
auto b = a.rebase(nx,ny,nz);
assert( eq( b, [0.5,0.5,0.5] ) );
```

If N==4 and access string is "i j k a" appends quaternion methods:

```d
static selftype fromAngle(E,alias string bs)( T alpha, in Vector!(3,E,bs) axis )
    if( isFloatingPoint!E );

// quaterni mul
auto quatMlt(E)( in Vector!(4,E,AS) b ) const;

// vector rotation
auto rot(size_t K,E,alias string bs)( in Vector!(K,E,bs) b ) const;

const @property
{
    T norm() { return dot(this,this); }
    T mag() { return sqrt( norm ); }
    auto con() { return selftype( -this.ijk, this.a ); }
    auto inv() { return con / norm; }
}
```

For more information see unittest in `des.math.linear.vector`
