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

module desmath.linear.matrix;

import std.math;
import std.traits;
import std.algorithm;
import std.exception;

import desutil.flatdata;
import desutil.testsuite;

import desmath.linear.vector;
import desmath.basic.traits;

private pure void isMatrixImpl(size_t H,size_t W,T)( Matrix!(H,W,T) ){}
pure bool isMatrix(E)() { return is( typeof( isMatrixImpl(E.init) ) ); }

pure bool isStaticMatrix(E)()
{
    static if( !isMatrix!E ) return false;
    else return E.isStatic;
}

pure bool isDynamicMatrix(E)()
{
    static if( !isMatrix!E ) return false;
    else return E.isDynamic;
}

unittest
{
    static assert( !isStaticMatrix!float );
    static assert( !isDynamicMatrix!float );
}

struct Matrix(size_t H, size_t W, E)
{
    alias Matrix!(H,W,E) selftype;
    alias E datatype;

    enum isDynamic = H == 0 || W == 0;
    enum isStatic = H != 0 && W != 0;

    enum isDynamicHeight = H == 0;
    enum isStaticHeight = H != 0;

    enum isDynamicWidth = W == 0;
    enum isStaticWidth = W != 0;

    enum isStaticHeightOnly = isStaticHeight && isDynamicWidth;
    enum isStaticWidthOnly = isStaticWidth && isDynamicHeight;

    enum isDynamicAll = isDynamicHeight && isDynamicWidth;
    enum isDynamicOne = isStaticWidthOnly || isStaticHeightOnly;

    static if( isStatic )
        E[W][H] data;
    else static if( isStaticWidthOnly )
        E[W][] data;
    else static if( isStaticHeightOnly )
        E[][H] data;
    else E[][] data;

    alias data this;

pure:

    private static bool allowSomeOp(size_t A, size_t B )
    { return A==B || A==0 || B==0; }

    static if( isStatic )
    {
        this(X...)( in X vals ) { fill( flatData!E(vals) ); }
    }
    else static if( isStaticWidthOnly )
    {
        this(X...)( in X vals )
        {
            auto buf = flatData!E(vals);
            enforce( !(buf.length%W), "wrong args length" );
            resize( buf.length/W, W );
            fill( buf );
        }
    }
    else static if( isStaticHeightOnly )
    {
        this(X...)( in X vals )
        {
            auto buf = flatData!E(vals);
            enforce( !(buf.length%H), "wrong args length" );
            resize( H, buf.length/H );
            fill( buf );
        }
    }
    else
    {
        this(X...)( size_t iH, size_t iW, in X vals )
        {
            auto buf = flatData!E(vals);
            enforce( buf.length == iH * iW, "wrong args length" ); 
            resize( iH, iW );
            fill( buf );
        }

        this( size_t iH, size_t iW ) { resize( iH, iW ); }
    }

    this(size_t oH, size_t oW, X)( in Matrix!(oH,oW,X) mtr )
        if( is(typeof(flatData!E(mtr.data))) )
    {
        static if( isDynamic )
            resize( mtr.height, mtr.width );
        fill( flatData!E(mtr.data) );
    }

    static if( isDynamic )
    {
        this(this) { fill(flatData!E(data)); }

        auto opAssign(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) b )
            if( allowSomeOp(H,bH) && allowSomeOp(W,bW) && is(typeof(E(X.init))) )
        {
            static if( isStaticHeight && b.isDynamicHeight ) enforce( height == b.height, "wrong height" );
            static if( isStaticWidth && b.isDynamicWidth ) enforce( width == b.width, "wrong width" );
            static if( isDynamic ) resize(b.height,b.width);
            fill(flatData!E(b.data));
            return this;
        }
    }

    static if( (W==H && isStatic) || isDynamicOne )
        static auto diag(X...)( in X vals )
        if( X.length > 0 && is(typeof(E(0))) && is(typeof(flatData!E(vals))) )
        {
            selftype ret;
            static if( isStaticHeight ) auto L = H;
            else auto L = W;

            static if( ret.isDynamic )
                ret.resize(L,L);

            ret.fill( E(0) );
            ret.fillDiag( flatData!E(vals) );

            return ret;
        }

    void fill( in E[] vals... )
    {
        enforce( vals.length > 0, "no vals to fill" );
        if( vals.length > 1 )
        {
            enforce( vals.length == height * width, "wrong vals length" );
            size_t k = 0;
            foreach( ref row; data )
                foreach( ref v; row )
                    v = vals[k++];
        }
        else foreach( ref row; data ) row[] = vals[0];
    }

    auto fillDiag( in E[] vals... )
    {
        enforce( vals.length > 0, "no vals to fill" );
        static if( isDynamic ) enforce( height == width, "not squared" );
        size_t k = 0;
        foreach( i; 0 .. H )
            data[i][i] = vals[k++%$];
        return this;
    }

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

    static if( isStaticWidth ) enum width = W;
    else
    {
        @property size_t width() const { return _width; }
        @property size_t width( size_t nw )
        {
            resize( height, nw );
            return nw;
        }
    }

    static if( isDynamic )
    {
        static if( isDynamicWidth ) private size_t _width = W;

        void resize( size_t nh, size_t nw )
        {
            static if( isStaticHeight ) enforce( nh == H, "height is static" );
            static if( isStaticWidth ) enforce( nw == W, "width is static" );

            static if( isDynamicHeight ) data.length = nh;
            static if( isDynamicWidth )
            {
                _width = nw;
                foreach( i; 0 .. height )
                    data[i].length = nw;
            }
        }
    }

    auto expandHeight(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( (bW==W||W==0||bW==0) && is(typeof(E(X.init))) )
    {
        static if( isDynamicWidth || mtr.isDynamicWidth )
            enforce( mtr.width == width, "wrong width" );

        auto ret = Matrix!(0,W,E)(this);
        auto last_height = height;
        ret.resize( ret.height + mtr.height, width );
        foreach( i; 0 .. mtr.height )
            foreach( j; 0 .. width )
                ret.data[last_height+i][j] = E(mtr.data[i][j]);
        return ret;
    }

    auto expandHeight(X...)( in X vals ) const
        if( is(typeof(Matrix!(1,W,E)(vals))) )
    { return expandHeight( Matrix!(1,W,E)(vals) ); }

    auto expandWidth(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( (bH==H||H==0||bH==0) && is(typeof(E(X.init))) )
    {
        static if( isDynamicHeight || mtr.isDynamicHeight )
            enforce( mtr.height == height, "wrong height" );
        auto ret = Matrix!(H,0,E)(this);
        auto last_width = width;
        ret.resize( height, ret.width + mtr.width );
        foreach( i; 0 .. height )
            foreach( j; 0 .. mtr.width )
                ret.data[i][last_width+j] = E(mtr.data[i][j]);
        return ret;
    }

    auto expandWidth(X...)( in X vals ) const
        if( is(typeof(Matrix!(H,1,E)(vals))) )
    { return expandWidth( Matrix!(H,1,E)(vals) ); }

    @property auto asArray() const
    {
        auto ret = new E[](width*height);
        foreach( i; 0 .. height )
            foreach( j; 0 .. width )
                ret[i*width+j] = data[i][j];
        return ret;
    }

    auto sliceHeight( size_t start, size_t count=0 ) const
    {
        enforce( start < height );
        count = count ? count : height - start;
        auto ret = Matrix!(0,W,E)(this);
        ret.resize( count, width );
        foreach( i; 0 .. count )
            ret.data[i][] = data[start+i][];
        return ret;
    }

    auto sliceWidth( size_t start, size_t count=0 ) const
    {
        enforce( start < width );
        count = count ? count : width - start;
        auto ret = Matrix!(H,0,E)(this);
        ret.resize( height, count );
        foreach( i; 0 .. height )
            foreach( j; 0 .. count )
            ret.data[i][j] = data[i][start+j];
        return ret;
    }

    auto opUnary(string op)() const
        if( op == "-" && is( typeof( E.init * (-1) ) ) )
    {
        auto ret = selftype(this);
        foreach( ref row; ret.data )
            foreach( ref v; row )
                v = v * -1;
        return ret;
    }

    private void checkCompatible(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
    {
        static if( isDynamicHeight || mtr.isDynamicHeight )
            enforce( height == mtr.height, "wrong height" );
        static if( isDynamicWidth || mtr.isDynamicWidth )
            enforce( width == mtr.width, "wrong width" );
    }

    auto opBinary(string op, size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( (op=="+"||op=="-") && allowSomeOp(H,bH) && allowSomeOp(W,bW) )
    {
        checkCompatible( mtr );

        auto ret = selftype(this);

        foreach( i; 0 .. height )
            foreach( j; 0 .. width )
                mixin( `ret[i][j] = E(data[i][j] ` ~ op ~ ` mtr[i][j]);` );
        return ret;
    }

    auto opBinary(string op,X)( in X b ) const
        if( (op!="+" && op!="-") && isValidOp!(op,E,X) )
    {
        auto ret = selftype(this);
        foreach( i; 0 .. height )
            foreach( j; 0 .. width )
                mixin( `ret[i][j] = E(data[i][j] ` ~ op ~ ` b);` );
        return ret;
    }

    auto opBinary(string op,size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( op=="*" && allowSomeOp(W,bH) && isValidOp!("*",E,X) )
    {
        static if( isDynamic || mtr.isDynamic )
            enforce( width == mtr.height, "incompatible sizes for mul" );
        Matrix!(H,bW,E) ret;
        static if( ret.isDynamic ) ret.resize(height,width);

        foreach( i; 0 .. height )
            foreach( j; 0 .. mtr.width )
            {
                ret[i][j] = E( data[i][0] * mtr.data[0][j] );
                foreach( k; 1 .. width )
                    ret[i][j] = ret[i][j] + E( data[i][k] * mtr.data[k][j] );
            }

        return ret;
    }

    auto opOpAssign(string op, E)( in E b )
        if( mixin( `is( typeof( this ` ~ op ~ ` b ) == selftype )` ) )
    { mixin( `return this = this ` ~ op ~ ` b;` ); }

    bool opCast(E)() const if( is( E == bool ) )
    { 
        foreach( v; asArray ) if( !isFinite(v) ) return false;
        return true;
    }

    @property auto T() const
    {
        Matrix!(W,H,E) ret;
        static if( isDynamic ) ret.resize(width,height);
        foreach( i; 0 .. height)
            foreach( j; 0 .. width )
                ret[j][i] = data[i][j];
        return ret;
    }
}

unittest
{
    static assert( Matrix!(3,3,float).sizeof == float.sizeof * 9 );
    static assert( Matrix!(3,3,float).isStatic );
    static assert( Matrix!(0,3,float).isDynamic );
    static assert( Matrix!(0,3,float).isDynamicHeight );
    static assert( Matrix!(0,3,float).isStaticWidth );
    static assert( Matrix!(3,0,float).isDynamic );
    static assert( Matrix!(3,0,float).isDynamicWidth );
    static assert( Matrix!(3,0,float).isStaticHeight );
    static assert( Matrix!(0,0,float).isDynamic );
    static assert( Matrix!(0,0,float).isDynamicHeight );
    static assert( Matrix!(0,0,float).isDynamicWidth );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    auto a = mat3( 1,2,3,4,5,6,7,8,9 );
    assert( a.height == 3 );
    assert( a.width == 3 );
    assert( eq( a, [[1,2,3],[4,5,6],[7,8,9]] ) );
    static assert( !__traits(compiles,a.resize(1,1)) );
    a.fill(1);
    assert( eq( a, [[1,1,1], [1,1,1], [1,1,1]] ) );
    a[0][0] *= 3;
    assert( eq( a, [[3,1,1], [1,1,1], [1,1,1]] ) );
    a[1][0] += 3;
    assert( eq( a, [[3,1,1], [4,1,1], [1,1,1]] ) );

    static struct Test
    {
        union
        {
            mat3 um;
            float[9] uf;
        }
    }

    Test tt;

    foreach( i, ref v; tt.uf ) v = i+1;
    assert( eq( tt.um, [[1,2,3],[4,5,6],[7,8,9]] ) );
}

unittest
{
    alias Matrix!(0,3,float) matDx3;
    auto a = matDx3( 1,2,3,4,5,6,7,8,9 );
    assert( mustExcept( {matDx3(1,2,3,4);} ) );
    assert( a.height == 3 );
    assert( a.width == 3 );
    assert( eq( a, [[1,2,3],[4,5,6],[7,8,9]] ) );
    assert( mustExcept({ a.resize(2,2); }) );
    a.resize(2,3);
    assert( eq( a, [[1,2,3],[4,5,6]] ) );
    assert( a.height == 2 );
    a.fill(1);
    assert( eq( a, [[1,1,1],[1,1,1]] ) );
    a.resize(0,3);
    assert( a.width == 3 );
    a.resize(2,3);
    a.fill(1);

    auto b = a;
    assert( eq( b, [[1,1,1],[1,1,1]] ) );
}

unittest
{
    alias Matrix!(3,0,float) mat3xD;
    auto a = mat3xD( 1,2,3,4,5,6,7,8,9 );
    assert( mustExcept( {mat3xD(1,2,3,4);} ) );
    assert( a.height == 3 );
    assert( a.width == 3 );
    assert( eq( a, [[1,2,3],[4,5,6],[7,8,9]] ) );
    assert( mustExcept({ a.resize(2,2); }) );
    a.resize(3,2);
    assert( eq( a, [[1,2],[4,5],[7,8]] ) );
    assert( a.width == 2 );
    a.fill(1);
    assert( eq( a, [[1,1],[1,1],[1,1]] ) );

    auto b = a;
    assert( eq( b, [[1,1],[1,1],[1,1]] ) );
}

unittest
{
    alias Matrix!(0,0,float) matD;
    auto a = matD( 3,3, 1,2,3,4,5,6,7,8,9 );
    assert( mustExcept( {matD(1,2,3,4,5);} ) );
    assert( a.height == 3 );
    assert( a.width == 3 );
    assert( eq( a, [[1,2,3],[4,5,6],[7,8,9]] ) );
    a.resize(2,2);
    assert( eq( a, [[1,2],[4,5]] ) );
    auto b = matD(2,2);
    b.fill(1);
    assert( eq( b, [[1,1],[1,1]] ) );
    b = a;
    assert( eq( a, b ) );
    auto c = matD( Matrix!(2,4,float)(1,2,3,4,5,6,7,8) );
    assert( eq( c, [[1,2,3,4],[5,6,7,8]] ) );
    assert( c.height == 2 );
    assert( c.width == 4 );
    assert( b.height == 2 );
    assert( b.width == 2 );
    b = c;
    assert( b.height == 2 );
    assert( b.width == 4 );
    assert( eq( b, c ) );
    b[0][0] = 666;
    assert( !eq( b, c ) );
}

unittest
{
    alias Matrix!(0,0,float) matD;
    alias Matrix!(3,0,float) mat3xD;
    auto a = mat3xD( 1,2,3,4,5,6,7,8,9 );
    matD b;
    assert( b.height == 0 );
    assert( b.width == 0 );
    b = a;
    assert( b.height == 3 );
    assert( b.width == 3 );
    assert( eq( a, b ) );
    a[0][0] = 22;
    assert( !eq( a, b ) );
    a = b;
    assert( eq( a, b ) );
    b.height = 4;
    assert(  mustExcept({ a = b; }) );
    assert( !mustExcept({ b = a; }) );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    alias Matrix!(0,0,float) matD;
    alias Matrix!(3,0,float) mat3xD;
    alias Matrix!(0,3,float) matDx3;

    auto a = mat3( 1,2,3,4,5,6,7,8,9 );
    auto b = matD( 3,3, 1,2,3,4,5,6,7,8,9 );
    auto c = mat3xD( 1,2,3,4,5,6,7,8,9 );
    auto d = matDx3( 1,2,3,4,5,6,7,8,9 );

    auto eha = a.expandHeight( 8,8,8 );
    auto ehb = b.expandHeight( 8,8,8 );
    auto ehc = c.expandHeight( 8,8,8 );
    auto ehd = d.expandHeight( 8,8,8 );

    assert( eq( eha, [[1,2,3],[4,5,6],[7,8,9],[8,8,8]] ));
    assert( eha.height == 4 );
    assert( ehb.height == 4 );
    assert( ehc.height == 4 );
    assert( ehd.height == 4 );
    assert( eq( eha, ehb ) );
    assert( eq( eha, ehc ) );
    assert( eq( eha, ehd ) );

    static assert( is(typeof(eha) == Matrix!(0,3,float)) );
    static assert( is(typeof(ehd) == Matrix!(0,3,float)) );

    static assert( is(typeof(ehb) == Matrix!(0,0,float)) );
    static assert( is(typeof(ehc) == Matrix!(0,0,float)) );

    auto ewa = a.expandWidth( 8,8,8 );
    auto ewb = b.expandWidth( 8,8,8 );
    auto ewc = c.expandWidth( 8,8,8 );
    auto ewd = d.expandWidth( 8,8,8 );

    assert( eq( ewa, [[1,2,3,8],[4,5,6,8],[7,8,9,8]] ));
    assert( ewa.width == 4 );
    assert( ewb.width == 4 );
    assert( ewc.width == 4 );
    assert( ewd.width == 4 );
    assert( eq( ewa, ewb ) );
    assert( eq( ewa, ewc ) );
    assert( eq( ewa, ewd ) );

    static assert( is(typeof(ewa) == Matrix!(3,0,float)) );
    static assert( is(typeof(ewc) == Matrix!(3,0,float)) );

    static assert( is(typeof(ewb) == Matrix!(0,0,float)) );
    static assert( is(typeof(ewd) == Matrix!(0,0,float)) );

    auto aa = a.expandHeight(a);
    assert( eq( aa, [[1,2,3],[4,5,6],[7,8,9],[1,2,3],[4,5,6],[7,8,9]] ));
    assert( aa.height == 6 );
    static assert( is(typeof(aa) == Matrix!(0,3,float)) );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    auto a = mat3( 1,2,3,4,5,6,7,8,9 );
    assert( a.asArray == [1.0f,2,3,4,5,6,7,8,9] );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    alias Matrix!(0,0,float) matD;
    alias Matrix!(3,0,float) mat3xD;
    alias Matrix!(0,3,float) matDx3;

    auto a = mat3.diag(1);
    assert( eq(a,[[1,0,0],[0,1,0],[0,0,1]]) );
    auto b = mat3xD.diag(1,2);
    assert( eq(b,[[1,0,0],[0,2,0],[0,0,1]]) );
    auto c = mat3xD.diag(1,2,3);
    assert( eq(c,[[1,0,0],[0,2,0],[0,0,3]]) );
    static assert( !__traits(compiles,matD.diag(1)) );
    auto d = matD(3,3).fillDiag(1);
    assert( eq(d,[[1,0,0],[0,1,0],[0,0,1]]) );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    auto a = mat3( 1,2,3,4,5,6,7,8,9 );
    auto sha = a.sliceHeight(1);
    assert( eq(sha,[[4,5,6],[7,8,9]]) );
    auto swsha = sha.sliceWidth(0,1);
    assert( eq(swsha,[[4],[7]]) );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    auto a = mat3.diag(1);
    assert( eq( -a,[[-1,0,0],[0,-1,0],[0,0,-1]]) );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    auto a = mat3.diag(1);
    auto b = a*3-a;
    assert( eq( b,a*2 ) );
    b /= 2;
    assert( eq( b,a ) );
}

unittest
{
    alias Matrix!(3,3,float) mat3;
    alias Matrix!(3,3,real) rmat3;
    alias Matrix!(3,0,real) rmat3xD;

    auto a = rmat3( 3,2,2, 1,3,1, 5,3,4 );
    auto ainv = rmat3xD( 9,-2,-4,  1,2,-1, -12,1,7 ) / 5;

    auto b = a * ainv;
    static assert( is( typeof(b) == Matrix!(3,0,real) ) );
    assert( eq( b, mat3.diag(1) ) );

    static assert( !__traits(compiles,a *= ainv ) );
    a *= rmat3(ainv);
    assert( eq( a, mat3.diag(1) ) );
}

unittest
{
    alias Matrix!(2,4,float) mat2x4;
    alias Matrix!(4,0,float) mat4xD;
    alias Matrix!(4,5,float) mat4x5;

    auto a = mat2x4.init * mat4xD.init;
    assert( mustExcept({ mat4xD.init * mat2x4.init; }) );
    auto b = mat2x4.init * mat4x5.init;

    static assert( is( typeof(a) == Matrix!(2,0,float) ) );
    static assert( is( typeof(b) == Matrix!(2,5,float) ) );
    static assert( is( typeof(mat4xD.init * mat2x4.init) == Matrix!(4,4,float) ) );
}

unittest
{
    alias Matrix!(2,3,float) mat2x3;
    alias Matrix!(4,0,float) mat4xD;

    auto a = mat2x3( 1,2,3, 4,5,6 );
    auto b = mat4xD( 1,2,3,4 );

    auto aT = a.T;
    auto bT = b.T;

    static assert( is( typeof(aT) == Matrix!(3,2,float) ) );
    static assert( is( typeof(bT) == Matrix!(0,4,float) ) );

    assert( bT.height == b.width );
}

