Provides work with segment.

`struct Segment(T) if( isFloatingPoint!T );`

Segment has two vec3: `pnt` and `dir`,

Basic math operations:

 - `seg+seg`
 - `seg-seg`
 - `seg*double`
 - `seg/double`

Segment methods: 

```d
    // apply transform matrix
    Segment!T tr(X)( in Matrix!(4,4,X) mtr ) const;

    Segment!T altitude( in vectype pp ) const;
    Segment!T altitude(F)( in Segment!F seg ) const;
    Segment!T intersect(F)( in Segment!F seg ) const;
```
