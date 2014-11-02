Provides work with region of N-dim space. Region described as
two point. First point is a start of rectangle region. Second point
is a size of rectingle region.

### `struct Region(size_t N,T) if( N >= 1 && isNumeric!T )`

public aliases: 

if `N<=3`:

- `alias Vector!(N,T,"xyz"[0..N].spaceSep) ptype`
- `alias Vector!(N*2,T,("xyz"[0..N]~"whd"[0..N]).spaceSep) rtype`

else if `N>3`:

- `alias Vector!(N,T) ptype`
- `alias Vector!(N*2,T) rtype`

in any case:

- `alias Region!(N,T) selftype`
- `alias vr this`

public unions:

```d
union
{
    rtype vr;
    ptype[2] pt;
}
```

Region can construct as `Vector!(N*2,T)`

public properties:

- `ref ptype pos()` - return ref to pt[0]
- `ref ptype size()` - return ref to pt[1]

- `ptype pos() const` - return copy of pt[0]
- `ptype size() const` - return copy of pt[1]

- `ptype lim() const` - return sum of pos and size
- `ptype lim( in ptype nl )` - set new lim

Binary operations allowed as for `Vector!(N*2,T)`.
Has two `opBinaryRight` methods, each of them receives 
`op == "in"`.

Example: 

```d
alias Region!(2,float) fRegion2;

auto a = fRegion2( vec2( 3,5 ), vec2(2,2) );
assert( vec2(4,6) in a );
assert( vec2(2,1) !in a );

auto b = fRegion2( vec2( 4,6 ), vec2(0.5,0.5) );
assert( b in a );
auto c = fRegion2( vec2( 4,6 ), vec2(2,2) );
assert( c !in a );
```

const public methods:

- `Region!(N,T) overlap(E)( in Region!(N,E) reg )` - return overlap of `this`
  and `reg`

- `Region!(N,T) overlapLocal(E)( in Region!(N,E) reg )` - return overlap of `this`
  and `reg`. `reg` pos in local coords of `this`

- `Region!(N,T) expand(E)( in Region!(N,E) reg )` - return region that contains
  `this` and `reg`

- `Region!(N,T) expand(E)( in E pnt ) if( isCompatibleVector!(N,T,E) )` - return region that contains
  `this` and point `pnt`
