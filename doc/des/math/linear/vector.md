Provides vector, matrix, segment, polygon, view camera.

### Using vector

```d
struct Vector( size_t N, T, alias string AS="")
    if( isCompatibleArrayAccessString(N,AS,SEP) || AS.length == 0 );
```

Vector can be dynamic (N=0) and static (N>0).
For static vector data can access by names.

```d
alias Vector!(4,float,"x y Vx Vy") phase;
auto a = phase( 1,2,3,4 );
a.x = 10;
a.Vy = 12;
```

If access string has one symbol per element
vector can return vector from elements:

```d
auto a = vec3(1,2,3);
auto b = a.zy; // [3,2]
```

Provides some aliases (vec2, vec3, etc...).

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
```

and can construct from one value:

```d
auto a = vec4(1);
assert( eq( a, [1,1,1,1] ) );
```

Static vectors store data in static arrays:

```d
assert( Vector!(4,float).sizeof == float.sizeof * 4 );
```

#### Math operations

Any binary operations allowed from element type allowed 
from vector and exec per element:

```d
auto a = vec3(1,2,3);
auto b = vec3(2,3,4);
auto c = a + b; // [3,5,7]
auto d = a * b; // [2,6,12]
a *= 2;
a /= 0.5;
```

Cast to `bool` checks any element is finite

`dot(a,b)` function for compatible vetors (by length and type)

`cross(a,b)` function for vectors with length == 3

Some conditional methods:
```d
const @property
{
    static if( is( typeof( dot(selftype.init,selftype.init) ) ) )
    {
        auto len2() { return dot(this,this); }

        static if( is( typeof( sqrt(CommonType!(T,float)(this.len2)) ) ) )
            auto len(E=CommonType!(T,float))() { return sqrt( E(len2) ); }

        static if( is( typeof( this / len ) == typeof(this) ) )
            auto e() { return this / len; }
    }
}

static if( N == 2 )
    auto rebase(I,J)( in I x, in J y ) const
        if( isCompatibleVector!(2,T,I) &&
            isCompatibleVector!(2,T,J) );

static if( N == 3 )
{
    auto rebase(I,J,K)( in I x, in J y, in K z ) const
        if( isCompatibleVector!(3,T,I) &&
            isCompatibleVector!(3,T,J) &&
            isCompatibleVector!(3,T,K) );
```

`rebase` convert static vector to new coord system

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
