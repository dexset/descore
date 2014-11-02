Provide simple work with image.

### `enum ComponentType`

Used as label of type of stored data

- `RAWBYTE`
- `BYTE`
- `UBYTE`
- `SHORT`
- `USHORT`
- `INT`
- `UINT`
- `FLOAT`
- `NORM_FLOAT`
- `DOUBLE`
- `NORM_DOUBL`

### `struct PixelType`

Pixel information

##### fiels:

- `ComponentType comp = ComponentType.RAWBYTE` - data type
- `size_t channels = 1` - count of chanels

##### methods:

- `this( ComponentType ict, size_t ch )`
- `this( size_t ch )` - component type setted as `RAWBYTE`

##### const properties:

- `size_t bpp()` - bytes per pixel
- `size_t compSize()` - bytes per channel

### `struct Header`

_Internal_ struct of Image. Contains info of image.

##### fields:

- `PixelType type`
- `imsize_t size`

##### const properties:

- `size_t dataSize()`
- `size_t pixelCount()`

### `struct Image(size_t N) if( N > 0 )`

All methods are pure.

##### aliases: 

if `N<=3`:

- `alias Vector!(N,size_t,"whd"[0..N].spaceSep) imsize_t`
- `alias Vector!(N,size_t,"xyz"[0..N].spaceSep) imcrd_t`
- `alias Vector!(N,ptrdiff_t,"xyz"[0..N].spaceSep) imdiff_t`

else if `N>3`:

- `alias Vector!(N,size_t) imsize_t`
- `alias Vector!(N,size_t) imcrd_t`
- `alias Vector!(N,ptrdiff_t) imdiff_t`

in any case:

- `alias Region!(N,ptrdiff_t) imregion_t`

##### fields:

- `void[] data` - one dim array which can be accessed by
    N-dim indexes (see methods)

##### static methods:

- `Image!N load( immutable(void[]) rawdata )` - load header and data from
  `rawdata` (see method `dump`)

##### ctors:

- `this(this)` - copy
- `this( in Image!N img )`
- `immutable this( in Image!N img )`
- `this( Header hdr, in void[] data=[] )`
- `this( in size_t[N] sz, in PixelType pt, in void[] data=[] )`
- `this(V)( in V v, in PixelType pt, in void[] data=[] ) if( isCompatibleVector!(N,size_t,V) )`
- `this(T)( in size_t[N] sz, in T[] data=[] )`
- `this(V,T)( in V v, in T[] data=[] ) if( isCompatibleVector!(N,size_t,V) )`

if `N>1` image can create from `Image!(N-1)`

`this( in Image!(N-1) img, size_t dim=N-1 )` - `dim` is dimension what replaced by 1,
data copies as is by linear.

##### properties:

- `Image!N dup() const` - duplicate
- `immutable(Image!N) idup() const` - duplicate to immutable object
- `imsize_t size() const` - get image size
- `imsize_t size(V)( in V sz ) if( isCompatibleVector!(N,size_t,V) )` - set image size
- `PixelType type() const` - get image type
- `PixelType type( in PixelType tp )` - set image type
- `auto header() const` - get header

if `N>1` image can be reduce to `Image!(N-1)` by

`@property Image!(N-1) histoConv(size_t K, T)() const if( K < N )` - `K` - dim
in which image be reduced, `T` - type, using for summation of pixels

##### methods:

- `void clear()` - fill data by zeros
- `immutable(void[]) dump() const` - return immutable array what containts
  header and data

- `ref T pixel(T)( in size_t[N] crd... )` - pixel access
- `ref T pixel(T,V)( in V v ) if( isCompatibleVector!(N,size_t,V) )` - dito
- `ref const(T) pixel(T)( in size_t[N] crd... ) const` - dito but const
- `ref const(T) pixel(T,V)( in V v ) const if( isCompatibleVector!(N,size_t,V) )` - dito
- `@property T[] mapAs(T)()` - cast `data` to `T[]` with checking type `T` for
  compatible with stored PixelType
- `@property const(T)[] mapAs(T)() const` - dito
- `Image!N copy(T)( in Region!(N,T) r ) const if( isIntegral!T )` - copy region of image
- `void paste(V)( in V pos, in Image!N im )` - paste image in pos
