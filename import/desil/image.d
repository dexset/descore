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
import desil.region;
import std.algorithm;
import std.string;
import std.exception;
import std.range;
import std.traits;

enum ComponentType
{
    BYTE,
    UBYTE,
    RAWBYTE,

    SHORT,
    USHORT,

    INT,
    UINT,

    FLOAT,
    NORM_FLOAT,

    DOUBLE,
    NORM_DOUBLE
}

struct PixelType
{
    pure this( ComponentType ict, size_t ch )
    {
        comp = ict;
        channels = ch;
    }

    pure this( size_t ch )
    {
        comp = ComponentType.RAWBYTE;
        channels = ch;
    }

    ComponentType comp;
    size_t channels;

    @safe pure nothrow size_t bpp() const
    {
        final switch( comp )
        {
            case ComponentType.BYTE:
            case ComponentType.UBYTE:
            case ComponentType.RAWBYTE:
                return byte.sizeof * channels;

            case ComponentType.SHORT:
            case ComponentType.USHORT:
                return short.sizeof * channels;

            case ComponentType.INT:
            case ComponentType.UINT:
                return int.sizeof * channels;

            case ComponentType.FLOAT:
            case ComponentType.NORM_FLOAT:
                return float.sizeof * channels;

            case ComponentType.DOUBLE:
            case ComponentType.NORM_DOUBLE:
                return double.sizeof * channels;
        }
    }
}

class ImageException : Exception 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ ) 
    { super( msg, file, line ); } 
}

struct Image(size_t N) if( N > 0 )
{
    alias Image!N selftype;

    /+
    static if( N < 4 )
    {
        alias vec!(N,size_t,"whd"[0..N]) imsize_t;
        alias vec!(N,size_t,"xyz"[0..N]) imcrd_t;
        alias vec!(N,ptrdiff_t,"xyz"[0..N]) imdiff_t;
    }
    else
    {
        alias vec!(N,size_t) imsize_t;
        alias vec!(N,size_t) imcrd_t;
        alias vec!(N,ptrdiff_t) imdiff_t;
    }
    +/

    alias vec!(N,size_t,N<4?("whd"[0..N]):"") imsize_t;
    alias vec!(N,size_t,N<4?("xyz"[0..N]):"") imcrd_t;
    alias vec!(N,ptrdiff_t,N<4?("xyz"[0..N]):"") imdiff_t;

    alias region!(N,ptrdiff_t) imregion_t;

    void[] data;
    imsize_t size;
    PixelType type;

    pure
    {
        this(this) { data = data.dup; }
        this( in Image img ) { allocate(img.size, img.type, img.data); }

        this(V)( in V sz, in PixelType tp, in void[] dt=null )
            if( isCompVector!(N,size_t,V) )
        { allocate( sz, tp, dt ); }

        this(V,T)( in V sz, in T[] dt=null )
            if( isCompVector!(N,size_t,V) )
        { allocate( sz, dt ); }

        immutable(void[]) serialize() const
        { return ( cast(void[])[size].dup ~ cast(void[])[type].dup ~ data ).idup; }

        static Image deserialize( immutable(void[]) rawdata )
        {
            size_t offset = 0, dsize = imsize_t.sizeof;
            auto imsz = (cast(imsize_t[])rawdata[ offset .. offset + dsize ])[0];
            offset += dsize;
            dsize = PixelType.sizeof;
            auto imtp = (cast(PixelType[])rawdata[ offset .. offset + dsize ])[0];
            offset += dsize;
            return Image( imsz, imtp, rawdata[offset .. $] );
        }

        // TODO под вопросом, нет тестов, desil.access не поддерживает
        void retype( in PixelType ntp )
        {
            if( ntp.bpp != type.bpp )
                throw new ImageException( "retype fails" );
            type = ntp;
        }

        @property size_t pixelCount() const
        { return reduce!((a,b)=>(a*=b))(1UL,size.data); }

        void resize(V)( in V sz ) if( isCompVector!(N,size_t,V) )
        in
        {
            enforce( all!"a>0"(sz.data.dup), new ImageException( "resize components must be > 0" ) );
        }
        body
        {
            if( size != sz )
            {
                size = sz;
                data = new void[](pixelCount * type.bpp);
            }
        }

        void clear() { fill( cast(ubyte[])data, cast(ubyte)0 ); }

        void allocate(V)( in V sz, in PixelType tp, in void[] dt=[] )
            if( isCompVector!(N,size_t,V) )
        {
            type = tp;
            resize( sz );

            if( dt is null || dt.length == 0 ) clear();
            else
            {
                if( dt.length != pixelCount * type.bpp )
                    throw new ImageException( "bad data size" );
                data = dt.dup;
            }
        }

        void allocate(T,V)( in V sz, in T[] dt=[] )
            if( isCompVector!(N,size_t,V) )
        { allocate( sz, PixelType( cast(ubyte)T.sizeof ), cast(void[])dt ); }

        const @property
        {
            auto dup() { return selftype( this ); }
            auto idup() { return immutable(selftype)( this ); }
        }

        @property T[] mapAs(T)()
        {
            if( T.sizeof != type.bpp )
                throw new ImageException( "type size uncompatible with elem size" );
            return cast(T[])data; 
        }

        @property const(T)[] mapAs(T)() const
        {
            if( T.sizeof != type.bpp )
                throw new ImageException( "type size uncompatible with elem size" );
            return cast(const(T)[])data; 
        }

        size_t index( size_t[N] crd... ) const { return indexCalc( size.data, crd ); }

        size_t index(V)( in V crd ) const if( isCompVector!(N,size_t,V) )
        in
        {
            enforce( all!"a>=0"(crd.data.dup),
                    new ImageException( "index components must be > 0" ) );

            enforce( all!"a[0]<a[1]"(zip(crd.data.dup,size.data.dup)),
                    new ImageException( format( "index out of range => index:%s, size:%s", crd.data, size.data ) ) );
        }
        body { return index( cast(size_t[N])(array(map!(a=>cast(size_t)a)(crd.data.dup))[0..N]) ); }

        static size_t indexCalc( size_t[N] imsize, size_t[N] crd )
        {
            size_t ret;
            foreach( i; 0 .. N )
            {
                auto v = reduce!((a,b)=>(a*=b))(1,imsize[0..i]);
                ret += crd[i] * v;
            }
            return ret;
        }

        @property auto opDispatch(string method)() 
            if( method.split("_")[0] == "pixel" )
        {
            enum dtype = method.split("_")[1..$].join("_");
            mixin( checkTypeSize( dtype ) );
            mixin( pixelAccessorString( dtype ) );
            return PixelAccessor( data, size );
        }

        @property auto opDispatch(string method)() const
            if( method.split("_")[0] == "pixel" )
        {
            enum dtype = method.split("_")[1..$].join("_");
            mixin( checkTypeSize( dtype ) );
            mixin( pixelAccessorString( dtype, true ) );
            return PixelAccessor( data, size );
        }

        private static string checkTypeSize( string type )
        {
            return format( `if( %s.sizeof != type.bpp )
                throw new ImageException( "type size uncompatible with elem size" );
                    `, type );
        }

        private static string pixelAccessorString( string type, bool isconst=false )
        {
            string t1,t2,t3;

            if(isconst) { t1 = "const("; t2 = ")"; t3 = "const"; }

            return format(`
            struct PixelAccessor
            {
                %2$svoid%3$s[] data;
                imsize_t size;

                ref %2$s%1$s%3$s opIndex( size_t[N] crd... ) %4$s
                { return (cast(%2$s%1$s%3$s[])data)[indexCalc(size.data,crd)]; }

                ref %2$s%1$s%3$s opIndex(V)( in V crd ) %4$s
                if( isCompVector!(N,size_t,V) )
                { return opIndex( array(map!(a=>cast(size_t)(a))(crd.data) ) ); }
            }`, type, t1, t2, t3 );
        }

    // TODO (
    }

    public
    {
    // REMOVE )

        auto copy(T)( in region!(N,T) r ) const if( isIntegral!T )
        {
            auto ret = selftype( imsize_t(r.size), this.type );

            auto crop = imregion_t( imsize_t(), size ).overlapLocal( r );
            auto bpp = type.bpp;

            auto line_size = crop.size[0];

            enum fbody = `
                auto pp = ind - r.pos;
                if( all!"a[0]>=0&&a[0]<a[1]"(zip(pp.data.dup,ret.size.data.dup)) )
                {
                    auto o1 = index(ind);
                    auto a = o1 * bpp;
                    auto b = (o1 + line_size) * bpp;
                    auto o2 = ret.index(pp);
                    auto c = o2 * bpp;
                    auto d = (o2 + line_size) * bpp;
                    ret.data[c..d] = data[a..b];
                }
            `;
            mixin( indexForeachString( "crop.pos", "crop.lim", "ind", fbody, 0 ) );

            return ret;
        }

        void paste(V)( in V pos, in Image!N im )
            if( isCompVector!(N,size_t,V) )
        {
            if( im.type != this.type )
                throw new ImageException( "Image type is not good for paste." );

            auto crop = imregion_t( imregion_t.ptype.init, size ).overlapLocal( imregion_t(pos,im.size) );

            auto bpp = type.bpp;

            auto line_size = crop.size[0];

            enum fbody = `
                auto pp = ind - pos;
                if( all!"a[0]>=0&&a[0]<a[1]"(zip(pp.data.dup,im.size.data.dup)) )
                {
                    auto o1 = index(ind);
                    auto a = o1 * bpp;
                    auto b = (o1 + line_size) * bpp;
                    auto o2 = im.index(pp);
                    auto c = o2 * bpp;
                    auto d = (o2 + line_size) * bpp;
                    data[a..b] = im.data[c..d];
                }
                `;
            mixin( indexForeachString( "crop.pos", "crop.lim", "ind", fbody, 0 ) );
        }

        private static string indexForeachString( string start, string end,
                                  string ind, string fbody, size_t[] without... )
        {
            string[] ret;

            ret ~= format( `vec!(N,size_t) %s = %s;`, ind, start );

            foreach( i; 0 .. N )
            {
                if( canFind(without,i) ) continue;
                ret ~= format( `for( %2$s[%1$d] = %3$s[%1$d]; %2$s[%1$d] < %4$s[%1$d]; %2$s[%1$d]++ ){`, 
                                      i, ind, start, end );
            }

            ret ~= fbody;

            foreach( i; 0 .. N )
            {
                if( canFind(without,i) ) continue;
                ret ~= "}";
            }

            return ret.join("\n");
        }


        static if( N > 1 )
        {
            @property Image!(N-1) histoConv(size_t K,T)() const if( K < N )
            {
                if( T.sizeof != type.bpp )
                    throw new ImageException( "type size uncompatible with elem size" );
                
                vec!(N-1,size_t) ret_size;
                foreach( i; 0 .. N )
                    if( i != K )
                        ret_size[i-cast(size_t)(i>K)] = size[i];

                auto ret = Image!(N-1)( ret_size, type );

                enum fbody = `

                    vec!(N-1,size_t) rind;
                    foreach( i; 0 .. N ) if( i != K )
                        rind[i-cast(size_t)(i>K)] = ind[i];

                    for( ind[K] = 0; ind[K] < size[K]; ind[K]++ )
                        ret.mapAs!(T)[ret.index(rind)] += mapAs!(T)[index(ind)];
                    `;
                mixin( indexForeachString( "vec!(N,size_t).init", "size", "ind", fbody, K ) );

                return ret;
            }
        }
    }
}

alias Image!1 Image1d;
alias Image!2 Image2d;
alias Image!3 Image3d;

unittest
{
    auto a = Image1d(vec!(1,size_t)(5), PixelType(ComponentType.FLOAT,2));
    a.opDispatch!("pixel_vec2")[3] = vec2(1,1);
    a.pixel_vec2[4] = vec2(2,2);
    auto b = a.copy( Image1d.imregion_t(3,2) );
    assert( b.pixel_vec2[0] == a.pixel_vec2[3] );
    assert( b.pixel_vec2[1] == a.pixel_vec2[4] );
}

unittest
{
    auto a = Image2d(ivec2(3,3),PixelType(ComponentType.FLOAT,2));

    assert( a.index(1,2) == 7 );
    assert( a.index(ivec2(1,2)) == 7 );

    a.mapAs!(vec2)[a.index(1,2)] = vec2(1,1);
    assert( a.opDispatch!"pixel_vec2"[1,2] == vec2(1,1) );

    a.pixel_vec2[1,2] = vec2(2,2);
    assert( a.pixel_vec2[1,2] == vec2(2,2) );
}

unittest
{
    auto a = Image3d(ivec3(3,3,3),PixelType(ComponentType.FLOAT,2));

    assert( a.index(1,2,1) == 16 );

    a.mapAs!(vec2)[a.index(1,2,1)] = vec2(1,1);
    assert( a.pixel_vec2[1,2,1] == vec2(1,1) );

    a.pixel_vec2[1,2,1] = vec2(2,2);
    assert( a.pixel_vec2[1,2,1] == vec2(2,2) );

    auto b = a.copy( a.imregion_t(1,2,1,1,1,1) );
    assert( b.pixel_vec2[0,0,0] == vec2(2,2) );
}

unittest
{
    pure vec2 sum( in Image2d img )
    {
        auto buf = img.mapAs!vec2;
        return reduce!((a,b)=>(a+=b))(vec2(0,0),buf);
    }

    auto a = Image2d(ivec2(3,3),PixelType(ComponentType.FLOAT,2));

    a.pixel_vec2[0,0] = vec2(1,2);
    a.pixel_vec2[1,2] = vec2(2,2);

    assert( sum(a) == vec2(3,4) );
}

unittest
{
    Image2d img;
    assert( img.data is null );
    assert( img.size == Image2d.imsize_t(0,0) );

    img.allocate( ivec2(3,3), PixelType( ComponentType.NORM_FLOAT, 3 ) );

    assert( img.data.length == 27 * float.sizeof );
    assert( img.type.bpp == 3 * float.sizeof );

    img.pixel_col3[0,1] = col3( .2,.1,.3 );
    assert( img.pixel_vec3[0,1] == vec3(.2,.1,.3) );

    auto di = Image2d.deserialize( img.serialize );
    assert( di.size == img.size );
    assert( di.type == img.type );
    assert( di.data == img.data );

    auto ii = immutable(Image2d)( img );
    assert( ii.size == img.size );
    assert( ii.type == img.type );
    assert( ii.data == img.data );

    assert( ii.opDispatch!"pixel_vec3"[0,1] == vec3(.2,.1,.3) );

    auto dii = immutable(Image2d).deserialize( ii.serialize );
    static assert( is( typeof(dii) == Image2d ) );
    assert( dii.size == img.size );
    assert( dii.type == img.type );
    assert( dii.data == img.data );

    auto dd = ii.dup;
    static assert( is( typeof(dd) == Image2d ) );
    assert( dd.size == img.size );
    assert( dd.type == img.type );
    assert( dd.data == img.data );

    auto ddi = ii.idup;
    static assert( is( typeof(ddi) == immutable(Image2d) ) );
    assert( ddi.size == img.size );
    assert( ddi.type == img.type );
    assert( ddi.data == img.data );
}

unittest
{
    Image2d img;
    img.allocate!vec3( Image2d.imsize_t(3,3) );
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

    auto orig = Image2d( ivec2( 5, 5 ), data );
    auto im = orig.copy( iregion2d( 0, 0, 5, 5 ) );
    assert( orig == im );
    
    auto imv1 = Image2d( ivec2( 7, 7 ), datav1 );
    assert( orig.copy( iregion2d( -1, -1, 7, 7 ) ) == imv1 );

    auto imv2 = Image2d( ivec2( 3, 3 ), datav2 );
    assert( orig.copy( iregion2d( 1, 1, 3, 3 ) ) == imv2 );

    auto imv3 = Image2d( ivec2( 4, 4 ), datav3 );
    assert( orig.copy( iregion2d( -1, -1, 4, 4 ) ) == imv3 );

    auto imv4 = Image2d( ivec2( 4, 4 ), datav4 );
    assert( orig.copy( iregion2d( 2, -1, 4, 4 ) ) == imv4 );

    auto imv5 = Image2d( ivec2( 4, 4 ), datav5 );
    assert( orig.copy( iregion2d( -1, 2, 4, 4 ) ) == imv5 );

    auto imv6 = Image2d( ivec2( 4, 4 ), datav6 );
    assert( orig.copy( iregion2d( 2, 2, 4, 4 ) ) == imv6 );
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


    auto orig = Image2d( ivec2( 7, 7 ), PixelType( ComponentType.RAWBYTE, 1 ) );
    auto im = Image2d( ivec2( 5, 5 ), data );

    auto res = Image2d(orig);
    res.paste( ivec2(-1,-1), im );
    assert( res.data == datav1 );

    res = Image2d(orig);
    res.paste( ivec2(1,1), im );
    assert( res.data == datav2 );
}

unittest
{
    auto data = 
    [
        vec2( 1, 2 ), vec2( 3, 4 ), vec2( 5, 6 ),
        vec2( 7, 8 ), vec2( 9, 1 ), vec2( 1, 2 ),
        vec2( 2, 3 ), vec2( 4, 5 ), vec2( 6, 7 )
    ];

    auto img = Image2d( ivec2(3,3), data );

    assert( img.size == ivec2(3,3) );
    assert( img.type.bpp == 2 * float.sizeof );

    assert( img.pixel_vec2[1,1] == vec2(9,1) );
    assert( img.type.comp == ComponentType.RAWBYTE );

    auto imdata = img.mapAs!vec2;
    assert( data == imdata );

    img.clear();
    assert( img.pixel_vec2[1,1] == vec2(0,0) );

    img.mapAs!(vec2)[] = data[];
    imdata = img.mapAs!vec2;
    assert( data == imdata );

    auto constdata = img.idup.mapAs!vec2;
    assert( constdata == imdata );
    assert( is( typeof(constdata) == const(vec2)[] ) );
}

unittest
{
    void test(uint LINE=__LINE__)( void delegate() exceptionFunc, string msg )
    {
        bool except = false;
        try exceptionFunc();
        catch( ImageException ie )
        {
            except = true;
        }
        import std.string;
        assert( except, format( "exceptionFunc not throw exception (line %d)", LINE ) );
    }

    test({ Image2d( ivec2(3,3), PixelType( ComponentType.UBYTE, 3 ), [ 1, 2, 3 ] ); }, "bad data size" );

    auto dt = [ vec2(1,0), vec2(0,1) ];
    test({ Image2d( ivec2(3,3), dt ); }, "bad data length" );

    auto img = Image2d( ivec2(3,3), PixelType( ComponentType.NORM_FLOAT, 3 ) );
    test({ auto d = img.mapAs!vec2; }, "type size uncompatible with elem size" );

    alias vec!(3,ubyte,"rgb") bcol3;
    test({ img.pixel_bcol3[ 1, 0 ] = bcol3(1,1,1); }, "type size uncompatible with elem size" );

    //test({ img.pixel_vec3[ 5, 5 ]; }, "out of image size" );
    //test({ img.pixel_col3[ 1, 4 ]; }, "out of image size" );
}

unittest
{
    ubyte[] dt =
        [
        0,0,0,0,
        0,0,0,0,
        0,0,0,0,
        0,0,0,0,
        
        0,0,0,0,
        0,1,2,0,
        0,3,4,0,
        0,0,0,0,

        0,0,0,0,
        0,5,6,0,
        0,7,8,0,
        0,0,0,0,

        0,0,0,0,
        0,0,0,0,
        0,0,0,0,
        0,0,0,0
        ];

    ubyte[] cp = 
        [
        1,2,1,2,
        3,4,3,4,
        1,2,1,2,
        3,4,3,4,

        5,6,5,6,
        7,8,7,8,
        5,6,5,6,
        7,8,7,8,

        1,2,1,2,
        3,4,3,4,
        1,2,1,2,
        3,4,3,4,

        5,6,5,6,
        7,8,7,8,
        5,6,5,6,
        7,8,7,8,
        ];

    ubyte[] rs = 
        [
            8,7,
            6,5,
            4,3,
            2,1
        ];

    ubyte[] nnd = [ 0,0, 0,0, 0,0, 0,8 ];

    auto a = Image3d( ivec3(4,4,4), PixelType( ComponentType.UBYTE,1 ), dt );
    auto b = Image3d( ivec3(4,4,4), PixelType( ComponentType.UBYTE,1 ), cp );
    auto c = Image3d( ivec3(4,4,4), PixelType( ComponentType.UBYTE,1 ) );

    auto part = a.copy(iregion3d(ivec3(1,1,1), ivec3(2,2,2)));

    c.paste( ivec3(0,0,0), part );
    c.paste( ivec3(0,2,0), part );
    c.paste( ivec3(2,0,0), part );
    c.paste( ivec3(2,2,0), part );
    
    c.paste( ivec3(0,0,2), part );
    c.paste( ivec3(0,2,2), part );
    c.paste( ivec3(2,0,2), part );
    c.paste( ivec3(2,2,2), part );

    assert( b == c );

    auto part2 = b.copy(iregion3d(ivec3(1,1,1), ivec3(2,2,2)));
    auto rr = Image3d( ivec3(2,2,2), PixelType( ComponentType.UBYTE,1 ), rs );
    assert( rr == part2 );

    auto nn = rr.copy( iregion3d( ivec3(-1,-1,-1), ivec3(2,2,2) ) );
    auto nndi = Image3d( ivec3(2,2,2), PixelType( ComponentType.UBYTE,1 ), nnd );

    assert( nn == nndi );
}

unittest
{
    ubyte[] img_data =
        [
            1,2,5,8,
            4,3,1,1
        ];

    ubyte[] hi_x_data = [ 16, 9 ];
    ubyte[] hi_y_data = [ 5, 5, 6, 9 ];

    auto img = Image2d( ivec2(4,2), PixelType( ComponentType.UBYTE, 1 ), img_data );
    auto hi_x = Image1d( vec!(1,size_t)(2), PixelType( ComponentType.UBYTE, 1 ), hi_x_data );
    auto hi_y = Image1d( vec!(1,size_t)(4), PixelType( ComponentType.UBYTE, 1 ), hi_y_data );

    assert( img.histoConv!(0,ubyte) == hi_x );
    assert( img.histoConv!(1,ubyte) == hi_y );
}
