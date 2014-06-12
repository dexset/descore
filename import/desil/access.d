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

module desil.access;

import desil.image;
import desil.rect;
import desmath.linear.vector;

interface ImageReadAccess
{ const {
    @property ref const(Image) selfImage();

    final
    {
        Image copy( in irect r ) { return selfImage.copy(r); }
        @property
        {
            const(ubyte[]) raw() { return selfImage.data; }
            imsize_t size() { return selfImage.size; }
            ImageType type() { return selfImage.type; }
            Image dup() { return selfImage.dup; }
            immutable(Image) idup(){ return selfImage.idup; }
            T[] copyData(T)() { return selfImage.copyData!T; }
        }

        immutable(ubyte[]) serialize() { return selfImage.serialize(); }

        T read(T)( in imcrd_t pos ) { return selfImage.read!T( pos.x, pos.y ); }
        T read(T)( size_t x, size_t y ) { return selfImage.read!T( x, y ); } 
    }
} }

class PointerIRA : ImageReadAccess
{
    Image* img;
    this( Image* I )
    {
        if( I is null ) throw new ImageException( "PointerIRA.ctor get null image pointer" );
        img = I;
    }
    const @property ref const(Image) selfImage() 
    { 
        return *img; 
    } 
}

interface ImageTypedRead(T): ImageReadAccess
{ const {
    final
    {
        T opIndex( in imcrd_t pos ) { return selfImage.read!T( pos.x, pos.y ); }
        T opIndex( size_t x, size_t y ) { return selfImage.read!T( x, y ); }
    }
} }

unittest
{
    class IRA: ImageReadAccess, ImageTypedRead!col3
    {
        Image img;
        this( in Image input ) { img = Image(input); }
        const @property ref const(Image) selfImage() { return img; }
    }

    auto data =
    [
        vec3(1,3,4), vec3(2,3,4), vec3(1,2,3),
        vec3(1,1,4), vec3(3,2,1), vec3(1,3,3),
        vec3(3,1,4), vec3(3,2,4), vec3(1,3,2)
    ];

    auto img = Image( imsize_t(3,3), ImageType( ImCompType.FLOAT, 3 ), cast(ubyte[])data );

    auto ira = new IRA( img );

    assert( ira.size == imsize_t(3,3) );
    assert( ira.type.bpp == float.sizeof * 3 );
    assert( ira.raw == cast(ubyte[])data );
    assert( ira.copyData!vec3 == data );

    assert( ira.read!col3(1,1) == col3(3,2,1) );
    assert( ira[1,1] == col3(3,2,1) );
}

interface ImageFullAccess: ImageReadAccess
{
    protected void accessHook( size_t x, size_t y );
    protected @property ref Image selfImage();
    final
    {
        void clear() { selfImage.clear(); }
        void allocate( in imsize_t sz, in ImageType tp, in ubyte[] dt=null )
        { selfImage.allocate( sz, tp, dt ); }

        void allocate(T)( in imsize_t sz, in T[] dt=null )
        { selfImage.allocate!T( sz, dt ); }

        void set(T)( in T[] dt ) { selfImage.set( dt ); }

        ref T access(T)( in imcrd_t pos ) 
        { 
            accessHook( pos.x, pos.y );
            return selfImage.access!T( pos.x, pos.y ); 
        }

        ref T access(T)( size_t x, size_t y )
        { 
            accessHook( x, y );
            return selfImage.access!T( x, y ); 
        }

        void paste( in ivec2 pos, in Image im )
        {
            selfImage.paste( pos, im );
        }
    }
}

interface ImageTypedAccess(T):ImageFullAccess, ImageTypedRead!T
{
    protected void accessHook( size_t x, size_t y );
    protected @property ref Image selfImage();
    final
    {
        ref T opIndex( in imcrd_t pos ) 
        { 
            accessHook( pos.x, pos.y ); 
            return selfImage.access!T( pos.x, pos.y ); 
        }

        ref T opIndex( size_t x, size_t y ) 
        { 
            accessHook( x, y ); 
            return selfImage.access!T( x, y ); 
        }
    }
}

unittest
{
    class IFA: ImageFullAccess, ImageTypedAccess!col3
    {
        Image img;
        this( in Image input ) { img = Image(input); }
        const @property ref const(Image) selfImage() { return img; }
        protected @property ref Image selfImage() { return img; }

        imcrd_t[] accessPos;

        protected void accessHook( size_t x, size_t y ) { accessPos ~= imcrd_t(x,y); }
    }

    auto data =
    [
        vec3(1,3,4), vec3(2,3,4), vec3(1,2,3),
        vec3(1,1,4), vec3(3,2,1), vec3(1,3,3),
        vec3(3,1,4), vec3(3,2,4), vec3(1,3,2)
    ];

    auto img = Image( imsize_t(3,3), ImageType( float.sizeof * 3 ), cast(ubyte[])data );

    auto ifa = new IFA( img );

    assert( ifa.size == imsize_t(3,3) );
    assert( ifa.type.bpp == float.sizeof * 3 );
    assert( ifa.raw == cast(ubyte[])data );
    assert( ifa.copyData!vec3 == data );

    assert( ifa.read!col3(1,1) == col3(3,2,1) );
    assert( (cast(ImageTypedRead!col3)ifa)[1,1] == col3(3,2,1) );

    ifa[1,1] = col3(2,3,1);
    assert( (cast(ImageTypedRead!col3)ifa)[1,1] == col3(2,3,1) );
    ifa.access!vec3(1,2) = vec3(9,8,5);
    assert( (cast(ImageTypedRead!col3)ifa)[1,2] == col3(9,8,5) );
    assert( ifa.accessPos == [ imcrd_t(1,1), imcrd_t(1,2) ] );
}
