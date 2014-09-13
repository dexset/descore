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

import std.algorithm;
import std.string;
import std.exception;
import std.range;
import std.traits;
import std.conv;

import desmath.linear.vector;
import desil.region;
import desutil.testsuite;

enum ComponentType
{
    RAWBYTE,
    BYTE,
    UBYTE,

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
    ComponentType comp = ComponentType.RAWBYTE;
    size_t channels = 1;

    invariant() { assert( channels > 0 ); }

    pure @safe nothrow @nogc
    {
        this( ComponentType ict, size_t ch )
        {
            comp = ict;
            channels = ch;
        }

        this( size_t ch )
        {
            comp = ComponentType.RAWBYTE;
            channels = ch;
        }

        @property
        {
            size_t bpp() const { return compSize * channels; }

            size_t compSize() const
            {
                final switch( comp )
                {
                    case ComponentType.RAWBYTE:
                    case ComponentType.BYTE:
                    case ComponentType.UBYTE:
                        return byte.sizeof;

                    case ComponentType.SHORT:
                    case ComponentType.USHORT:
                        return short.sizeof;

                    case ComponentType.INT:
                    case ComponentType.UINT:
                        return int.sizeof;

                    case ComponentType.FLOAT:
                    case ComponentType.NORM_FLOAT:
                        return float.sizeof;

                    case ComponentType.DOUBLE:
                    case ComponentType.NORM_DOUBLE:
                        return double.sizeof;
                }
            }
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

    alias Vector!(N,size_t,"whd"[0..N].spaceSep) imsize_t;
    alias Vector!(N,size_t,"xyz"[0..N].spaceSep) imcrd_t;
    alias Vector!(N,ptrdiff_t,"xyz"[0..N].spaceSep) imdiff_t;

    alias Region!(N,ptrdiff_t) imregion_t;

    static struct Header
    {
        PixelType type;
        imsize_t size;

        pure
        {
            @safe nothrow @property @nogc
            {
                size_t dataSize() const { return pixelCount * type.bpp; }

                size_t pixelCount() const
                {
                    size_t sz = 1;
                    foreach( v; size.data ) sz *= v;
                    return sz;
                }
            }
        }
    }

    private Header head;
    void[] data;

    invariant() { assert( data.length == head.dataSize ); }

    pure
    {
        this(this) { data = data.dup; }

        this( in Image!N img )
        {
            head = img.head;
            data = img.data.dup;
        }

        immutable this( in Image!N img )
        {
            head = img.head;
            data = img.data.idup;
        }

        this( Header hdr, in void[] data=[] )
        {
            head = hdr;

            if( data.length == 0 )
                this.data = new void[]( head.dataSize );
            else
            {
                enforce( data.length == head.dataSize );
                this.data = data.dup;
            }
        }

        this( in size_t[N] sz, in PixelType pt, in void[] data=[] )
        { this( Header(pt,imsize_t(sz)), data ); }

        this(V)( in V v, in PixelType pt, in void[] data=[] )
            if( isCompatibleVector!(N,size_t,V) )
        { this( to!(size_t[N])(v.data), pt, data ); }

        this(T)( in size_t[N] sz, in T[] data=[] )
        { this( sz, PixelType( ComponentType.RAWBYTE, T.sizeof ), data ); }

        this(V,T)( in V v, in T[] data=[] )
            if( isCompatibleVector!(N,size_t,V) )
        { this( to!(size_t[N])(v.data), PixelType( ComponentType.RAWBYTE, T.sizeof ), data ); }

        void clear() { fill( cast(ubyte[])data, ubyte(0) ); }

        static if( N > 1 )
        {
            this( in Image!(N-1) img, size_t dim=N-1 )
            in { assert( dim < N ); } body
            {
                imsize_t sz;
                foreach( i; 0 .. N )
                    if( i == dim ) sz[i] = 1;
                    else sz[i] = img.size[i-(i>dim)];
                head.size = sz;
                head.type = img.type;
                data = img.data.dup;
            }
        }

        const @property
        {
            auto dup() { return selftype( this ); }
            auto idup() { return immutable(selftype)( this ); }
        }

        immutable(void[]) dump() const
        { return (cast(void[])[head] ~ data).idup; }

        static auto load( immutable(void[]) rawdata )
        {
            auto head = (cast(Header[])rawdata[0..Header.sizeof])[0];
            return selftype( head, rawdata[Header.sizeof .. $] );
        }

        ref T pixel(T)( in size_t[N] crd... )
        {
            checkComponentType!T;
            return (cast(T[])data)[index(crd)];
        }

        ref const(T) pixel(T)( in size_t[N] crd... ) const
        {
            checkComponentType!T;
            return (cast(const(T)[])data)[index(crd)];
        }

        ref T pixel(T,V)( in V v )
            if( isCompatibleVector!(N,size_t,V) )
        {
            checkComponentType!T;
            return (cast(T[])data)[index(to!(size_t[N])(v.data))];
        }

        ref const(T) pixel(T,V)( in V v ) const
            if( isCompatibleVector!(N,size_t,V) )
        {
            checkComponentType!T;
            return (cast(const(T)[])data)[index(to!(size_t[N])(v.data))];
        }

        @property T[] mapAs(T)()
        {
            checkComponentType!T;
            return cast(T[])data; 
        }

        @property const(T)[] mapAs(T)() const
        {
            checkComponentType!T;
            return cast(const(T)[])data; 
        }

        private
        {
            private void checkComponentType(T)() const
            {
                enforce( T.sizeof == head.type.bpp,
                        new ImageException( "access with wrong type" ) );
            }

            static size_t indexCalc( in size_t[N] imsize, in size_t[N] crd )
            in
            {
                enforce( all!"a[0]>a[1]"( zip( imsize.dup, crd.dup ) ), 
                        new ImageException("range violation") );
            }
            body
            {
                size_t ret;
                foreach( i; 0 .. N )
                {
                    auto v = reduce!((a,b)=>(a*=b))(1UL,imsize[0..i]);
                    ret += crd[i] * v;
                }
                return ret;
            }

            size_t index( in size_t[N] crd... ) const
            { return indexCalc( header.size.data, crd ); }

            size_t index(V)( in V v ) const
                if( isCompatibleVector!(N,size_t,V) )
            { return indexCalc( header.size.data, to!(size_t[N])(v.data) ); }
        }

        @property
        {
            auto size() const { return head.size; }

            auto size(V)( in V sz ) 
                if( isCompatibleVector!(N,size_t,V) )
            in
            {
                enforce( all!"a>=0"(sz.data.dup),
                        new ImageException( "resize components must be >= 0" ) );
            }
            body
            {
                head.size = imsize_t( sz.data );
                if( data.length != head.dataSize )
                    data = new void[]( head.dataSize );
                return sz;
            }

            auto type() const { return head.type; }

            auto type( in PixelType tp )
            {
                head.type = tp;
                if( data.length != head.dataSize )
                    data = new void[]( head.dataSize );
                return tp;
            }

            auto header() const { return head; }
        }

        auto copy(T)( in Region!(N,T) r ) const if( isIntegral!T )
        {
            auto ret = selftype( imsize_t(r.size).data, this.header.type );

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
            if( isCompatibleVector!(N,size_t,V) )
        {
            enforce( im.type == this.type,
                new ImageException( "Image type is not good for paste." ) );

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

            ret ~= format( `Vector!(N,size_t) %s = %s;`, ind, start );

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
            @property Image!(N-1) histoConv(size_t K, T)() const if( K < N )
            {
                if( T.sizeof != type.bpp )
                    throw new ImageException( "type size uncompatible with elem size" );
                
                Vector!(N-1,size_t) ret_size;
                foreach( i; 0 .. N )
                    if( i != K )
                        ret_size[i-cast(size_t)(i>K)] = size[i];

                auto ret = Image!(N-1)( ret_size, type );

                enum fbody = `

                    Vector!(N-1,size_t) rind;
                    foreach( i; 0 .. N ) if( i != K )
                        rind[i-cast(size_t)(i>K)] = ind[i];

                    for( ind[K] = 0; ind[K] < size[K]; ind[K]++ )
                        ret.mapAs!(T)[ret.index(rind)] += mapAs!(T)[index(ind)];
                    `;
                mixin( indexForeachString( "Vector!(N,size_t).init", "size", "ind", fbody, K ) );

                return ret;
            }
        }
    }
}

alias Image!1 Image1;
alias Image!2 Image2;
alias Image!3 Image3;

version(unittest)
{
    private struct bvec3
    {
        ubyte[3] data;
        alias data this;
        this( ubyte[3] d... ) { data = d; }
    }
}

unittest
{
    auto a = Image2( [3,3], PixelType( ComponentType.UBYTE, 3 ) );
    assert( a.data.length != 0 );
    assert( eq( a.header.size, [3,3] ) );
    a.pixel!bvec3(0,0) = bvec3(1,2,3);
    auto b = a;
    assert( b == a );
    assert( eq( b.pixel!bvec3(0,0), bvec3(1,2,3) ) );
    a.pixel!bvec3(1,1) = bvec3(3,4,5);
    assert( b != a );
    assert( b == Image2.load( b.dump() ) );
    assert( b == b.dup );
    assert( b.data == b.idup.data.dup );
    a = b;
    assert( b == a );
    assert( a == Image2.load( b.dump() ) );
    assert( a == b.dup );
    assert( a.data == b.idup.data.dup );
    auto crd = ivec2(1,2);
    b.pixel!bvec3(crd) = bvec3(5,6,8);
    assert( eq( b.pixel!bvec3(1,2), bvec3(5,6,8) ) );

    b.clear();
    assert( eq( b.pixel!bvec3(1,2), bvec3(0,0,0) ) );
}

unittest
{
    auto a = Image2( [3,3], to!(ubyte[])([ 1,2,3,4,5,6,7,8,9 ]) );
    auto b = Image2(a);

    assert( a.pixel!ubyte(0,0) == 1 );
    assert( b.pixel!ubyte(0,0) == 1 );
    a.pixel!ubyte(0,0) = 2;
    assert( a.pixel!ubyte(0,0) == 2 );
    assert( b.pixel!ubyte(0,0) == 1 );

    auto c = immutable Image2(a);
    assert( c.pixel!ubyte(0,0) == 2 );
}

unittest
{
    auto a = Image1( [3], to!(ubyte[])([ 1,2,3 ]) );
    assert(  mustExcept({ a.pixel!(ubyte)(8) = 0; }) );
    assert( !mustExcept({ a.pixel!(ubyte)(0) = 0; }) );

    assert( a.pixel!ubyte(0) == 0 );

    auto b = Image2(a);

    assert( b.header.size.w == 3 );
    assert( b.header.size.h == 1 );

    assert( b.pixel!ubyte(0,0) == 0 );
    assert( b.pixel!ubyte(1,0) == 2 );
    assert( mustExcept({ b.pixel!ubyte(1,1) = 2; }) );

    auto c = Image2(a,0);

    assert( c.header.size.w == 1 );
    assert( c.header.size.h == 3 );

    assert( c.pixel!ubyte(0,0) == 0 );
    assert( c.pixel!ubyte(0,1) == 2 );
    assert( mustExcept({ c.pixel!ubyte(1,1) = 2; }) );

    c.size = ivec2(2,2);

    assert( c.size.w == 2 );
    assert( c.size.h == 2 );
}

unittest
{
    auto a = Image1( [5], PixelType( ComponentType.FLOAT, 2 ) );
    a.pixel!vec2(3) = vec2(1,1);
    a.pixel!vec2(4) = vec2(2,2);
    auto b = a.copy( Image1.imregion_t(3,2) );
    assert( b.pixel!vec2(0) == a.pixel!vec2(3) );
    assert( b.pixel!vec2(1) == a.pixel!vec2(4) );
}

unittest
{
    auto a = Image2( [3,3], PixelType( ComponentType.FLOAT, 2 ) );

    assert( a.index(1,2) == 7 );
    assert( a.index(ivec2(1,2)) == 7 );

    a.mapAs!(vec2)[a.index(1,2)] = vec2(1,1);
    assert( a.pixel!vec2(1,2) == vec2(1,1) );

    a.pixel!vec2(1,2) = vec2(2,2);
    assert( a.pixel!vec2(1,2) == vec2(2,2) );
}

unittest
{
    auto a = Image3( [3,3,3], PixelType( ComponentType.FLOAT, 2 ) );

    assert( a.index(1,2,1) == 16 );

    a.mapAs!(vec2)[a.index(1,2,1)] = vec2(1,1);
    assert( a.pixel!vec2(1,2,1) == vec2(1,1) );

    a.pixel!vec2(1,2,1) = vec2(2,2);
    assert( a.pixel!vec2(1,2,1) == vec2(2,2) );

    auto b = a.copy( a.imregion_t(1,2,1,1,1,1) );
    assert( b.pixel!vec2(0,0,0) == vec2(2,2) );
}

unittest
{
    pure vec2 sum( in Image2 img )
    {
        auto buf = img.mapAs!vec2;
        return reduce!((a,b)=>(a+=b))(vec2(0,0),buf);
    }

    auto a = Image2( [3,3], PixelType( ComponentType.FLOAT, 2 ) );

    a.pixel!vec2(0,0) = vec2(1,2);
    a.pixel!vec2(1,2) = vec2(2,2);

    assert( sum(a) == vec2(3,4) );
}

unittest
{
    Image2 img;
    assert( img.data.length == 0 );
    assert( img.data is null );
    assert( img.size == Image2.imsize_t(0,0) );

    img.size = ivec2(3,3);
    img.type = PixelType( ComponentType.NORM_FLOAT, 3 );
    img.clear();

    assert( img.data.length == 27 * float.sizeof );
    assert( img.type.bpp == 3 * float.sizeof );

    img.pixel!col3(0,1) = col3( .2,.1,.3 );
    assert( img.pixel!vec3(0,1) == vec3(.2,.1,.3) );

    auto di = Image2.load( img.dump() );
    assert( di.size == img.size );
    assert( di.type == img.type );
    assert( di.data == img.data );

    auto ii = immutable(Image2)( img );
    assert( ii.size == img.size );
    assert( ii.type == img.type );
    assert( ii.data == img.data );

    assert( ii.pixel!vec3(0,1) == vec3(.2,.1,.3) );

    auto dii = immutable(Image2).load( ii.dump() );
    static assert( is( typeof(dii) == Image2 ) );
    assert( dii.size == img.size );
    assert( dii.type == img.type );
    assert( dii.data == img.data );

    auto dd = ii.dup;
    static assert( is( typeof(dd) == Image2 ) );
    assert( dd.size == img.size );
    assert( dd.type == img.type );
    assert( dd.data == img.data );

    auto ddi = ii.idup;
    static assert( is( typeof(ddi) == immutable(Image2) ) );
    assert( ddi.size == img.size );
    assert( ddi.type == img.type );
    assert( ddi.data == img.data );
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

    auto orig = Image2( [5,5], data );
    auto im = orig.copy( iRegion2( 0, 0, 5, 5 ) );
    assert( orig == im );
    
    auto imv1 = Image2( ivec2( 7, 7 ), datav1 );
    assert( orig.copy( iRegion2( -1, -1, 7, 7 ) ) == imv1 );

    auto imv2 = Image2( [3,3], datav2 );
    assert( orig.copy( iRegion2( 1, 1, 3, 3 ) ) == imv2 );

    auto imv3 = Image2( ivec2(4,4), datav3 );
    assert( orig.copy( iRegion2( -1, -1, 4, 4 ) ) == imv3 );

    auto imv4 = Image2( ivec2(4,4), datav4 );
    assert( orig.copy( iRegion2( 2, -1, 4, 4 ) ) == imv4 );

    auto imv5 = Image2( ivec2(4,4), datav5 );
    assert( orig.copy( iRegion2( -1, 2, 4, 4 ) ) == imv5 );

    auto imv6 = Image2( [4,4], datav6 );
    assert( orig.copy( iRegion2( 2, 2, 4, 4 ) ) == imv6 );
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


    auto orig = Image2( ivec2( 7, 7 ), PixelType( ComponentType.RAWBYTE, 1 ) );
    auto im = Image2( ivec2( 5, 5 ), data );

    auto res = Image2(orig);
    res.paste( ivec2(-1,-1), im );
    assert( res.data == datav1 );

    res = Image2(orig);
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

    auto img = Image2( ivec2(3,3), data );

    assert( img.size == ivec2(3,3) );
    assert( img.type.bpp == 2 * float.sizeof );

    assert( img.pixel!vec2(1,1) == vec2(9,1) );
    assert( img.type.comp == ComponentType.RAWBYTE );

    auto imdata = img.mapAs!vec2;
    assert( data == imdata );

    img.clear();
    assert( img.pixel!vec2(1,1) == vec2(0,0) );

    img.mapAs!(vec2)[] = data[];
    imdata = img.mapAs!vec2;
    assert( data == imdata );

    auto constdata = img.idup.mapAs!vec2;
    assert( constdata == imdata );
    assert( is( typeof(constdata) == const(vec2)[] ) );
}

unittest
{
    assert( mustExcept({ Image2( [3,3], PixelType( ComponentType.UBYTE, 3 ), [ 1, 2, 3 ] ); }) );

    auto dt = [ vec2(1,0), vec2(0,1) ];
    assert( mustExcept({ Image2( ivec2(3,3), dt ); }) );

    auto img = Image2( ivec2(3,3), PixelType( ComponentType.NORM_FLOAT, 3 ) );
    assert( mustExcept({ auto d = img.mapAs!vec2; }) );

    assert( !mustExcept({ img.pixel!col3(1,0) = col3(1,1,1); }) );
    assert(  mustExcept({ img.pixel!vec2(1,0) = vec2(1,1); }) );
    assert(  mustExcept({ img.pixel!vec3(4,4) = vec3(1,1); }) );
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

    auto a = Image3( [4,4,4], PixelType( ComponentType.UBYTE,1 ), dt );
    auto b = Image3( [4,4,4], PixelType( ComponentType.UBYTE,1 ), cp );
    auto c = Image3( [4,4,4], PixelType( ComponentType.UBYTE,1 ) );

    auto part = a.copy(iRegion3(ivec3(1,1,1), ivec3(2,2,2)));

    c.paste( ivec3(0,0,0), part );
    c.paste( ivec3(0,2,0), part );
    c.paste( ivec3(2,0,0), part );
    c.paste( ivec3(2,2,0), part );
    
    c.paste( ivec3(0,0,2), part );
    c.paste( ivec3(0,2,2), part );
    c.paste( ivec3(2,0,2), part );
    c.paste( ivec3(2,2,2), part );

    assert( b == c );

    auto part2 = b.copy(iRegion3(ivec3(1,1,1), ivec3(2,2,2)));
    auto rr = Image3( ivec3(2,2,2), PixelType( ComponentType.UBYTE,1 ), rs );
    assert( rr == part2 );

    auto nn = rr.copy( iRegion3( ivec3(-1,-1,-1), ivec3(2,2,2) ) );
    auto nndi = Image3( ivec3(2,2,2), PixelType( ComponentType.UBYTE,1 ), nnd );

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

    auto img = Image2( [4,2], PixelType( ComponentType.UBYTE, 1 ), img_data );
    auto hi_x = Image1( [2], PixelType( ComponentType.UBYTE, 1 ), hi_x_data );
    auto hi_y = Image1( [4], PixelType( ComponentType.UBYTE, 1 ), hi_y_data );

    assert( img.histoConv!(0,ubyte) == hi_x );
    assert( img.histoConv!(1,ubyte) == hi_y );
}

unittest
{
    ubyte[] src_data =
        [
        1,2,3,
        4,5,6,
        7,8,9
        ];

    ubyte[] dst1_data =
        [
        0,0,0,
        0,0,0,
        0,0,0,
        1,2,3,
        4,5,6,
        7,8,9,
        0,0,0,
        0,0,0,
        0,0,0
        ];

    ubyte[] dst2_data =
        [
        0,1,0,
        0,2,0,
        0,3,0,
        0,4,0,
        0,5,0,
        0,6,0,
        0,7,0,
        0,8,0,
        0,9,0
        ];

    auto src = Image2( ivec2(3,3), PixelType( ComponentType.UBYTE, 1 ), src_data );
    auto dst = Image3( ivec3(3,3,3), PixelType( ComponentType.UBYTE, 1 ) );
    dst.paste( ivec3(0,0,1), Image3( src ) );
    assert( dst.data == dst1_data );
    dst.clear();
    dst.paste( ivec3(1,0,0), Image3(src,0) );
    assert( dst.data == dst2_data );
}
