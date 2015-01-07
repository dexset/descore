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

/++
Params:
N - dimensions count
 +/
struct Image(size_t N) if( N > 0 )
{
    /// is compatible image vector
    template CIV(V) { enum CIV = isCompatibleVector!(N,CoordType,V); }

    ///
    static struct Header
    {
        ///
        ElemInfo info;
        ///
        SizeVector!N size;

        invariant() { assert( isAllCompPositive(size) ); }

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
        }
    }

    private Header head;

    ///
    void[] data;

    invariant() { assert( data.length == head.dataSize ); }

pure:
    /// copy ctor
    this(this) { data = data.dup; }

    /// from other image
    this( in Image!N img )
    {
        head = img.head;
        data = img.data.dup;
    }

    /// from other image
    immutable this( in Image!N img )
    {
        head = img.head;
        data = img.data.idup;
    }

    /// from header and data
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

    /// from size, element info and data
    this(T)( in T[N] sz, in ElemInfo pt, in void[] data=[] )
        if( isIntegral!T )
    in { assert( isAllCompPositive(sz) ); } body
    { this( Header(pt,SizeVector!N(sz)), data ); }

    /// from size, data type, channel count and data
    this(T)( in T[N] sz, DataType dt, size_t ch, in void[] data=[] )
        if( isIntegral!T )
    in { assert( isAllCompPositive(sz) ); } body
    { this( Header(ElemInfo(dt,ch),SizeVector!N(sz)), data ); }

    /// fill data zeros
    void clear() { fill( cast(ubyte[])data, ubyte(0) ); }

    static if( N > 1 )
    {
        this( in Image!(N-1) img, size_t dim=N-1 )
        in { assert( dim < N ); } body
        {
            SizeVector!N sz;
            foreach( i; 0 .. N )
                if( i == dim ) sz[i] = 1;
                else sz[i] = img.size[i-(i>dim)];
            head.size = sz;
            head.info = img.info;
            data = img.data.dup;
        }
    }

    const @property
    {
        /// get copy of image
        auto dup() { return Image!N( this ); }

        /// get immutable copy of image
        auto idup() { return immutable(Image!N)( this ); }
    }

    ///
    immutable(void[]) dump() const
    { return (cast(void[])[head] ~ data).idup; }

    ///
    static auto load( immutable(void[]) rawdata )
    {
        auto head = (cast(Header[])rawdata[0..Header.sizeof])[0];
        return Image!N( head, rawdata[Header.sizeof .. $] );
    }

    /// access to pixel
    ref T pixel(T,C,size_t Z)( in C[Z] crd... )
        if( isIntegral!C && Z == N )
    in
    {
        assert( isAllCompPositive(crd), "negative coordinate" );
        assert( all!"a[0]>a[1]"( zip( size.dup, crd.dup ) ), "range violation" );
    }
    body
    {
        checkDataType!T;
        return (cast(T[])data)[index(crd)];
    }

    /// ditto
    ref const(T) pixel(T,C,size_t Z)( in C[Z] crd... ) const
        if( isIntegral!C && Z == N )
    in
    {
        assert( isAllCompPositive(crd), "negative coordinate" );
        assert( all!"a[0]>a[1]"( zip( size.dup, crd.dup ) ), "range violation" );
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

    private
    {
        private void checkDataType(T)() const
        {
            enforce( T.sizeof == head.info.bpe,
                    new ImageException( "access with wrong type" ) );
        }
    }

    /// return line index by coordinate
    size_t index(T,size_t Z)( in T[Z] crd... ) const
        if( isIntegral!T && Z == N )
    in { assert( isAllCompPositive(crd) ); } body
    { return getIndex( size.data, to!(CoordType[N])(crd) ); }

    @property
    {
        /// get size
        auto size() const { return head.size; }

        /// set size
        auto size(V)( in V sz ) if( CIV!V )
        in { assert( isAllCompPositive(sz) ); } body
        {
            auto old_size = head.size;
            head.size = SizeVector!N( sz );
            if( old_size != head.size )
                data = new void[]( head.dataSize );
            return sz;
        }

        /// get info
        auto info() const { return head.info; }

        /// set info
        auto info( in ElemInfo tp )
        {
            head.info = tp;
            if( data.length != head.dataSize )
                data = new void[]( head.dataSize );
            return tp;
        }

        /// get header struct copy
        auto header() const { return head; }
    }
}

///
alias Image!1 Image1;
///
alias Image!2 Image2;
///
alias Image!3 Image3;

///
unittest
{
    auto a = Image2( [3,3], ElemInfo( DataType.UBYTE, 3 ) );
    assert( a.data.length != 0 );
    assert( eq( a.size, [3,3] ) );
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

///
unittest
{
    auto a = Image2( [3,3], ElemInfo( DataType.UBYTE, 1 ), to!(ubyte[])([ 1,2,3,4,5,6,7,8,9 ]) );
    auto b = Image2(a);

    assert( a.pixel!ubyte(0,0) == 1 );
    assert( b.pixel!ubyte(0,0) == 1 );
    a.pixel!ubyte(0,0) = 2;
    assert( a.pixel!ubyte(0,0) == 2 );
    assert( b.pixel!ubyte(0,0) == 1 );

    auto c = immutable Image2(a);
    assert( c.pixel!ubyte(0,0) == 2 );
}

///
unittest
{
    auto a = Image1( [3], DataType.UBYTE, 1, to!(ubyte[])([ 1,2,3 ]) );
    assert(  mustExcept!Throwable({ a.pixel!(ubyte)(7) = 0; }) );
    assert( !mustExcept({ a.pixel!(ubyte)(0) = 0; }) );

    assert( a.pixel!ubyte(0) == 0 );

    auto b = Image2(a);

    assert( b.header.size.w == 3 );
    assert( b.header.size.h == 1 );

    assert( b.pixel!ubyte(0,0) == 0 );
    assert( b.pixel!ubyte(1,0) == 2 );
    assert( mustExcept!Throwable({ b.pixel!ubyte(1,1) = 2; }) );

    auto c = Image2(a,0);

    assert( c.header.size.w == 1 );
    assert( c.header.size.h == 3 );

    assert( c.pixel!ubyte(0,0) == 0 );
    assert( c.pixel!ubyte(0,1) == 2 );
    assert( mustExcept!Throwable({ c.pixel!ubyte(1,1) = 2; }) );

    c.size = ivec2(2,2);

    assert( c.size.w == 2 );
    assert( c.size.h == 2 );
}

///
unittest
{
    auto a = Image2( [3,3], ElemInfo( DataType.FLOAT, 2 ) );

    assert( a.index(1,2) == 7 );
    assert( a.index(ivec2(1,2)) == 7 );

    a.mapAs!(vec2)[a.index(1,2)] = vec2(1,1);
    assert( a.pixel!vec2(1,2) == vec2(1,1) );

    a.pixel!vec2(1,2) = vec2(2,2);
    assert( a.pixel!vec2(1,2) == vec2(2,2) );
}

unittest
{
    vec2 sum( in Image2 img ) pure
    {
        auto buf = img.mapAs!vec2;
        return reduce!((a,b)=>(a+=b))(vec2(0,0),buf);
    }

    auto a = Image2( [3,3], ElemInfo( DataType.FLOAT, 2 ) );

    a.pixel!vec2(0,0) = vec2(1,2);
    a.pixel!vec2(1,2) = vec2(2,2);

    assert( sum(a) == vec2(3,4) );
}

///
unittest
{
    Image2 img;
    assert( img.data.length == 0 );
    assert( img.data is null );
    assert( img.size == SizeVector!2(0,0) );

    img.size = ivec2(3,3);
    img.info = ElemInfo( DataType.NORM_FIXED, 3 );
    img.clear();

    assert( img.data.length == 27 * float.sizeof );
    assert( img.info.bpe == 3 * float.sizeof );

    img.pixel!col3(0,1) = col3( .2,.1,.3 );
    assert( img.pixel!vec3(0,1) == vec3(.2,.1,.3) );

    auto di = Image2.load( img.dump() );
    assert( di.size == img.size );
    assert( di.info == img.info );
    assert( di.data == img.data );

    auto ii = immutable(Image2)( img );
    assert( ii.size == img.size );
    assert( ii.info == img.info );
    assert( ii.data == img.data );

    assert( ii.pixel!vec3(0,1) == vec3(.2,.1,.3) );

    auto dii = immutable(Image2).load( ii.dump() );
    static assert( is( typeof(dii) == Image2 ) );
    assert( dii.size == img.size );
    assert( dii.info == img.info );
    assert( dii.data == img.data );

    auto dd = ii.dup;
    static assert( is( typeof(dd) == Image2 ) );
    assert( dd.size == img.size );
    assert( dd.info == img.info );
    assert( dd.data == img.data );

    auto ddi = ii.idup;
    static assert( is( typeof(ddi) == immutable(Image2) ) );
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

    auto img = Image2( ivec2(3,3), DataType.FLOAT, 2, data );

    assert( img.size == ivec2(3,3) );
    assert( img.info.bpe == 2 * float.sizeof );

    assert( img.pixel!vec2(1,1) == vec2(9,1) );
    assert( img.info.comp == DataType.FLOAT );

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

///
unittest
{
    assert( mustExcept({ Image2( [3,3], ElemInfo( DataType.UBYTE, 3 ), [ 1, 2, 3 ] ); }) );

    auto dt = [ vec2(1,0), vec2(0,1) ];
    assert( mustExcept({ Image2( ivec2(3,3), DataType.FLOAT, 2, dt ); }) );

    auto img = Image2( ivec2(3,3), ElemInfo( DataType.NORM_FIXED, 3 ) );
    assert( mustExcept({ auto d = img.mapAs!vec2; }) );

    assert( !mustExcept({ img.pixel!col3(1,0) = col3(1,1,1); }) );
    assert(  mustExcept({ img.pixel!vec2(1,0) = vec2(1,1); }) );
    static assert(  !__traits(compiles, { img.pixel!vec3(4,4) = vec3(1,1); }) );
}
