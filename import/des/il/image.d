module des.il.image;

import std.exception;

import std.algorithm;
import std.string;
import std.exception;
import std.range;
import std.traits;
import std.conv;

import des.math.linear.vector;
import des.math.util.accessstring;
import des.il.region;
import des.il.util;
import des.util.testsuite;
import des.util.stdext.algorithm;
public import des.util.data.type;

import std.stdio;

///
struct Image
{
    ///
    CrdVector!0 size;
    ///
    ElemInfo info;
    ///
    void[] data;

    invariant()
    {
        enforce( isAllCompPositive( size ) );
        if( data.length > 0 )
            enforce( data.length == expectedDataLength );
    }

pure:

    /// copy ctor
    this(this)
    {
        size = CrdVector!0( size );
        data = data.dup;
    }

    /// from other image
    this( in Image img )
    {
        size = CrdVector!0( img.size );
        info = img.info;
        data = img.data.dup;
    }

    /// from other image
    immutable this( in Image img )
    {
        size = immutable CrdVector!0( img.size );
        info = img.info;
        data = img.data.idup;
    }

    /// from size, element info and data
    this(size_t N,T)( in Vector!(N,T) size, ElemInfo info, in void[] data=[] )
        if( isIntegral!T )
    in { assert( isAllCompPositive(size) ); } body
    {
        this.size = CrdVector!0( size );
        this.info = info;

        if( data.length ) this.data = data.dup;
        else this.data = new void[]( dataSize );
    }

    /// from size, channel count, component type and data
    this(size_t N,T)( in Vector!(N,T) size, size_t ch, DataType type, in void[] data=[] )
        if( isIntegral!T )
    in { assert( isAllCompPositive(size) ); } body
    {
        this.size = CrdVector!0( size );
        this.info = ElemInfo( ch, type );

        if( data.length ) this.data = data.dup;
        else this.data = new void[]( dataSize );
    }

    static
    {
        /// use external memory (not copy)
        auto external(size_t N,T)( in Vector!(N,T) size, ElemInfo info, void[] data )
            if( isIntegral!T )
        in { assert( isAllCompPositive(size) ); } body
        {
            Image ret;
            ret.size = size;
            ret.info = info;
            ret.data = data;
            return ret;
        }

        /// ditto
        auto external(size_t N,T)( in Vector!(N,T) size, size_t ch, DataType type, void[] data )
            if( isIntegral!T )
        in { assert( isAllCompPositive(size) ); } body
        { return external( size, ElemInfo(ch,type), data ); }
    }

    pure const @safe nothrow @property @nogc
    {
        /// image data size
        size_t dataSize() { return pixelCount * info.bpe; }

        ///
        size_t pixelCount()
        {
            size_t sz = 1;
            foreach( v; size.data ) sz *= v;
            return sz;
        }

        size_t dims() { return size.data.length; }
    }

    /// fill data zeros
    void clear()
    {
        if( data ) fill( cast(ubyte[])data, ubyte(0) );
        else data = new void[]( expectedDataLength );
    }

    const @property
    {
        /// get copy of image
        auto dup() { return Image( this ); }

        /// get immutable copy of image
        auto idup() { return immutable(Image)( this ); }
    }

    CrdVector!0 robSize( size_t K ) const
    { return CrdVector!(0).fillOne( K, size, 1 ); }

    ///
    immutable(void[]) dump() const
    {
        return (cast(void[])([size.length]) ~
                cast(void[])(size.data) ~
                cast(void[])([info]) ~ data).idup;
    }

    ///
    static auto load( immutable(void[]) rawdata )
    {
        immutable(void)[] readVals(T)( T* ptr, size_t cnt, immutable(void[]) arr )
        {
            auto data = cast(immutable(T[]))arr[0..T.sizeof*cnt];
            foreach( i, val; data ) *ptr++ = val;
            return arr[T.sizeof*cnt..$];
        }

        size_t dims;
        auto buf = readVals!size_t( &dims, 1, rawdata );

        auto szdata = new coord_t[](dims);
        buf = readVals!coord_t( szdata.ptr, dims, buf );

        auto size = CrdVector!0( szdata );

        ElemInfo info;

        buf = readVals!ElemInfo( &info, 1, buf );

        return Image( size, info, buf );
    }

    /// access to pixel
    ref T pixel(T,C)( in C[] crd... )
        if( isIntegral!C )
    in
    {
        assert( isAllCompPositive(crd), "negative coordinate" );
        assert( all!"a[0]>a[1]"( zip( size.dup, crd.dup ) ), "range violation" );
        assert( crd.length == size.length );
    }
    body
    {
        checkDataType!T;
        return (cast(T[])data)[index(crd)];
    }

    /// ditto
    ref const(T) pixel(T,C)( in C[] crd... ) const
        if( isIntegral!C )
    in
    {
        assert( isAllCompPositive(crd), "negative coordinate" );
        assert( crd.length == size.length );
        assert( all!"a[0]>a[1]"( zip( size.data, crd ) ), "range violation" );
    }
    body
    {
        checkDataType!T;
        return (cast(const(T)[])data)[index(crd)];
    }

    /// ditto
    ref T pixel(T,C,size_t N)( in Vector!(N,C) crd )
        if( isIntegral!C )
    in
    {
        assert( isAllCompPositive(crd), "negative coordinate" );
        assert( crd.length == size.length );
        assert( all!"a[0]>a[1]"( zip( size.data, crd.data.dup ) ), "range violation" );
    }
    body
    {
        checkDataType!T;
        return (cast(T[])data)[index(crd)];
    }

    /// ditto
    ref const(T) pixel(T,C,size_t N)( in Vector!(N,C) crd ) const
        if( isIntegral!C )
    in
    {
        assert( isAllCompPositive(crd), "negative coordinate" );
        assert( crd.length == size.length );
        assert( all!"a[0]>a[1]"( zip( size.data, crd.data.dup ) ), "range violation" );
    }
    body
    {
        checkDataType!T;
        return (cast(const(T)[])data)[index(crd)];
    }

    /// cast data to `T[]`
    @property T[] mapAs(T)()
    {
        checkDataType!T;
        return cast(T[])data;
    }

    /// ditto
    @property const(T)[] mapAs(T)() const
    {
        checkDataType!T;
        return cast(const(T)[])data;
    }

    /// return line index by coordinate
    size_t index(T)( in T[] crd ) const
        if( isIntegral!T )
    in { assert( isAllCompPositive(crd) ); } body
    { return getIndex( size, crd ); }

private:

    void checkDataType(T)() const
    {
        enforce( T.sizeof == info.bpe,
                new ImageException( "access with wrong type" ) );
    }

    size_t expectedDataLength() const @property
    {
        size_t sz = 1;
        foreach( v; size.data ) sz *= v;
        return sz * info.bpe;
    }
}

///
unittest
{
    import std.stdio;
    auto a = Image( ivec2(3,3), 3, DataType.UBYTE );
    assert( a.data.length != 0 );
    assert( eq( a.size, [3,3] ) );
    a.pixel!bvec3(0,0) = bvec3(1,2,3);
    auto b = a;
    assert( b == a );
    assert( eq( b.pixel!bvec3(0,0), bvec3(1,2,3) ) );
    a.pixel!bvec3(1,1) = bvec3(3,4,5);
    assert( b != a );
    assert( b == Image.load( b.dump() ) );
    assert( b == b.dup );
    assert( b.data == b.idup.data.dup );
    a = b;
    assert( b == a );
    assert( a == Image.load( b.dump() ) );
    assert( a == b.dup );
    assert( a.data == b.idup.data.dup );
    auto crd = ivec2(1,2);
    b.pixel!bvec3(crd) = bvec3(5,6,8);
    assert( eq( b.pixel!bvec3(1,2), bvec3(5,6,8) ) );

    b.clear();
    assert( eq( b.pixel!bvec3(1,2), bvec3(0,0,0) ) );
}

///
unittest
{
    auto a = Image( ivec2(3,3), ElemInfo( 1, DataType.UBYTE ), to!(ubyte[])([ 1,2,3,4,5,6,7,8,9 ]) );
    auto b = Image(a);

    assert( a.pixel!ubyte(0,0) == 1 );
    assert( b.pixel!ubyte(0,0) == 1 );
    a.pixel!ubyte(0,0) = 2;
    assert( a.pixel!ubyte(0,0) == 2 );
    assert( b.pixel!ubyte(0,0) == 1 );

    auto c = immutable Image(a);
    assert( c.pixel!ubyte(0,0) == 2 );
}

///
unittest
{
    auto a = Image( ivec!1(3), 1, DataType.UBYTE, to!(ubyte[])([ 1,2,3 ]) );
    assert(  mustExcept!Throwable({ a.pixel!(ubyte)(7) = 0; }) );
    assert( !mustExcept({ a.pixel!(ubyte)(0) = 0; }) );

    assert( a.pixel!ubyte(0) == 0 );

    auto b = Image(a);
    b.size.length = 2;
    b.size[1] = 1;

    assert( b.size[0] == 3 );
    assert( b.size[1] == 1 );

    assert( b.pixel!ubyte(0,0) == 0 );
    assert( b.pixel!ubyte(1,0) == 2 );
    assert( mustExcept!Throwable({ b.pixel!ubyte(1,1) = 2; }) );

    auto c = Image(a);
    c.size.length = 2;
    c.size = ivec2(1,3);

    assert( c.size[0] == 1 );
    assert( c.size[1] == 3 );

    assert( c.pixel!ubyte(0,0) == 0 );
    assert( c.pixel!ubyte(0,1) == 2 );
    assert( mustExcept!Throwable({ c.pixel!ubyte(1,1) = 2; }) );

    c.size = ivec2(2,2);

    assert( c.size[0] == 2 );
    assert( c.size[1] == 2 );
}

///
unittest
{
    auto a = Image( ivec2(3,3), 2, DataType.FLOAT );

    assert( a.index([1,2]) == 7 );
    assert( a.index(ivec2(1,2)) == 7 );

    a.mapAs!(vec2)[a.index([1,2])] = vec2(1,1);
    assert( a.pixel!vec2(1,2) == vec2(1,1) );

    a.pixel!vec2(1,2) = vec2(2,2);
    assert( a.pixel!vec2(1,2) == vec2(2,2) );
}

unittest
{
    vec2 sum( in Image img ) pure
    {
        auto buf = img.mapAs!vec2;
        return reduce!((a,b)=>(a+=b))(vec2(0,0),buf);
    }

    auto a = Image( ivec2(3,3), ElemInfo( 2, DataType.FLOAT ) );

    a.pixel!vec2(0,0) = vec2(1,2);
    a.pixel!vec2(1,2) = vec2(2,2);

    assert( sum(a) == vec2(3,4) );
}

/// use external memory
unittest
{
    float[] data = [ 1.0, 2, 3, 4 ];
    auto img = Image.external( ivec2(2,2), 1, DataType.FLOAT, data );

    img.pixel!float(0,0) = 8.0f;

    assert( data[0] == 8.0f );
}

///
unittest
{
    Image img;
    assert( img.size.length == 0 );
    assert( img.data.length == 0 );

    img.size = ivec2(3,3);
    img.info = ElemInfo( 3, DataType.NORM_FIXED );
    img.clear();

    assert( img.data.length == 27 * float.sizeof );
    assert( img.info.bpe == 3 * float.sizeof );

    img.pixel!vec3(0,1) = vec3( .2,.1,.3 );
    assert( img.pixel!vec3(0,1) == vec3(.2,.1,.3) );

    auto di = Image.load( img.dump() );
    assert( di.size == img.size );
    assert( di.info == img.info );
    assert( di.data == img.data );

    auto ii = immutable(Image)( img );
    assert( ii.size == img.size );
    assert( ii.info == img.info );
    assert( ii.data == img.data );

    assert( ii.pixel!vec3(0,1) == vec3(.2,.1,.3) );

    auto dii = immutable(Image).load( ii.dump() );
    static assert( is( typeof(dii) == Image ) );
    assert( dii.size == img.size );
    assert( dii.info == img.info );
    assert( dii.data == img.data );

    auto dd = ii.dup;
    static assert( is( typeof(dd) == Image ) );
    assert( dd.size == img.size );
    assert( dd.info == img.info );
    assert( dd.data == img.data );

    auto ddi = ii.idup;
    static assert( is( typeof(ddi) == immutable(Image) ) );
    assert( ddi.size == img.size );
    assert( ddi.info == img.info );
    assert( ddi.data == img.data );
}

///
unittest
{
    auto data =
    [
        vec2( 1, 2 ), vec2( 3, 4 ), vec2( 5, 6 ),
        vec2( 7, 8 ), vec2( 9, 1 ), vec2( 1, 2 ),
        vec2( 2, 3 ), vec2( 4, 5 ), vec2( 6, 7 )
    ];

    auto img = Image( ivec2(3,3), 2, DataType.FLOAT, data );

    assert( img.size == ivec2(3,3) );
    assert( img.info.bpe == 2 * float.sizeof );

    assert( img.pixel!vec2(1,1) == vec2(9,1) );
    assert( img.info.type == DataType.FLOAT );

    auto imdata = img.mapAs!vec2;
    assert( data == imdata );

    img.clear();
    assert( img.pixel!vec2(1,1) == vec2(0,0) );

    img.mapAs!(vec2)[] = data[];
    imdata = img.mapAs!vec2;
    assert( data == imdata );

    auto constdata = img.idup.mapAs!vec2;
    assertEq( constdata, imdata );
    assert( is( typeof(constdata) == const(vec2)[] ) );
}

///
unittest
{
    assert( mustExcept({ Image( ivec2(3,3), ElemInfo(3,DataType.UBYTE), [ 1, 2, 3 ] ); }) );

    auto dt = [ vec2(1,0), vec2(0,1) ];
    assert( mustExcept({ Image( ivec2(3,3), 2, DataType.FLOAT, dt ); }) );

    auto img = Image( ivec2(3,3), ElemInfo( 3, DataType.NORM_FIXED ) );
    assert( mustExcept({ auto d = img.mapAs!vec2; }) );

    assert( !mustExcept({ img.pixel!vec3(1,0) = vec3(1,1,1); }) );
    assert(  mustExcept({ img.pixel!vec2(1,0) = vec2(1,1); }) );
    static assert(  !__traits(compiles, { img.pixel!vec3(4,4) = vec3(1,1); }) );
}
