Provides work with segment. It is a point-size pair, where size is a direction
vector.

#### `struct Segment(T) if( isFloatingPoint!T );`

##### aliases:

- `alias Vector!(3,T,"x y z") vectype`

##### fields:

- `vectype pnt` - start of segment
- `vectype dir` - size and direction

##### properties:

- `ref vectype start()` - return ref to pnt
- `ref const(vectype) start()` - return copy of pnt
- `vectype end() const` - return sum of pnt and dir
- `vectype end( in vectype p )` - sets end point and return it
- `Segment!T revert() const` - swap start and end
- `T len2() const` - return squared length of dir
- `T len() const` - return length of dir

##### static methods:

- `static Segment!T fromPoints( in vectype start, in vectype end )`

##### basic math operations:

 - `seg+seg`
 - `seg-seg`
 - `seg*double`
 - `seg/double`

 implements by `mixin( BasicMathOp!"pnt dir" )`

##### const methods: 

- `Segment!T tr(X)( in Matrix!(4,4,X) mtr )` - apply transform matrix to
  copy and return it

- `Segment!T altitude( in vectype pp )` - altitude from segment line to point
- `Segment!T altitude(F)( in Segment!F seg )` - altitude from `this` segment line
  to `seg` line
- `vectype intersect(F)( in Segment!F seg )` - point of intersection of segments lines as
altitude pnt + dir * 0.5
