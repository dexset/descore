Module provides struct for working with matrix and some functions and aliases.

```d
struct Matrix(size_t H, size_t W, E);
```

Some functions added depending on type `E`.

Matrix can be dynamic ( `H=0 || W==0` ) and static ( `H>0 && W>0` ).

Matrix data is 2-dim array, static or dynamic depending on
values of H and W. Row-major data layout.

##### aliases:

- `alias Matrix!(H,W,E) selftype`
- `alias E datatype`
- `alias data this`

##### enums:

- `enum isDynamic = H == 0 || W == 0`
- `enum isStatic = H != 0 && W != 0`
- `enum isDynamicHeight = H == 0`
- `enum isStaticHeight = H != 0`
- `enum isDynamicWidth = W == 0`
- `enum isStaticWidth = W != 0`
- `enum isStaticHeightOnly = isStaticHeight && isDynamicWidth`
- `enum isStaticWidthOnly = isStaticWidth && isDynamicHeight`
- `enum isDynamicAll = isDynamicHeight && isDynamicWidth`
- `enum isDynamicOne = isStaticWidthOnly || isStaticHeightOnly`

Static matrix inits by zeros if `isNumeric!datatype` and if `H!=W`,
else if `H==W` matrix inits as identity matrix.

If matrix has static dim it can be initialized such as Vector
(by values, arrays, vectors etc). Result count of elements must be:

- `H*W` if matrix is full static
- `cnt % W == 0` if only width is static
- `cnt % H == 0` if only height is static

If matrix is dynamic in ctor first 2 params is sizes:

```d
this(X...)( size_t iH, size_t iW, in X vals );
```

and `vals` can be values, arrays, vectors, etc.
Count of them must be `iH*iW`.

Matrix can initialize from other matrix if dim sizes is compatible.

```d
    auto fill( in E[] vals... ); // fill data same in ctor
```

If matrix is static and squared or has one dynamic dim it 
can be created with static method `diag`

```d
auto m = mat4.diag(1,2,3); // cyclic filling in diagonal
assert( eq( m, [[1,0,0,0],
                [0,2,0,0],
                [0,0,3,0],
                [0,0,0,1]] ));
```

If matrix has static dim, this static dim sets both as enum and property
```d
    static if( isStaticHeight ) enum height = H;
    else
    {
        @property size_t height() const { return data.length; }
        @property size_t height( size_t nh )
        {
            resize( nh, width );
            return nh;
        }
    }
```

Dynamic matrix has method `void resize( size_t nh, size_t nw )`.

If matrix has one static dim, then proper parameter in method must be
equal to static dim value.

```d
auto m = mat3xD(1,2,3,4,5,6);
m.resize(3,10);
m.resize(5,5); // throw exception
```

All matrix can be expanded by two methods:

```d
    auto expandHeight(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( (bW==W||W==0||bW==0) && is(typeof(E(X.init))) );
    auto expandHeight(X...)( in X vals ) const
        if( is(typeof(Matrix!(1,W,E)(vals))) );
    auto expandWidth(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( (bH==H||H==0||bH==0) && is(typeof(E(X.init))) )
    auto expandWidth(X...)( in X vals ) const
        if( is(typeof(Matrix!(H,1,E)(vals))) );
```

All of them returns dynamic matrix:

```d
auto m = mat3xD(1,2,3,4,5,6);
m.expandHeight( 12,15 ); // -> matDxD
m.expandWidth( 7,8,9 ); // -> mat3xD
```

All matrix can return 1-dim dynamic array from its elements:

```d
assert( eq( mat3xD(1,2,3,4,5,6).asArray, [1,2,3,4,5,6] ) );
```

All matrix can return slice:

```d
    auto sliceHeight( size_t start, size_t count=0 ) const;
    auto sliceWidth( size_t start, size_t count=0 ) const;
```

The return of `slice*` is dynamic matrix with `count = count ? count : height - start` of
lines (rows or columns) from start pos:

```d
auto m = mat3xD(1,2,3,4,5,6);
m.sliceHeight( 1,1 ); // -> matDxD [[3,4]]
m.sliceWidth( 1 ); // -> mat3xD [[4],[5],[6]]
```

All matrixes support rows and cols setting,
and can return one dim matrix from row and cols

```d
auto m = mat3xD(1,2,3,4,5,6);
m.setRow(1,[8,9]); // m -> [[1,2],[8,9],[5,6]]
m.setCol(0,10,10,10); // m -> [[10,2],[10,9],[10,6]] 

auto mr = m.row(0); // mc -> [[10,2]]
auto mc = m.col(0); // mc -> [[10],[10],[10]]
```

Binary operations (`+` and `-`) allowed with compatible matrix
(equal sizes and compatible types for operation).

Other binary operations allowed with matrix and some type only if
operation is valid with matrix element type and input type.
Mul to double for example.

Matrix-matrix, matrix-vector, vector-matrix multiplications implemented of course.
Matrix-vector mul can save vector access string if matrix is squared.

Transposition as `@property auto T() const`.

Floating point and squared matrix has properties:
```d
@property auto det() const; // determinant
@property auto inv() const; // inversion matrix
@property auto rowReduceInv() const; // inversion with row reduce method
```

Only for transform matrix `Matrix!(4,4,float)`
```d
@property auto speedTransformInv() const;
```

Module provides some functions:

```d
Matrix!(3,3,E) quatToMatrix(E)( Vector!(4,E,"i j k a") iq );
Matrix!(4,4,E) quatAndPosToMatrix(A,B,string AS)( in Vector!(4,A,"i j k a") iq, in Vector!(3,B,AS) pos );
```

and some aliases `alias Matrix!(<H>,<W>,<Type>) <T>mat<H>x<W>`

- `<T>` type id, associated with `<Type>` as:

    - NoID : `float`
    - `d`  : `double`
    - `r`  : `real`

- `<H>` - `size_t` - matrix height
- `<W>` - `size_t` - matrix widht
