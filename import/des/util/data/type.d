module des.util.data.type;

import std.traits;
import des.math.linear.vector;
import des.math.linear.matrix;

///
enum DataType
{
    RAWBYTE,      /// untyped data
    BYTE,         ///
    UBYTE,        ///

    SHORT,        ///
    USHORT,       ///
    NORM_HALF,    /// fixed point half [-1,1]
    UNORM_HALF,   /// fixed point half [0,1]

    INT,          ///
    UINT,         ///
    NORM_FIXED,   /// fixed point [-1,1]
    UNORM_FIXED,  /// fixed point [0,1]

    LONG,         ///
    ULONG,        ///
    NORM_DOUBLE,  /// fixed point double [-1,1]
    UNORM_DOUBLE, /// fixed point double [0,1]

    FLOAT,        ///
    DOUBLE        ///
}

///
enum StoreDataType : DataType
{
    BYTE   = DataType.BYTE,  ///
    UBYTE  = DataType.UBYTE, ///

    SHORT  = DataType.SHORT, ///
    USHORT = DataType.USHORT,///

    INT    = DataType.INT,   ///
    UINT   = DataType.UINT,  ///

    LONG   = DataType.LONG,  ///
    ULONG  = DataType.ULONG, ///

    FLOAT  = DataType.FLOAT, ///
    DOUBLE = DataType.DOUBLE ///
}

///
template getDataType(T)
{
         static if( is( T == byte ) )   enum getDataType = DataType.BYTE;
    else static if( is( T == ubyte ) )  enum getDataType = DataType.UBYTE;
    else static if( is( T == short ) )  enum getDataType = DataType.SHORT;
    else static if( is( T == ushort ) ) enum getDataType = DataType.USHORT;
    else static if( is( T == int ) )    enum getDataType = DataType.INT;
    else static if( is( T == uint ) )   enum getDataType = DataType.UINT;
    else static if( is( T == long ) )   enum getDataType = DataType.LONG;
    else static if( is( T == ulong ) )  enum getDataType = DataType.ULONG;
    else static if( is( T == float ) )  enum getDataType = DataType.FLOAT;
    else static if( is( T == double ) ) enum getDataType = DataType.DOUBLE;
    else enum getDataType = DataType.RAWBYTE;
}

///
size_t dataTypeSize( DataType dt ) pure nothrow @nogc @safe
{
    final switch( dt )
    {
        case DataType.RAWBYTE:
        case DataType.BYTE:
        case DataType.UBYTE:
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

///
template storeDataType( DataType dt )
{
         static if( dt == DataType.RAWBYTE )      alias storeDataType = ubyte;
    else static if( dt == DataType.BYTE )         alias storeDataType = byte;
    else static if( dt == DataType.UBYTE )        alias storeDataType = ubyte;
    else static if( dt == DataType.SHORT )        alias storeDataType = short;
    else static if( dt == DataType.USHORT )       alias storeDataType = ushort;
    else static if( dt == DataType.NORM_HALF )    alias storeDataType = short;
    else static if( dt == DataType.UNORM_HALF )   alias storeDataType = ushort;
    else static if( dt == DataType.INT )          alias storeDataType = int;
    else static if( dt == DataType.UINT )         alias storeDataType = uint;
    else static if( dt == DataType.NORM_FIXED )   alias storeDataType = int;
    else static if( dt == DataType.UNORM_FIXED )  alias storeDataType = uint;
    else static if( dt == DataType.LONG )         alias storeDataType = long;
    else static if( dt == DataType.ULONG )        alias storeDataType = ulong;
    else static if( dt == DataType.NORM_DOUBLE )  alias storeDataType = long;
    else static if( dt == DataType.UNORM_DOUBLE ) alias storeDataType = ulong;
    else static if( dt == DataType.FLOAT )        alias storeDataType = float;
    else static if( dt == DataType.DOUBLE )       alias storeDataType = double;
}

///
template conformDataType( DataType dt )
{
         static if( dt == DataType.RAWBYTE )      alias conformDataType = void;
    else static if( dt == DataType.BYTE )         alias conformDataType = byte;
    else static if( dt == DataType.UBYTE )        alias conformDataType = ubyte;
    else static if( dt == DataType.SHORT )        alias conformDataType = short;
    else static if( dt == DataType.USHORT )       alias conformDataType = ushort;
    else static if( dt == DataType.NORM_HALF )    alias conformDataType = float;
    else static if( dt == DataType.UNORM_HALF )   alias conformDataType = float;
    else static if( dt == DataType.INT )          alias conformDataType = int;
    else static if( dt == DataType.UINT )         alias conformDataType = uint;
    else static if( dt == DataType.NORM_FIXED )   alias conformDataType = float;
    else static if( dt == DataType.UNORM_FIXED )  alias conformDataType = float;
    else static if( dt == DataType.LONG )         alias conformDataType = long;
    else static if( dt == DataType.ULONG )        alias conformDataType = ulong;
    else static if( dt == DataType.NORM_DOUBLE )  alias conformDataType = double;
    else static if( dt == DataType.UNORM_DOUBLE ) alias conformDataType = double;
    else static if( dt == DataType.FLOAT )        alias conformDataType = float;
    else static if( dt == DataType.DOUBLE )       alias conformDataType = double;
}

///
template isDirectDataType( DataType dt )
{ enum isDirectDataType = is( storeDataType!dt == conformDataType!dt ); }

unittest
{
    import std.string;

    template F(DataType dt)
    {
        enum F = (storeDataType!dt).sizeof == dataTypeSize(dt);
        static assert( F, format("%s",dt) );
    }

    static assert( F!( DataType.RAWBYTE ) );
    static assert( F!( DataType.BYTE ) );
    static assert( F!( DataType.UBYTE ) );
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

///
struct ElemInfo
{
    ///
    DataType comp = DataType.RAWBYTE;

    ///
    size_t channels = 1;

    invariant() { assert( channels > 0 ); }

    pure @safe nothrow @nogc
    {

        static ElemInfo fromType(T)() @property
            if( !hasIndirections!T )
        {
            static if( isNumeric!T )
                return ElemInfo( getDataType!T, 1 );
            else static if( isStaticArray!T )
                return ElemInfo( getDataType!( typeof(T.init[0]) ), T.length );
            else static if( isStaticVector!T )
                return ElemInfo( getDataType!( T.datatype ), T.length );
            else static if( isStaticMatrix!T )
                return ElemInfo( getDataType!( T.datatype ), T.width * T.height );
            else static assert(0,"unsupported type");
        }

        ///
        this( DataType ict, size_t ch )
        {
            comp = ict;
            channels = ch;
        }

        ///
        this( size_t ch )
        {
            comp = DataType.RAWBYTE;
            channels = ch;
        }

        const @property
        {
            /// bytes per element
            size_t bpe() { return compSize * channels; }

            /// size of component
            size_t compSize() { return dataTypeSize(comp); }
        }
    }
}

unittest
{
    static assert( ElemInfo.fromType!vec2 == ElemInfo( DataType.FLOAT, 2 ) );
    static assert( ElemInfo.fromType!mat4 == ElemInfo( DataType.FLOAT, 16 ) );
    static assert( ElemInfo.fromType!(int[2]) == ElemInfo( DataType.INT, 2 ) );
    static assert( ElemInfo.fromType!float == ElemInfo( DataType.FLOAT, 1 ) );

    static class A{}

    static assert( !__traits(compiles, ElemInfo.fromType!A ) );
    static assert( !__traits(compiles, ElemInfo.fromType!(int[]) ) );
    static assert( !__traits(compiles, ElemInfo.fromType!dvec ) );
}
