Provides work with triangle.

#### `struct Triangle(T) if( isFloatingPoint!T )`

##### aliases: 

- `alias Vector!(3,T,"x y z") vectype`

##### fields:

- `vectype[3] pnt`

##### const properties:

- `vectype perp()` - perpendicular calced as cross mul
    of segments [p0 to p1] and [p0 to p2]
- `vectype norm()` - `perp.e`
- `T area()` - `perp.len / 2` - area of triangle
- `vectype center()` - center point

##### const methods:

- `Triangle!T tr(X)( in Matrix!(4,4,X) mtr )` - transform all 3 points of
    triangle with transform matrix `mtr`

- `Segment!(T)[3] toSegments()` -- return segments
    [p0 to p1], [p1 to p2], [p2 to p0]

- `Segment!T altitude( in vectype pp )` - return altitude to
    point from triangle plane

- `Segment!T project(F)( in Segment!F seg )` - return projection of
    `seg` to triangle plane

- `vectype intersect(F)( in Segment!F seg )` - return interseciont
    of `seg` with triangle plane
