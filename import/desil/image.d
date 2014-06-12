/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desil.image;

import std.exception;

public import desmath.linear.vector;
import desil.rect;

alias vec!(2,size_t,"wh") imsize_t;
alias vec!(2,size_t,"xy") imcrd_t;

enum ImCompType
{
    RAWBYTE,
    UBYTE,
    FLOAT,
    NORM_FLOAT,
    DOUBLE,
    NORM_DOUBLE
}

struct ImageType
{
    pure this( ImCompType ict, size_t ch )
    {
        comp = ict;
        channels = ch;
    }

    pure this( size_t ch )
    {
        comp = ImCompType.RAWBYTE;
        channels = ch;
    }

    ImCompType comp;
    size_t channels;

    @safe pure nothrow size_t bpp() const
    {
        final switch( comp )
        {
            case ImCompType.RAWBYTE: case ImCompType.UBYTE:
                return ubyte.sizeof * channels;

            case ImCompType.FLOAT: case ImCompType.NORM_FLOAT:
                return float.sizeof * channels;

            case ImCompType.DOUBLE: case ImCompType.NORM_DOUBLE:
                return double.sizeof * channels;
        }
    }
}

class ImageException : Exception 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ ) 
    { super( msg, file, line ); } 
}

struct Image
{
    // TODO: сделать приватными поля
    ubyte[] data;
    imsize_t size;
    ImageType type;

    pure
    {
        this(this) { data = data.dup; }
        this( in Image img ) { allocate(img.size, img.type, img.data); }

        this( in imsize_t sz, in ImageType tp, in ubyte[] dt=null )
        { allocate( sz, tp, dt ); }

        this(T)( in imsize_t sz, in T[] dt=null )
        { allocate( sz, dt ); }

        immutable(ubyte[]) serialize() const
        { return ( cast(ubyte[])[size].dup ~ cast(ubyte[])[type].dup ~ data ).idup; }

        static Image deserialize( immutable(ubyte[]) rawdata )
        {
            size_t offset = 0, dsize = imsize_t.sizeof;
            auto imsz = (cast(imsize_t[])rawdata[ offset .. offset + dsize ])[0];
            offset += dsize;
            dsize = ImageType.sizeof;
            auto imtp = (cast(ImageType[])rawdata[ offset .. offset + dsize ])[0];
            offset += dsize;
            return Image( imsz, imtp, rawdata[offset .. $] );
        }

        // TODO под вопросом, нет тестов, desil.access не поддерживает
        void retype( in ImageType tp )
        {
            if( tp.bpp != type.bpp ) throw new ImageException( "retype fails" );
            type = tp;
        }

        void clear() { data = new ubyte[size.w * size.h * type.bpp]; }

        void allocate( in imsize_t sz, in ImageType tp, in ubyte[] dt=null )
        {
            size = sz;
            type = tp;

            if( dt is null || dt.length == 0 ) clear();
            else
            {
                if( dt.length != size.w * size.h * type.bpp )
                    throw new ImageException( "bad data size" );
                data = dt.dup;
            }
        }

        void allocate(T)( in imsize_t sz, in T[] dt=null )
        {
            size = sz;
            type.comp = ImCompType.RAWBYTE;
            type.channels = cast(ubyte)T.sizeof;

            if( dt is null || dt.length == 0 ) clear();
            else
            {
                if( dt.length != size.w * size.h )
                    throw new ImageException( "bad data length" );

                data = cast(ubyte[])dt.dup;
            }
        }

        const @property
        {
            auto dup() { return Image( this ); }
            auto idup() { return immutable(Image)( this ); }
        }

        @property T[] copyData(T)() const
        { 
            if( T.sizeof != type.bpp )
                throw new ImageException( "type size uncompatible with elem size" );
            return cast(T[])data.dup; 
        }

        void set(T)( in T[] dt )
        {
            if( dt.length * T.sizeof != size.w * size.h * type.bpp )
                throw new ImageException( "bad data size" );

            data = cast(ubyte[])dt.dup;
        }

        ref T access(T)( in imcrd_t pos ) { return access!T( pos.x, pos.y ); }
        ref T access(T)( size_t x, size_t y ) 
        { 
            if( T.sizeof != type.bpp )
                throw new ImageException( "type size uncompatible with elem size" );
            if( x >= size.w || y >= size.h )
                throw new ImageException( "out of image size" );

            return (cast(T[])(data))[ size.w * y + x ];
        }

        T read(T)( in imcrd_t pos ) const { return read!T( pos.x, pos.y ); }
        T read(T)( size_t x, size_t y ) const
        {
            if( T.sizeof != type.bpp )
                throw new ImageException( "type size uncompatible with elem size" );
            if( x >= size.w || y >= size.h )
                throw new ImageException( "out of image size" );

            return (cast(T[])(data))[ size.w * y + x ];
        }

        Image copy( in irect r ) const
        {
            auto ret = Image( imsize_t(r.size), this.type );

            auto cr = irect( 0, 0, size ).overlapLocal( r );

            auto rp = cr.pos - r.pos;
            auto op = cr.pos;

            auto opx_s = op.x;
            auto opx_e = op.x + cr.size.x;

            auto rpx_s = rp.x;
            auto rpx_e = rp.x + cr.size.x;

            auto k = type.bpp;

            foreach( uint y; 0 .. cr.size.y )
            {
                auto rpy = rp.y + y;
                auto opy = op.y + y;

                auto rpyy = rpy * r.size.x;
                auto opyy = opy * size.w;

                ret.data[ (rpyy+rpx_s)*k .. (rpyy+rpx_e)*k ] = data[ (opyy+opx_s)*k .. (opyy+opx_e)*k ];
            }
            return ret;
        }

        void paste( in ivec2 pos, in Image im )
        {
            if( im.type != this.type )
                throw new ImageException( "Image type is not good for paste." );

            auto r = irect( pos, im.size );
            auto cr = irect( 0, 0, size ).overlapLocal( r );

            auto rp = cr.pos - r.pos;
            auto op = cr.pos;

            auto opx_s = op.x;
            auto opx_e = op.x + cr.size.x;

            auto rpx_s = rp.x;
            auto rpx_e = rp.x + cr.size.x;

            auto k = type.bpp;

            foreach( uint y; 0 .. cr.size.y )
            {
                auto rpy = rp.y + y;
                auto opy = op.y + y;

                auto rpyy = rpy * r.size.x;
                auto opyy = opy * size.w;
                data[ (opyy+opx_s)*k .. (opyy+opx_e)*k ] = im.data[ (rpyy+rpx_s)*k .. (rpyy+rpx_e)*k ];
            }
        }
    }
}

unittest
{
    Image img;
    assert( img.data is null );
    assert( img.size == imsize_t(0,0) );

    img.allocate( imsize_t(3,3), ImageType( ImCompType.NORM_FLOAT, 3 ) );
    assert( img.data.length == 27 * float.sizeof );
    assert( img.type.bpp == 3 * float.sizeof );
    img.access!col3( 0,1 ) = col3( 1,0,0.4 );
    assert( img.read!vec3(0,1) == vec3(1,0,0.4) );

    img.access!vec3( 1,0 ) = col3( .2,.1,.3 );
    assert( img.read!vec3(1,0) == vec3(.2,.1,.3) );

    auto di = Image.deserialize( img.serialize );
    assert( di.size == img.size );
    assert( di.type == img.type );
    assert( di.data == img.data );

    auto ii = immutable(Image)( img );
    assert( ii.size == img.size );
    assert( ii.type == img.type );
    assert( ii.data == img.data );

    assert( !__traits( compiles, ii.access!vec3(1,0) ) );
    assert( __traits( compiles, ii.read!vec3(1,0) ) );
    assert( ii.read!vec3(1,0) == vec3(.2,.1,.3) );

    auto dii = immutable(Image).deserialize( ii.serialize );
    static assert( is( typeof(dii) == Image ) );
    assert( dii.size == img.size );
    assert( dii.type == img.type );
    assert( dii.data == img.data );

    auto dd = ii.dup;
    static assert( is( typeof(dd) == Image ) );
    assert( dd.size == img.size );
    assert( dd.type == img.type );
    assert( dd.data == img.data );

    auto ddi = ii.idup;
    static assert( is( typeof(ddi) == immutable(Image) ) );
    assert( ddi.size == img.size );
    assert( ddi.type == img.type );
    assert( ddi.data == img.data );
}

unittest
{
    Image img;
    img.allocate!vec3( imsize_t(3,3) );
    assert( img.data.length == float.sizeof * 3 * 9 );
}

unittest 
{
    ubyte[] data = 
    [
        2, 1, 3, 5, 2,
        9, 1, 2, 6, 0,
        2, 5, 2, 9, 1,
        8, 3, 6, 3, 0,
        6, 2, 8, 1, 5 
    ];

    ubyte[] datav1 =
    [
        0, 0, 0, 0, 0, 0, 0, 
        0, 2, 1, 3, 5, 2, 0,
        0, 9, 1, 2, 6, 0, 0,
        0, 2, 5, 2, 9, 1, 0,
        0, 8, 3, 6, 3, 0, 0,
        0, 6, 2, 8, 1, 5, 0,
        0, 0, 0, 0, 0, 0, 0 
    ];

    ubyte[] datav2 = 
    [
        1, 2, 6,
        5, 2, 9,
        3, 6, 3
    ];

    ubyte[] datav3 =
    [
        0, 0, 0, 0,
        0, 2, 1, 3,
        0, 9, 1, 2,
        0, 2, 5, 2
    ];

    ubyte[] datav4 =
    [
        0, 0, 0, 0, 
        3, 5, 2, 0,
        2, 6, 0, 0,
        2, 9, 1, 0
    ];

    ubyte[] datav5 =
    [
        0, 2, 5, 2,
        0, 8, 3, 6,
        0, 6, 2, 8,
        0, 0, 0, 0
    ];

    ubyte[] datav6 =
    [
        2, 9, 1, 0,
        6, 3, 0, 0,
        8, 1, 5, 0,
        0, 0, 0, 0 
    ];

    auto orig = Image( imsize_t( 5, 5 ), data );
    auto im = orig.copy( irect( 0, 0, 5, 5 ) );
    assert( orig == im );
    
    auto imv1 = Image( imsize_t( 7, 7 ), datav1 );
    assert( orig.copy( irect( -1, -1, 7, 7 ) ) == imv1 );

    auto imv2 = Image( imsize_t( 3, 3 ), datav2 );
    assert( orig.copy( irect( 1, 1, 3, 3 ) ) == imv2 );

    auto imv3 = Image( imsize_t( 4, 4 ), datav3 );
    assert( orig.copy( irect( -1, -1, 4, 4 ) ) == imv3 );

    auto imv4 = Image( imsize_t( 4, 4 ), datav4 );
    assert( orig.copy( irect( 2, -1, 4, 4 ) ) == imv4 );

    auto imv5 = Image( imsize_t( 4, 4 ), datav5 );
    assert( orig.copy( irect( -1, 2, 4, 4 ) ) == imv5 );

    auto imv6 = Image( imsize_t( 4, 4 ), datav6 );
    assert( orig.copy( irect( 2, 2, 4, 4 ) ) == imv6 );
}

unittest 
{
    ubyte[] data = 
    [
        2, 1, 3, 5, 2,
        9, 1, 2, 6, 0,
        2, 5, 2, 9, 1,
        8, 3, 6, 3, 0,
        6, 2, 8, 1, 5 
    ];

    ubyte[] datav1 = 
    [
        1, 2, 6, 0, 0, 0, 0,
        5, 2, 9, 1, 0, 0, 0,
        3, 6, 3, 0, 0, 0, 0,
        2, 8, 1, 5, 0, 0, 0,  
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0
    ];

    ubyte[] datav2 = 
    [
        0, 0, 0, 0, 0, 0, 0,
        0, 2, 1, 3, 5, 2, 0,
        0, 9, 1, 2, 6, 0, 0,
        0, 2, 5, 2, 9, 1, 0,  
        0, 8, 3, 6, 3, 0, 0,
        0, 6, 2, 8, 1, 5, 0,
        0, 0, 0, 0, 0, 0, 0
    ];


    auto orig = Image( imsize_t( 7, 7 ), ImageType( ImCompType.RAWBYTE, 1 ) );
    auto im = Image( imsize_t( 5, 5 ), data );

    auto res = Image(orig);
    res.paste( ivec2(-1,-1), im );
    assert( res.data == datav1 );

    res = Image(orig);
    res.paste( ivec2(1,1), im );
    assert( res.data == datav2 );
}

unittest
{
    auto data = 
    [
        vec2( 1, 2 ), vec2( 3, 4 ), vec2( 5, 6 ),
        vec2( 7, 8 ), vec2( 9, 0 ), vec2( 1, 2 ),
        vec2( 2, 3 ), vec2( 4, 5 ), vec2( 6, 7 )
    ];

    auto img = Image( imsize_t(3,3), data );

    assert( img.size == imsize_t(3,3) );
    assert( img.type.bpp == 2 * float.sizeof );

    assert( img.read!vec2(1,1) == vec2(9,0) );
    assert( img.type.comp == ImCompType.RAWBYTE );

    auto imdata = img.copyData!vec2;
    assert( data == imdata );

    img.clear();
    assert( img.read!vec2(1,1) == vec2(0,0) );

    img.set( data );
    imdata = img.copyData!vec2;
    assert( data == imdata );

    auto constdata = img.idup.copyData!vec2;
    assert( constdata == imdata );
    assert( is( typeof(constdata) == vec2[] ) );
}

unittest
{
    void test(uint LINE=__LINE__)( void delegate() exceptionFunc, string msg )
    {
        bool except = false;
        try exceptionFunc();
        catch( ImageException ie )
        {
            assert( ie.msg == msg );
            except = true;
        }
        import std.string;
        assert( except, format( "exceptionFunc not throw exception (line %d)", LINE ) );
    }

    test({ Image( imsize_t(3,3), ImageType( ImCompType.UBYTE, 3 ), [ 1, 2, 3 ] ); }, "bad data size" );

    auto dt = [ vec2(1,0), vec2(0,1) ];
    test({ Image( imsize_t(3,3), dt ); }, "bad data length" );

    auto img = Image( imsize_t(3,3), ImageType( ImCompType.NORM_FLOAT, 3 ) );
    test({ auto d = img.copyData!vec2; }, "type size uncompatible with elem size" );
    test({ img.set( dt ); }, "bad data size" );

    alias vec!(3,ubyte,"rgb") bcol3;
    test({ img.access!bcol3( 1, 0 ); }, "type size uncompatible with elem size" );
    test({ img.read!bcol3( 1, 0 ); }, "type size uncompatible with elem size" );

    test({ img.access!vec3( 5, 5 ); }, "out of image size" );
    test({ img.read!col3( 1, 4 ); },   "out of image size" );
}
