module des.util.data.type;

import std.string : format, join;
import std.algorithm;
import std.conv : to;
import std.traits;
import std.math : abs;
import std.exception : enforce;
import des.math.linear.vector;
import des.math.linear.matrix;
import des.math.util.flatdata;
import des.util.testsuite;

/// data types description for untyped `void[]` arrays
enum DataType
{
    RAWBYTE,      /// untyped data `ubyte`
    BYTE,         /// `byte`
    UBYTE,        /// `ubyte`
    NORM_QUART,   /// fixed point quartered [-1,1] `byte`
    UNORM_QUART,  /// fixed point quartered [0,1] `ubyte`

    SHORT,        /// `short`
    USHORT,       /// `ushort`
    NORM_HALF,    /// fixed point half [-1,1] `short`
    UNORM_HALF,   /// fixed point half [0,1] `ushort`

    INT,          /// `int`
    UINT,         /// `uint`
    NORM_FIXED,   /// fixed point [-1,1] `int`
    UNORM_FIXED,  /// fixed point [0,1] `uint`

    LONG,         /// `long`
    ULONG,        /// `ulong`
    NORM_DOUBLE,  /// fixed point double [-1,1] `long`
    UNORM_DOUBLE, /// fixed point double [0,1] `ulong`

    FLOAT,        /// `float`
    DOUBLE        /// `double`
}

/// data types that has direct correspondence with Dlang data types
enum StoreDataType : DataType
{
    BYTE   = DataType.BYTE,  /// `DataType.BYTE`
    UBYTE  = DataType.UBYTE, /// `DataType.UBYTE`

    SHORT  = DataType.SHORT, /// `DataType.SHORT`
    USHORT = DataType.USHORT,/// `DataType.USHORT`

    INT    = DataType.INT,   /// `DataType.INT`
    UINT   = DataType.UINT,  /// `DataType.UINT`

    LONG   = DataType.LONG,  /// `DataType.LONG`
    ULONG  = DataType.ULONG, /// `DataType.ULONG`

    FLOAT  = DataType.FLOAT, /// `DataType.FLOAT`
    DOUBLE = DataType.DOUBLE /// `DataType.DOUBLE`
}

/++
returns associated with type T DataType

* `byte`   = `DataType.BYTE`
* `ubyte`  = `DataType.UBYTE`
* `short`  = `DataType.SHORT`
* `ushort` = `DataType.USHORT`
* `int`    = `DataType.INT`
* `uint`   = `DataType.UINT`
* `long`   = `DataType.LONG`
* `ulong`  = `DataType.ULONG`
* `float`  = `DataType.FLOAT`
* `double` = `DataType.DOUBLE`
* `else`   = `DataType.RAWBYTE`
returns:
    enum DataType
 +/
template assocDataType(T)
{
         static if( is( T == byte ) )   enum assocDataType = DataType.BYTE;
    else static if( is( T == ubyte ) )  enum assocDataType = DataType.UBYTE;
    else static if( is( T == short ) )  enum assocDataType = DataType.SHORT;
    else static if( is( T == ushort ) ) enum assocDataType = DataType.USHORT;
    else static if( is( T == int ) )    enum assocDataType = DataType.INT;
    else static if( is( T == uint ) )   enum assocDataType = DataType.UINT;
    else static if( is( T == long ) )   enum assocDataType = DataType.LONG;
    else static if( is( T == ulong ) )  enum assocDataType = DataType.ULONG;
    else static if( is( T == float ) )  enum assocDataType = DataType.FLOAT;
    else static if( is( T == double ) ) enum assocDataType = DataType.DOUBLE;
    else                                enum assocDataType = DataType.RAWBYTE;
}

/// size of associated data type
size_t dataTypeSize( DataType dt ) pure nothrow @nogc @safe
{
    final switch( dt )
    {
        case DataType.RAWBYTE:
        case DataType.BYTE:
        case DataType.UBYTE:
        case DataType.NORM_QUART:
        case DataType.UNORM_QUART:
            return byte.sizeof;

        case DataType.SHORT:
        case DataType.USHORT:
        case DataType.NORM_HALF:
        case DataType.UNORM_HALF:
            return short.sizeof;

        case DataType.INT:
        case DataType.UINT:
        case DataType.NORM_FIXED:
        case DataType.UNORM_FIXED:
            return int.sizeof;

        case DataType.LONG:
        case DataType.ULONG:
        case DataType.NORM_DOUBLE:
        case DataType.UNORM_DOUBLE:
            return long.sizeof;

        case DataType.FLOAT:
            return float.sizeof;

        case DataType.DOUBLE:
            return double.sizeof;
    }
}

/++
 alias for assocated store type

 * `DataType.RAWBYTE`      = `ubyte`
 * `DataType.BYTE`         = `byte`
 * `DataType.UBYTE`        = `ubyte`
 * `DataType.NORM_QUART`   = `byte`
 * `DataType.UNORM_QUART`  = `ubyte`
 * `DataType.SHORT`        = `short`
 * `DataType.USHORT`       = `ushort`
 * `DataType.NORM_HALF`    = `short`
 * `DataType.UNORM_HALF`   = `ushort`
 * `DataType.INT`          = `int`
 * `DataType.UINT`         = `uint`
 * `DataType.NORM_FIXED`   = `int`
 * `DataType.UNORM_FIXED`  = `uint`
 * `DataType.LONG`         = `long`
 * `DataType.ULONG`        = `ulong`
 * `DataType.NORM_DOUBLE`  = `long`
 * `DataType.UNORM_DOUBLE` = `ulong`
 * `DataType.FLOAT`        = `float`
 * `DataType.DOUBLE`       = `double`

 See_Also:
 [DataType](des/util/data/type/DataType.html)
 +/
template storeDataType( DataType DT )
{
         static if( DT == DataType.RAWBYTE )      alias storeDataType = ubyte;
    else static if( DT == DataType.BYTE )         alias storeDataType = byte;
    else static if( DT == DataType.UBYTE )        alias storeDataType = ubyte;
    else static if( DT == DataType.NORM_QUART )   alias storeDataType = byte;
    else static if( DT == DataType.UNORM_QUART )  alias storeDataType = ubyte;
    else static if( DT == DataType.SHORT )        alias storeDataType = short;
    else static if( DT == DataType.USHORT )       alias storeDataType = ushort;
    else static if( DT == DataType.NORM_HALF )    alias storeDataType = short;
    else static if( DT == DataType.UNORM_HALF )   alias storeDataType = ushort;
    else static if( DT == DataType.INT )          alias storeDataType = int;
    else static if( DT == DataType.UINT )         alias storeDataType = uint;
    else static if( DT == DataType.NORM_FIXED )   alias storeDataType = int;
    else static if( DT == DataType.UNORM_FIXED )  alias storeDataType = uint;
    else static if( DT == DataType.LONG )         alias storeDataType = long;
    else static if( DT == DataType.ULONG )        alias storeDataType = ulong;
    else static if( DT == DataType.NORM_DOUBLE )  alias storeDataType = long;
    else static if( DT == DataType.UNORM_DOUBLE ) alias storeDataType = ulong;
    else static if( DT == DataType.FLOAT )        alias storeDataType = float;
    else static if( DT == DataType.DOUBLE )       alias storeDataType = double;
}

/++
 alias for conformation type

 diff with [storeDataType](des/util/data/type/storeDataType.html):

 * `DataType.NORM_QUART`   = `float`
 * `DataType.UNORM_QUART`  = `float`
 * `DataType.NORM_HALF`    = `float`
 * `DataType.UNORM_HALF`   = `float`
 * `DataType.NORM_FIXED`   = `float`
 * `DataType.UNORM_FIXED`  = `float`
 * `DataType.NORM_DOUBLE`  = `double`
 * `DataType.UNORM_DOUBLE` = `double`

 See_Also:

 * [DataType](des/util/data/type/DataType.html)
 * [storeDataType](des/util/data/type/storeDataType.html):

 +/
template conformDataType( DataType DT )
{
         static if( DT == DataType.RAWBYTE )      alias conformDataType = void;
    else static if( DT == DataType.BYTE )         alias conformDataType = byte;
    else static if( DT == DataType.UBYTE )        alias conformDataType = ubyte;
    else static if( DT == DataType.NORM_QUART )   alias conformDataType = float;
    else static if( DT == DataType.UNORM_QUART )  alias conformDataType = float;
    else static if( DT == DataType.SHORT )        alias conformDataType = short;
    else static if( DT == DataType.USHORT )       alias conformDataType = ushort;
    else static if( DT == DataType.NORM_HALF )    alias conformDataType = float;
    else static if( DT == DataType.UNORM_HALF )   alias conformDataType = float;
    else static if( DT == DataType.INT )          alias conformDataType = int;
    else static if( DT == DataType.UINT )         alias conformDataType = uint;
    else static if( DT == DataType.NORM_FIXED )   alias conformDataType = float;
    else static if( DT == DataType.UNORM_FIXED )  alias conformDataType = float;
    else static if( DT == DataType.LONG )         alias conformDataType = long;
    else static if( DT == DataType.ULONG )        alias conformDataType = ulong;
    else static if( DT == DataType.NORM_DOUBLE )  alias conformDataType = double;
    else static if( DT == DataType.UNORM_DOUBLE ) alias conformDataType = double;
    else static if( DT == DataType.FLOAT )        alias conformDataType = float;
    else static if( DT == DataType.DOUBLE )       alias conformDataType = double;
}

/// check `is( storeDataType!DT == conformDataType!DT )` for DataType DT
template isDirectDataType( DataType DT )
{ enum isDirectDataType = is( storeDataType!DT == conformDataType!DT ); }

unittest
{
    import std.string;

    template F( DataType DT )
    {
        enum F = (storeDataType!DT).sizeof == dataTypeSize(DT);
        static assert( F, format("%s",DT) );
    }

    static assert( F!( DataType.RAWBYTE ) );
    static assert( F!( DataType.BYTE ) );
    static assert( F!( DataType.UBYTE ) );
    static assert( F!( DataType.NORM_QUART ) );
    static assert( F!( DataType.UNORM_QUART ) );
    static assert( F!( DataType.SHORT ) );
    static assert( F!( DataType.USHORT ) );
    static assert( F!( DataType.NORM_HALF ) );
    static assert( F!( DataType.UNORM_HALF ) );
    static assert( F!( DataType.INT ) );
    static assert( F!( DataType.UINT ) );
    static assert( F!( DataType.NORM_FIXED ) );
    static assert( F!( DataType.UNORM_FIXED ) );
    static assert( F!( DataType.LONG ) );
    static assert( F!( DataType.ULONG ) );
    static assert( F!( DataType.NORM_DOUBLE ) );
    static assert( F!( DataType.UNORM_DOUBLE ) );
    static assert( F!( DataType.FLOAT ) );
    static assert( F!( DataType.DOUBLE ) );

    static assert( F!( StoreDataType.BYTE ) );
    static assert( F!( StoreDataType.UBYTE ) );
    static assert( F!( StoreDataType.SHORT ) );
    static assert( F!( StoreDataType.USHORT ) );
    static assert( F!( StoreDataType.INT ) );
    static assert( F!( StoreDataType.UINT ) );
    static assert( F!( StoreDataType.LONG ) );
    static assert( F!( StoreDataType.ULONG ) );
    static assert( F!( StoreDataType.FLOAT ) );
    static assert( F!( StoreDataType.DOUBLE ) );
}

unittest
{
    static assert( !isDirectDataType!( DataType.RAWBYTE ) );
    static assert(  isDirectDataType!( DataType.BYTE ) );
    static assert(  isDirectDataType!( DataType.UBYTE ) );
    static assert( !isDirectDataType!( DataType.NORM_QUART ) );
    static assert( !isDirectDataType!( DataType.UNORM_QUART ) );
    static assert(  isDirectDataType!( DataType.SHORT ) );
    static assert(  isDirectDataType!( DataType.USHORT ) );
    static assert( !isDirectDataType!( DataType.NORM_HALF ) );
    static assert( !isDirectDataType!( DataType.UNORM_HALF ) );
    static assert(  isDirectDataType!( DataType.INT ) );
    static assert(  isDirectDataType!( DataType.UINT ) );
    static assert( !isDirectDataType!( DataType.NORM_FIXED ) );
    static assert( !isDirectDataType!( DataType.UNORM_FIXED ) );
    static assert(  isDirectDataType!( DataType.LONG ) );
    static assert(  isDirectDataType!( DataType.ULONG ) );
    static assert( !isDirectDataType!( DataType.NORM_DOUBLE ) );
    static assert( !isDirectDataType!( DataType.UNORM_DOUBLE ) );
    static assert(  isDirectDataType!( DataType.FLOAT ) );
    static assert(  isDirectDataType!( DataType.DOUBLE ) );

    static assert(  isDirectDataType!( StoreDataType.BYTE ) );
    static assert(  isDirectDataType!( StoreDataType.UBYTE ) );
    static assert(  isDirectDataType!( StoreDataType.SHORT ) );
    static assert(  isDirectDataType!( StoreDataType.USHORT ) );
    static assert(  isDirectDataType!( StoreDataType.INT ) );
    static assert(  isDirectDataType!( StoreDataType.UINT ) );
    static assert(  isDirectDataType!( StoreDataType.LONG ) );
    static assert(  isDirectDataType!( StoreDataType.ULONG ) );
    static assert(  isDirectDataType!( StoreDataType.FLOAT ) );
    static assert(  isDirectDataType!( StoreDataType.DOUBLE ) );
}

/++
 Description for untyped arrays with multidimension elements
 +/
struct ElemInfo
{
    /// count of components in element
    size_t comp = 1;

    /// type of one component
    DataType type = DataType.RAWBYTE;

    invariant() { assert( comp > 0 ); }

    pure @safe nothrow @nogc
    {
        /++ get ElemInfo from type
         +
         + works with:
         + * single numeric
         + * static arrays
         + * static [vector](des/math/linear/vector/Vector.html)
         + * static [matrix](des/math/linear/matrix/Matrix.html)
         +/
        static ElemInfo fromType(T)() @property
            if( !hasIndirections!T )
        {
            static if( isNumeric!T )
                return ElemInfo( 1, assocDataType!T );
            else static if( isStaticArray!T )
                return ElemInfo( T.length, assocDataType!( typeof(T.init[0]) ) );
            else static if( isStaticVector!T )
                return ElemInfo( T.length, assocDataType!( T.datatype ) );
            else static if( isStaticMatrix!T )
                return ElemInfo( T.width * T.height, assocDataType!( T.datatype ) );
            else static assert(0,"unsupported type");
        }

        ///
        unittest
        {
            static assert( ElemInfo.fromType!vec2 == ElemInfo( 2, DataType.FLOAT ) );
            static assert( ElemInfo.fromType!mat4 == ElemInfo( 16, DataType.FLOAT ) );
            static assert( ElemInfo.fromType!(int[2]) == ElemInfo( 2, DataType.INT ) );
            static assert( ElemInfo.fromType!float == ElemInfo( 1, DataType.FLOAT ) );

            static class A{}

            static assert( !__traits(compiles, ElemInfo.fromType!A ) );
            static assert( !__traits(compiles, ElemInfo.fromType!(int[]) ) );
            static assert( !__traits(compiles, ElemInfo.fromType!dvec ) );
        }

        ///
        this( size_t comp, DataType type=DataType.RAWBYTE )
        {
            this.comp = comp;
            this.type = type;
        }

        ///
        this( in ElemInfo ei )
        {
            this.comp = ei.comp;
            this.type = ei.type;
        }

        const @property
        {
            /++ bytes per element
                returns:
                    typeSize * comp
             +/
            size_t bpe() { return typeSize * comp; }

            /// size of component
            size_t typeSize() { return dataTypeSize(type); }
        }
    }
}

///
class DataTypeException : Exception
{
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
struct ArrayData
{
    ///
    size_t size;
    ///
    void* ptr;

    this(T)( size_t size, T* data )
    {
        this.size = size;
        ptr = cast(void*)data;
    }

    this(T)( size_t size, in T* data ) const
    {
        this.size = size;
        ptr = cast(void*)data;
    }
}

///
union AlienArray(T)
{
    ///
    ArrayData raw;
    ///
    T[] arr;
    ///
    alias type=T;
    ///
    alias arr this;
}

///
auto getTypedArray(T,X)( size_t sz, X* addr ) pure nothrow
{
    static if( is( Unqual!(X) == X ) )
        return AlienArray!T( ArrayData( sz, addr ) );
    else
        return const AlienArray!T( const ArrayData( sz, addr ) );
}

///
unittest
{
    float[] buf = [ 1.1f, 2.2, 3.3, 4.4, 5.5 ];
    auto a = getTypedArray!float( 2, cast(void*)(buf.ptr + 1) );
    import std.stdio;
    assert( eq( a, [2.2, 3.3] ) );
    a[0] = 10;
    assert( eq( buf, [1.1, 10, 3.3, 4.4, 5.5] ) );
}

///
unittest
{

    ubyte[] buf = [ 1, 2, 3, 4 ];
    auto a = getTypedArray!void( 4, cast(void*)buf );
    assert( eq( cast(ubyte[])a, buf ) );
}

///
unittest
{
    static struct TT { ubyte val; }

    ubyte[] fnc( in TT[] data ) pure
    { return getTypedArray!ubyte( data.length, data.ptr ).arr.dup; }

    auto tt = [ TT(0), TT(1), TT(3) ];
    assert( eq( fnc( tt ), cast(ubyte[])[0,1,3] ) );
}

///
template convertValue( DataType DT )
{
    auto convertValue(T)( T val ) pure
    {
        alias SDT = storeDataType!DT;

        static if( isDirectDataType!DT )
            return cast(SDT)( val );
        else static if( DT == DataType.RAWBYTE )
            static assert( 0, "can't convert any value to RAWBYTE" );
        else
        {
            static if( isFloatingPoint!T )
            {
                static if( isSigned!SDT )
                {
                    enforce( val >= -1 && val <= 1, "value exceed signed limits [-1,1]" );
                    return cast(SDT)( (val>0?SDT.max:SDT.min) * abs(val) );
                }
                else
                {
                    enforce( val >= 0 && val <= 1, "value exceed unsigned limits [0,1]" );
                    return cast(SDT)( SDT.max * val );
                }
            }
            else static assert(0, "can't convert int value to fixed point value" );
        }
    }
}

///
unittest
{
    static assert( convertValue!(DataType.NORM_FIXED)(1.0)  == int.max );
    static assert( convertValue!(DataType.NORM_FIXED)(0.5)  == int.max/2 );
    static assert( convertValue!(DataType.NORM_FIXED)(0.0)  == 0 );
    static assert( convertValue!(DataType.NORM_FIXED)(-0.5) == int.min/2 );
    static assert( convertValue!(DataType.NORM_FIXED)(-1.0) == int.min );
    static assert( is( typeof( convertValue!(DataType.NORM_FIXED)(1.0) ) == int ) );
}

unittest
{
    static assert( convertValue!(DataType.BYTE)(1) == 1 );
    static assert( is( typeof( convertValue!(DataType.BYTE)(1) ) == byte ) );

    static assert( convertValue!(DataType.FLOAT)(1) == 1 );
    static assert( convertValue!(DataType.FLOAT)(1.1) == 1.1 );
    static assert( is( typeof( convertValue!(DataType.FLOAT)(1) ) == float ) );

    static assert( convertValue!(DataType.UNORM_QUART)(1.0) == ubyte.max );
    static assert( convertValue!(DataType.UNORM_QUART)(0.5) == ubyte.max/2 );
    static assert( convertValue!(DataType.UNORM_QUART)(0.0) == 0 );
    static assert( is( typeof( convertValue!(DataType.UNORM_QUART)(1.0) ) == ubyte ) );

    static assert( convertValue!(DataType.UNORM_HALF)(1.0) == ushort.max );
    static assert( convertValue!(DataType.UNORM_HALF)(0.5) == ushort.max/2 );
    static assert( convertValue!(DataType.UNORM_HALF)(0.0) == 0 );
    static assert( is( typeof( convertValue!(DataType.UNORM_HALF)(1.0) ) == ushort ) );

    static assert( convertValue!(DataType.UNORM_FIXED)(1.0) == uint.max );
    static assert( convertValue!(DataType.UNORM_FIXED)(0.5) == uint.max/2 );
    static assert( convertValue!(DataType.UNORM_FIXED)(0.0) == 0 );
    static assert( is( typeof( convertValue!(DataType.UNORM_FIXED)(1.0) ) == uint ) );

    static assert( convertValue!(DataType.UNORM_DOUBLE)(1.0) == ulong.max );
    static assert( convertValue!(DataType.UNORM_DOUBLE)(0.5) == ulong.max/2 );
    static assert( convertValue!(DataType.UNORM_DOUBLE)(0.0) == 0 );
    static assert( is( typeof( convertValue!(DataType.UNORM_DOUBLE)(1.0) ) == ulong ) );

    static assert( convertValue!(DataType.NORM_QUART)(1.0)  == byte.max );
    static assert( convertValue!(DataType.NORM_QUART)(0.5)  == byte.max/2 );
    static assert( convertValue!(DataType.NORM_QUART)(0.0)  == 0 );
    static assert( convertValue!(DataType.NORM_QUART)(-0.5) == byte.min/2 );
    static assert( convertValue!(DataType.NORM_QUART)(-1.0) == byte.min );
    static assert( is( typeof( convertValue!(DataType.NORM_QUART)(1.0) ) == byte ) );

    static assert( convertValue!(DataType.NORM_HALF)(1.0)  == short.max );
    static assert( convertValue!(DataType.NORM_HALF)(0.5)  == short.max/2 );
    static assert( convertValue!(DataType.NORM_HALF)(0.0)  == 0 );
    static assert( convertValue!(DataType.NORM_HALF)(-0.5) == short.min/2 );
    static assert( convertValue!(DataType.NORM_HALF)(-1.0) == short.min );
    static assert( is( typeof( convertValue!(DataType.NORM_HALF)(1.0) ) == short ) );

    static assert( convertValue!(DataType.NORM_FIXED)(1.0)  == int.max );
    static assert( convertValue!(DataType.NORM_FIXED)(0.5)  == int.max/2 );
    static assert( convertValue!(DataType.NORM_FIXED)(0.0)  == 0 );
    static assert( convertValue!(DataType.NORM_FIXED)(-0.5) == int.min/2 );
    static assert( convertValue!(DataType.NORM_FIXED)(-1.0) == int.min );
    static assert( is( typeof( convertValue!(DataType.NORM_FIXED)(1.0) ) == int ) );

    static assert( convertValue!(DataType.NORM_DOUBLE)(1.0)  == long.max );
    static assert( convertValue!(DataType.NORM_DOUBLE)(0.5)  == long.max/2 );
    static assert( convertValue!(DataType.NORM_DOUBLE)(0.0)  == 0 );
    static assert( convertValue!(DataType.NORM_DOUBLE)(-0.5) == long.min/2 );
    static assert( convertValue!(DataType.NORM_DOUBLE)(-1.0) == long.min );
    static assert( is( typeof( convertValue!(DataType.NORM_DOUBLE)(1.0) ) == long ) );

    assert(  mustExcept({ convertValue!(DataType.NORM_FIXED)(1.1); }) );
    assert( !mustExcept({ convertValue!(DataType.NORM_FIXED)(-0.1); }) );

    assert(  mustExcept({ convertValue!(DataType.UNORM_FIXED)(1.1); }) );
    assert(  mustExcept({ convertValue!(DataType.UNORM_FIXED)(-0.1); }) );
}

/// untyped data assign
void utDataAssign(T...)( in ElemInfo elem, void* buffer, in T vals ) pure
    if( is(typeof(flatData!real(vals))) )
in
{
    assert( buffer !is null );
    assert( elem.comp == flatData!real(vals).length );
}
body
{
    enum fmt = q{
        auto dst = getTypedArray!(storeDataType!(%1$s))( elem.comp, buffer );
        auto src = flatData!real(vals);
        foreach( i, ref t; dst )
            t = convertValue!(%1$s)( src[i] );
    };
    mixin( getSwitchDataType( "elem.type", fmt, ["RAWBYTE": "can't operate RAWBYTE"] ) );
}

///
unittest
{
    float[] buf = [ 1.1, 2.2, 3.3, 4.4, 5.5, 6.6 ];

    utDataAssign( ElemInfo( 3, DataType.FLOAT ), cast(void*)buf.ptr, vec3(8,9,10) );

    assert( eq( buf, [8,9,10,4.4,5.5,6.6] ) );
}

/++
    binary operation between untyped buffers

    Params:
        info = common to all buffers information
        dst = result buffer ptr
        uta = buffer ptr A
        utb = buffer ptr B
 +/
void utDataOp(string op)( in ElemInfo elem, void* dst, void* utb ) pure
if( ( op == "+" || op == "-" || op == "*" || op == "/" ) )
in
{
    assert( dst !is null );
    assert( utb !is null );
}
body
{
    enum fmt = format( q{
        alias SDT = storeDataType!(%%1$s);
        auto ta = getTypedArray!SDT( elem.comp, dst );
        auto tb = getTypedArray!SDT( elem.comp, utb );
        foreach( i, ref r; ta )
            r = cast(SDT)( ta[i] %s tb[i] );
    }, op );
    mixin( getSwitchDataType( "elem.type", fmt, ["RAWBYTE": "can't operate RAWBYTE"] ) );
}

///
unittest
{
    ubyte[] a = [ 10, 20, 30, 40 ];
    ubyte[] b = [ 60, 70, 40, 20 ];

    utDataOp!"+"( ElemInfo( 4, DataType.UNORM_QUART ), a.ptr, b.ptr );

    assert( eq( a, [70,90,70,60] ) );

    utDataOp!"+"( ElemInfo( 2, DataType.UBYTE ), a.ptr, a.ptr + 2 );

    assert( eq( a, [140,150,70,60] ) );
}

/++ generate switch for all DataType elements

Params:
subj = past as `switch( subj )`
fmt = body of all cases past as formated with one argument (DataType) string
except = exception in selected cases

Example:
    enum fmt = q{
        auto dst = getTypedArray!(storeDataType!(%1$s))( info.comp, buffer );
        auto src = flatData!real(vals);
        foreach( i, ref t; dst )
            t = convertValue!(%1$s)( src[i] );
    };
    writeln( genSwitchDataType( "info.type", fmt, ["RAWBYTE": "can't operate RAWBYTE"] ) );

Output like this:

    final switch( info.type ) {
    case DataType.RAWBYTE: throw new DataTypeException( "can't operate RAWBYTE" );
    case DataType.BYTE:
            auto dst = getTypedArray!(storeDataType!(DataType.BYTE))( info.comp, buffer );
            auto src = flatData!real(vals);
            foreach( i, ref t; dst )
                t = convertValue!(DataType.BYTE)( src[i] );
    break;
    case DataType.UBYTE:
            auto dst = getTypedArray!(storeDataType!(DataType.UBYTE))( info.comp, buffer );
            auto src = flatData!real(vals);
            foreach( i, ref t; dst )
                t = convertValue!(DataType.UBYTE)( src[i] );
    break;
    ...
    }
+/
string getSwitchDataType( string subj, string fmt, string[string] except ) pure
{
    string[] ret = [ format( `final switch( %s ) {`, subj ) ];

    auto _type( string dt ) { return "DataType." ~ dt; }
    auto _case( string dt ) { return "case " ~ _type(dt) ~ ": "; }

    auto fmt_case( string dt, string fmt )
    { return _case(dt) ~ "\n" ~ format( fmt, _type(dt) ) ~ "\nbreak;"; }

    auto fmt_except( string dt, string msg )
    { return _case( dt ) ~ format( `throw new DataTypeException( "%s" );`, msg ); }

    foreach( dt; [EnumMembers!DataType].map!(a=>to!string(a)) )
    {
        if( dt in except ) ret ~= fmt_except( dt, except[dt] );
        else ret ~= fmt_case( dt, fmt );
    }

    ret ~= "}";

    return ret.join("\n");
}
