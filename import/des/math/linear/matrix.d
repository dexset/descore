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

module des.math.linear.matrix;

import std.math;
import std.traits;
import std.algorithm;
import std.range;
import std.array;
import std.exception;

import des.util.testsuite;

import des.math.util;
import des.math.linear.vector;
import des.math.linear.quaterni;
import des.math.basic.traits;

///
template isMatrix(E)
{
    enum isMatrix = is( typeof( impl(E.init) ) );
    void impl(size_t H,size_t W,T)( Matrix!(H,W,T) ){}
}

///
template isStaticMatrix(E)
{
    static if( !isMatrix!E )
        enum isStaticMatrix = false;
    else enum isStaticMatrix = E.isStatic;
}

///
template isDynamicMatrix(E)
{
    static if( !isMatrix!E )
        enum isDynamicMatrix = false;
    else enum isDynamicMatrix = E.isDynamic;
}

unittest
{
    static assert( !isStaticMatrix!float );
    static assert( !isDynamicMatrix!float );
}

private @property
{
    import std.string;

    string identityMatrixDataString(size_t S)()
    { return diagMatrixDataString!(S,S)(1); }

    string zerosMatrixDataString(size_t H, size_t W)()
    { return diagMatrixDataString!(H,W)(0); }

    string diagMatrixDataString(size_t H, size_t W)( size_t val )
    {
        string[] ret;
        foreach( i; 0 .. H )
        {
            string[] buf;
            foreach( j; 0 .. W )
                buf ~= format( "%d", i == j ? val : 0 );
            ret ~= "[" ~ buf.join(",") ~ "]";
        }
        return "[" ~ ret.join(",") ~ "]";
    }

    unittest
    {
        assert( identityMatrixDataString!3 == "[[1,0,0],[0,1,0],[0,0,1]]" );
        assert( zerosMatrixDataString!(3,3) == "[[0,0,0],[0,0,0],[0,0,0]]" );
    }

    string castArrayString(string type, size_t H, size_t W)()
    {
        return format( "cast(%s[%d][%d])", type, W, H );
    }

}

/++
 +/
struct Matrix(size_t H, size_t W, E)
{
    ///
    alias selftype = Matrix!(H,W,E);

    ///
    alias datatype = E;

    /// `H == 0 || W == 0`
    enum bool isDynamic = H == 0 || W == 0;
    /// `H != 0 && W != 0`
    enum bool isStatic = H != 0 && W != 0;

    /// `H == 0`
    enum bool isDynamicHeight = H == 0;
    /// `H != 0`
    enum bool isStaticHeight = H != 0;

    /// `W == 0`
    enum bool isDynamicWidth = W == 0;
    /// `W != 0`
    enum bool isStaticWidth = W != 0;

    /// `isStaticHeight && isDynamicWidth`
    enum bool isStaticHeightOnly = isStaticHeight && isDynamicWidth;
    /// `isStaticWidth && isDynamicHeight`
    enum bool isStaticWidthOnly = isStaticWidth && isDynamicHeight;

    /// `isDynamicHeight && isDynamicWidth`
    enum bool isDynamicAll = isDynamicHeight && isDynamicWidth;
    /// `isStaticWidthOnly || isStaticHeightOnly`
    enum bool isDynamicOne = isStaticWidthOnly || isStaticHeightOnly;

    static if( isStatic )
    {
        static if( isNumeric!E )
        {
            static if( H == W )
                /// static data ( if isNumeric!E fills valid numbers: if squred then identity matrix else zeros )
                E[W][H] data = mixin( castArrayString!("E",H,H) ~ identityMatrixDataString!H );
            else 
                E[W][H] data = mixin( castArrayString!("E",H,W) ~ zerosMatrixDataString!(H,W) );
        }
        else E[W][H] data;
    }
    else static if( isStaticWidthOnly )
        /// static width only
        E[W][] data;
    else static if( isStaticHeightOnly )
        /// static height only
        E[][H] data;
    else
        /// full dynamic
        E[][] data;

    ///
    alias data this;

pure:

    private static bool allowSomeOp(size_t A, size_t B )
    { return A==B || A==0 || B==0; }

    static if( isStatic || isDynamicOne )
    {
        /++ fill data and set dynamic size for `isDynamicOne` matrix

            only:
                if( isStatic || isDynamicOne )
         +/
        this(X...)( in X vals )
            if( is(typeof(flatData!E(vals))) )
        {
            static if( isStatic )
            {
                static if( hasNoDynamic!X )
                {
                    static if( X.length > 1 )
                    {
                        static assert( getElemCount!X == W*H, "wrong args count" );
                        static assert( isConvertable!(E,X), "wrong args type" );
                        mixin( matrixStaticFill!("E","data","vals",W,E,X) );
                    }
                    else static if( X.length == 1 && isStaticMatrix!(X[0]) )
                    {
                        static assert( X[0].width == W && X[0].height == H );
                        foreach( y; 0 .. H )
                            foreach( x; 0 .. W )
                                data[y][x] = vals[0][y][x];
                    }
                    else enum __DF=true;
                }
                else enum __DF=true;

                static if( is(typeof(__DF)) )
                    _fillData( flatData!E(vals) );
            }
            else static if( isStaticWidthOnly )
            {
                auto buf = flatData!E(vals);
                enforce( !(buf.length%W), "wrong args length" );
                resize( buf.length/W, W );
                _fillData( buf );
            }
            else static if( isStaticHeightOnly )
            {
                auto buf = flatData!E(vals);
                enforce( !(buf.length%H), "wrong args length" );
                resize( H, buf.length/H );
                _fillData( buf );
            }
        }
    }
    else
    {
        /++ set size and fill data

            only:
                if( isDynamicAll )
         +/
        this(X...)( size_t iH, size_t iW, in X vals )
        {
            auto buf = flatData!E(vals);
            enforce( buf.length == iH * iW || buf.length == 1, "wrong args length" );
            resize( iH, iW );
            _fillData( buf );
        }

        /++ set size

            only:
                if( isDynamicAll )
         +/
        this( size_t iH, size_t iW ) { resize( iH, iW ); }
    }

    ///
    this(size_t oH, size_t oW, X)( in Matrix!(oH,oW,X) mtr )
        if( is( typeof( E(X.init) ) ) )
    {
        static if( isDynamic )
            resize( mtr.height, mtr.width );
        foreach( i; 0 .. mtr.height )
            foreach( j; 0 .. mtr.width )
                data[i][j] = E(mtr[i][j]);
    }

    static if( isDynamic )
    {
        /++
            only:
                if( isDynamic )
         +/
        this(this)
        {
            data = data.dup;
            foreach( ref row; data )
                row = row.dup;
        }

        /++
            only:
                if( isDynamic )
         +/
        ref typeof(this) opAssign(size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) b )
            if( allowSomeOp(H,bH) && allowSomeOp(W,bW) && is(typeof(E(X.init))) )
        {
            static if( isStaticHeight && b.isDynamicHeight ) enforce( height == b.height, "wrong height" );
            static if( isStaticWidth && b.isDynamicWidth ) enforce( width == b.width, "wrong width" );
            static if( isDynamic ) resize(b.height,b.width);
            _fillData(flatData!E(b.data));
            return this;
        }
    }

    private void _fillData( in E[] vals... )
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

    /// fill data
    ref typeof(this) fill( in E[] vals... )
    {
        _fillData( vals );
        return this;
    }

    static if( (W==H && isStatic) || isDynamicOne )
    {
        /++ get diagonal matrix, diagonal elements fills cyclically

            only:
                if( (W==H && isStatic) || isDynamicOne )
         +/
        static auto diag(X...)( in X vals )
        if( X.length > 0 && is(typeof(E(0))) && is(typeof(flatData!E(vals))) )
        {
            selftype ret;
            static if( isStaticHeight ) auto L = H;
            else auto L = W;

            static if( ret.isDynamic )
                ret.resize(L,L);

            ret._fillData( E(0) );
            ret.fillDiag( flatData!E(vals) );

            return ret;
        }
    }

    ///
    ref typeof(this) fillDiag( in E[] vals... )
    {
        enforce( vals.length > 0, "no vals to fill" );
        enforce( height == width, "not squared" );
        size_t k = 0;
        foreach( i; 0 .. height )
            data[i][i] = vals[k++%$];
        return this;
    }

    static if( isStaticHeight )
        /++
            only:
                if( isStaticHeight )
         +/
        enum height = H;
    else
    {
        /// if isStaticHeight it's enum (not available to set)
        @property size_t height() const { return data.length; }
        /// if isStaticHeight it's enum (not available to set)
        @property size_t height( size_t nh )
        {
            resize( nh, width );
            return nh;
        }
    }

    static if( isStaticWidth )
        /++
            only:
                if( isStaticWidth )
         +/
        enum width = W;
    else
    {
        private size_t _width = W;
        /// if isStaticWidth it's enum (not available to set)
        @property size_t width() const { return _width; }
        /// if isStaticWidth it's enum (not available to set)
        @property size_t width( size_t nw )
        {
            resize( height, nw );
            return nw;
        }
    }

    static if( isDynamic )
    {
        /++ resize dynamic matrix, new height/width must equals static height/width

            only:
                if( isDynamic )
         +/
        ref typeof(this) resize( size_t nh, size_t nw )
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
            return this;
        }
    }

    ///
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

    ///
    auto expandHeight(X...)( in X vals ) const
        if( is(typeof(Matrix!(1,W,E)(vals))) )
    { return expandHeight( Matrix!(1,W,E)(vals) ); }

    ///
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

    ///
    auto expandWidth(X...)( in X vals ) const
        if( is(typeof(Matrix!(H,1,E)(vals))) )
    { return expandWidth( Matrix!(H,1,E)(vals) ); }

    ///
    auto asArray() const @property
    {
        auto ret = new E[](width*height);
        foreach( i; 0 .. height )
            foreach( j; 0 .. width )
                ret[i*width+j] = data[i][j];
        return ret;
    }

    ///
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

    ///
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

    ///
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

    ///
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

    ///
    auto opBinary(string op,X)( in X b ) const
        if( (op!="+" && op!="-") && isValidOp!(op,E,X) )
    {
        auto ret = selftype(this);
        foreach( i; 0 .. height )
            foreach( j; 0 .. width )
                mixin( `ret[i][j] = E(data[i][j] ` ~ op ~ ` b);` );
        return ret;
    }

    ///
    auto opBinary(string op,size_t bH, size_t bW, X)( in Matrix!(bH,bW,X) mtr ) const
        if( op=="*" && allowSomeOp(W,bH) && isValidOp!("*",E,X) )
    {
        static if( isDynamic || mtr.isDynamic )
            enforce( width == mtr.height, "incompatible sizes for mul" );
        Matrix!(H,bW,E) ret;
        static if( ret.isDynamic ) ret.resize(height,mtr.width);

        foreach( i; 0 .. height )
            foreach( j; 0 .. mtr.width )
            {
                ret[i][j] = E( data[i][0] * mtr.data[0][j] );
                foreach( k; 1 .. width )
                    ret[i][j] = ret[i][j] + E( data[i][k] * mtr.data[k][j] );
            }

        return ret;
    }

    ///
    ref typeof(this) opOpAssign(string op, E)( in E b )
        if( mixin( `is( typeof( selftype.init ` ~ op ~ ` E.init ) == selftype )` ) )
    { mixin( `return this = this ` ~ op ~ ` b;` ); }

    ///
    bool opCast(E)() const if( is( E == bool ) )
    { 
        foreach( v; asArray ) if( !isFinite(v) ) return false;
        return true;
    }

    /// transponate
    auto T() const @property
    {
        Matrix!(W,H,E) ret;
        static if( isDynamic ) ret.resize(width,height);
        foreach( i; 0 .. height)
            foreach( j; 0 .. width )
                ret[j][i] = data[i][j];
        return ret;
    }

    ///
    ref typeof(this) setCol(X...)( size_t no, in X vals )
        if( is(typeof(flatData!E(vals))) )
    {
        enforce( no < width, "bad col index" );
        auto buf = flatData!E(vals);
        enforce( buf.length == height, "bad data length" );
        foreach( i; 0 .. height )
            data[i][no] = buf[i];
        return this;
    }

    ///
    ref typeof(this) setRow(X...)( size_t no, in X vals )
        if( is(typeof(flatData!E(vals))) )
    {
        enforce( no < height, "bad row index" );
        auto buf = flatData!E(vals);
        enforce( buf.length == width, "bad data length" );
        data[no][] = buf[];
        return this;
    }

    ///
    ref typeof(this) setRect(size_t bH, size_t bW, X)( size_t pos_row, size_t pos_col, in Matrix!(bH,bW,X) mtr )
        if( is(typeof(E(X.init))) )
    {
        enforce( pos_row < height, "bad row index" );
        enforce( pos_col < width, "bad col index" );
        enforce( pos_row + mtr.height <= height, "bad height size" );
        enforce( pos_col + mtr.width <= width, "bad width size" );

        foreach( i; 0 .. mtr.height )
            foreach( j; 0 .. mtr.width )
                data[i+pos_row][j+pos_col] = E(mtr[i][j]);

        return this;
    }

    ///
    auto col( size_t no ) const
    {
        enforce( no < width, "bad col index" );
        Matrix!(H,1,E) ret;
        static if( ret.isDynamic )
            ret.resize(height,1);
        foreach( i; 0 .. height )
            ret[i][0] = data[i][no];
        return ret;
    }

    ///
    auto row( size_t no ) const
    {
        enforce( no < height, "bad row index" );
        Matrix!(1,W,E) ret;
        static if( ret.isDynamic )
            ret.resize(1,width);
        ret[0][] = data[no][];
        return ret;
    }

    ///
    auto opBinary(string op,size_t K,X,alias string AS)( in Vector!(K,X,AS) v ) const
        if( op=="*" && allowSomeOp(W,K) && isValidOp!("*",E,X) && isValidOp!("+",E,E) )
    {
        static if( isDynamic || v.isDynamic )
            enforce( width == v.length, "wrong vector length" );

        static if( isStatic && W == H )
            Vector!(H,E,AS) ret;
        else
            Vector!(H,E) ret;

        static if( ret.isDynamic )
            ret.length = height;

        foreach( i; 0 .. height )
        {
            ret[i] = data[i][0] * v[0];

            foreach( j; 1 .. width )
                ret[i] = ret[i] + E(data[i][j] * v[j]);
        }

        return ret;
    }

    ///
    auto opBinaryRight(string op,size_t K,X,alias string AS)( in Vector!(K,X,AS) v ) const
        if( op=="*" && isVector!(typeof(selftype.init.T * typeof(v).init)) )
    { return this.T * v; }

    static private size_t[] getIndexesWithout(size_t max, in size_t[] arr)
    {
        size_t[] ret;
        foreach( i; 0 .. max ) if( !canFind(arr,i) ) ret ~= i;
        return ret;
    }

    ///
    auto subWithout( size_t[] without_rows=[], size_t[] without_cols=[] ) const
    {
        auto with_rows = getIndexesWithout(height,without_rows);
        auto with_cols = getIndexesWithout(width,without_cols);

        return sub( with_rows,with_cols );
    }

    /// get sub matrix
    auto sub( size_t[] with_rows, size_t[] with_cols ) const
    {
        auto wrows = array( uniq(with_rows) );
        auto wcols = array( uniq(with_cols) );

        enforce( all!(a=>a<height)( wrows ), "bad row index" );
        enforce( all!(a=>a<width)( wcols ), "bad col index" );

        Matrix!(0,0,E) ret;
        ret.resize( wrows.length, wcols.length );

        foreach( i, orig_i; wrows )
            foreach( j, orig_j; wcols )
                ret[i][j] = data[orig_i][orig_j];

        return ret;
    }

    static if( isFloatingPoint!E && ( isDynamicAll ||
                ( isStaticHeightOnly && H > 1 ) ||
                ( isStaticWidthOnly && W > 1 ) ||
                ( isStatic && W == H ) ) )
    {
        ///
        E cofactor( size_t i, size_t j ) const
        { return subWithout([i],[j]).det * coef(i,j); }

        private static nothrow @trusted auto coef( size_t i, size_t j )
        { return ((i+j)%2?-1:1); }
        
        ///
        auto det() const @property 
        {
            static if( isDynamic )
                enforce( width == height, "not square matrix" );

            static if( isDynamic )
            {
                if( width == 1 )
                    return data[0][0];
                else if( width == 2 )
                    return data[0][0] * data[1][1] -
                           data[0][1] * data[1][0];
                else return classicDet;
            }
            else
            {
                static if( W == 1 )
                    return data[0][0];
                else static if( W == 2 )
                    return data[0][0] * data[1][1] -
                           data[0][1] * data[1][0];
                else return classicDet;
            }
        }

        private @property classicDet() const
        {
            auto i = 0UL; // TODO: find max zeros line
            auto ret = data[i][0] * cofactor(i,0);

            foreach( j; 1 .. width )
                ret = ret + data[i][j] * cofactor(i,j);

            return ret;
        }

        ///
        auto inv() const @property
        {
            static if( isDynamic )
                enforce( width == height, "not square matrix" );
            else static assert( W==H, "not square matrix" );

            selftype buf;

            static if( isDynamic )
                buf.resize(height,width);

            foreach( i; 0 .. height )
                foreach( j; 0 .. width )
                    buf[i][j] = cofactor(i,j);

            auto i = 0UL; // TODO: find max zeros line
            auto d = data[i][0] * buf[i][0];

            foreach( j; 1 .. width )
                d = d + data[i][j] * buf[i][j];

            return buf.T / d;
        }

        static if( (isStaticHeightOnly && H==4) ||
                   (isStaticWidthOnly && W==4) ||
                   (isStatic && H==W && H==4) ||
                   isDynamicAll )
        {
            /++ only for transform matrix +/
            @property auto speedTransformInv() const
            {
                static if( isDynamic )
                {
                    enforce( width == height, "not square matrix" );
                    enforce( width == 4, "matrix must be 4x4" );
                }

                selftype ret;
                static if( isDynamic )
                    ret.resize( height, width );

                foreach( i; 0 .. 3 )
                    foreach( j; 0 .. 3 )
                        ret[i][j] = this[j][i];

                auto a22k = 1.0 / this[3][3];

                ret[0][3] = -( ret[0][0] * this[0][3] + ret[0][1] * this[1][3] + ret[0][2] * this[2][3] ) * a22k;
                ret[1][3] = -( ret[1][0] * this[0][3] + ret[1][1] * this[1][3] + ret[1][2] * this[2][3] ) * a22k;
                ret[2][3] = -( ret[2][0] * this[0][3] + ret[2][1] * this[1][3] + ret[2][2] * this[2][3] ) * a22k;

                ret[3][0] = -( this[3][0] * ret[0][0] + this[3][1] * ret[1][0] + this[3][2] * ret[2][0] ) * a22k;
                ret[3][1] = -( this[3][0] * ret[0][1] + this[3][1] * ret[1][1] + this[3][2] * ret[2][1] ) * a22k;
                ret[3][2] = -( this[3][0] * ret[0][2] + this[3][1] * ret[1][2] + this[3][2] * ret[2][2] ) * a22k;
                
                ret[3][3] = a22k * ( 1.0 - ( this[3][0] * ret[0][3] + this[3][1] * ret[1][3] + this[3][2] * ret[2][3] ) );

                return ret;
            }
        }

        ///
        auto rowReduceInv() const @property
        {
            static if( isDynamic )
                enforce( width == height, "not square matrix" );

            auto ln = height;

            auto orig = selftype(this);
            selftype invt;
            static if( isDynamic )
            {
                invt.resize(ln,ln);
                foreach( i; 0 .. ln )
                    foreach( j; 0 .. ln )
                        invt[i][j] = E(i==j);
            }

            foreach( r; 0 .. ln-1 )
            {
                auto k = E(1) / orig[r][r];
                foreach( c; 0 .. ln )
                {
                    orig[r][c] *= k;
                    invt[r][c] *= k;
                }
                foreach( rr; r+1 .. ln )
                {
                    auto v = orig[rr][r];
                    foreach( c; 0 .. ln )
                    {
                        orig[rr][c] -= orig[r][c] * v;
                        invt[rr][c] -= invt[r][c] * v;
                    }
                }
            }

            foreach_reverse( r; 1 .. ln )
            {
                auto k = E(1) / orig[r][r];
                foreach( c; 0 .. ln )
                {
                    orig[r][c] *= k;
                    invt[r][c] *= k;
                }
                foreach_reverse( rr; 0 .. r )
                {
                    auto v = orig[rr][r];
                    foreach( c; 0 .. ln )
                    {
                        orig[rr][c] -= orig[r][c] * v;
                        invt[rr][c] -= invt[r][c] * v;
                    }
                }
            }

            return invt;
        }
    }
}

alias Matrix2(T)   = Matrix!(2,2,T); ///
alias Matrix2x3(T) = Matrix!(2,3,T); ///
alias Matrix2x4(T) = Matrix!(2,4,T); ///
alias Matrix2xD(T) = Matrix!(2,0,T); ///
alias Matrix3x2(T) = Matrix!(3,2,T); ///
alias Matrix3(T)   = Matrix!(3,3,T); ///
alias Matrix3x4(T) = Matrix!(3,4,T); ///
alias Matrix3xD(T) = Matrix!(3,0,T); ///
alias Matrix4x2(T) = Matrix!(4,2,T); ///
alias Matrix4x3(T) = Matrix!(4,3,T); ///
alias Matrix4(T)   = Matrix!(4,4,T); ///
alias Matrix4xD(T) = Matrix!(4,0,T); ///
alias MatrixDx2(T) = Matrix!(0,2,T); ///
alias MatrixDx3(T) = Matrix!(0,3,T); ///
alias MatrixDx4(T) = Matrix!(0,4,T); ///
alias MatrixDxD(T) = Matrix!(0,0,T); ///

alias Matrix!(2,2,float) mat2;   ///
alias Matrix!(2,3,float) mat2x3; ///
alias Matrix!(2,4,float) mat2x4; ///
alias Matrix!(2,0,float) mat2xD; ///
alias Matrix!(3,2,float) mat3x2; ///
alias Matrix!(3,3,float) mat3;   ///
alias Matrix!(3,4,float) mat3x4; ///
alias Matrix!(3,0,float) mat3xD; ///
alias Matrix!(4,2,float) mat4x2; ///
alias Matrix!(4,3,float) mat4x3; ///
alias Matrix!(4,4,float) mat4;   ///
alias Matrix!(4,0,float) mat4xD; ///
alias Matrix!(0,2,float) matDx2; ///
alias Matrix!(0,3,float) matDx3; ///
alias Matrix!(0,4,float) matDx4; ///
alias Matrix!(0,0,float) matD;   ///

alias Matrix!(2,2,double) dmat2;   ///
alias Matrix!(2,3,double) dmat2x3; ///
alias Matrix!(2,4,double) dmat2x4; ///
alias Matrix!(2,0,double) dmat2xD; ///
alias Matrix!(3,2,double) dmat3x2; ///
alias Matrix!(3,3,double) dmat3;   ///
alias Matrix!(3,4,double) dmat3x4; ///
alias Matrix!(3,0,double) dmat3xD; ///
alias Matrix!(4,2,double) dmat4x2; ///
alias Matrix!(4,3,double) dmat4x3; ///
alias Matrix!(4,4,double) dmat4;   ///
alias Matrix!(4,0,double) dmat4xD; ///
alias Matrix!(0,2,double) dmatDx2; ///
alias Matrix!(0,3,double) dmatDx3; ///
alias Matrix!(0,4,double) dmatDx4; ///
alias Matrix!(0,0,double) dmatD;   ///

alias Matrix!(2,2,real) rmat2;   ///
alias Matrix!(2,3,real) rmat2x3; ///
alias Matrix!(2,4,real) rmat2x4; ///
alias Matrix!(2,0,real) rmat2xD; ///
alias Matrix!(3,2,real) rmat3x2; ///
alias Matrix!(3,3,real) rmat3;   ///
alias Matrix!(3,4,real) rmat3x4; ///
alias Matrix!(3,0,real) rmat3xD; ///
alias Matrix!(4,2,real) rmat4x2; ///
alias Matrix!(4,3,real) rmat4x3; ///
alias Matrix!(4,4,real) rmat4;   ///
alias Matrix!(4,0,real) rmat4xD; ///
alias Matrix!(0,2,real) rmatDx2; ///
alias Matrix!(0,3,real) rmatDx3; ///
alias Matrix!(0,4,real) rmatDx4; ///
alias Matrix!(0,0,real) rmatD;   ///

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
    static assert( isStaticMatrix!(mat3) );
    static assert( !isStaticMatrix!(matD) );
    static assert( !isStaticMatrix!(int[]) );
}

unittest
{
    assert( eq( mat3.init, [[1,0,0],[0,1,0],[0,0,1]] ) );
    assert( eq( mat2.init, [[1,0],[0,1]] ) );
    assert( eq( mat2x3.init, [[0,0,0],[0,0,0]] ) );
}

unittest
{
    auto a = Matrix!(3,2,double)( 36, 0, 3, 3, 0, 0 );
    auto b = Matrix!(3,2,double)( [ 36, 0, 3, 3, 0, 0 ] );
    assert( eq( a.asArray, b.asArray ) );
    assert( eq( a.asArray, [ 36, 0, 3, 3, 0, 0 ] ) );
}

unittest
{
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
}

///
unittest
{
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

///
unittest
{
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

///
unittest
{
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
    auto a = mat3( 1,2,3,4,5,6,7,8,9 );
    assert( a.asArray == [1.0f,2,3,4,5,6,7,8,9] );
}

///
unittest
{
    auto a = matD(4,4,0).fillDiag(1);
    assert( eq( a, mat4() ) );
    assert( eq( a.inv, a ) );
}

///
unittest
{
    auto a = mat4x2( 1,2,3,4,5,6,7,8 );
    auto b = mat4( 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 );
    auto c = a.T * b * a;
    static assert( c.height == 2 && c.width == 2 );
}

unittest
{
    matD a;
    matD b;
    a.resize( 10, 4 );
    b.resize( 10, 10 );
    auto c = a.T * b * a;
    assert( c.height == 4 && c.width == 4 );
}

///
unittest
{
    auto a = mat3.diag(1);
    assert( eq(a,[[1,0,0],[0,1,0],[0,0,1]]) );
    auto b = mat3xD.diag(1,2);
    assert( eq(b,[[1,0,0],[0,2,0],[0,0,1]]) );
    auto c = mat3xD.diag(1,2,3);
    assert( eq(c,[[1,0,0],[0,2,0],[0,0,3]]) );
    static assert( !__traits(compiles,matD.diag(1)) );
    auto d = matD(3,3).fill(0).fillDiag(1);
    assert( eq(d,[[1,0,0],[0,1,0],[0,0,1]]) );
}

///
unittest
{
    auto a = mat3( 1,2,3,4,5,6,7,8,9 );
    auto sha = a.sliceHeight(1);
    assert( eq(sha,[[4,5,6],[7,8,9]]) );
    auto swsha = sha.sliceWidth(0,1);
    assert( eq(swsha,[[4],[7]]) );
}

///
unittest
{
    auto a = mat3.diag(1);
    assert( eq( -a,[[-1,0,0],[0,-1,0],[0,0,-1]]) );
}

unittest
{
    auto a = mat3.diag(1);
    auto b = a*3-a;
    assert( eq( b,a*2 ) );
    b /= 2;
    assert( eq( b,a ) );
}

///
unittest
{
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

    auto a = mat2x3( 1,2,3, 4,5,6 );
    auto b = mat4xD( 1,2,3,4 );

    auto aT = a.T;
    auto bT = b.T;

    static assert( is( typeof(aT) == Matrix!(3,2,float) ) );
    static assert( is( typeof(bT) == Matrix!(0,4,float) ) );

    assert( bT.height == b.width );
}

unittest
{
    auto a = mat3.diag(1);

    a.setRow(2,4,5,6);
    assert( eq( a, [[1,0,0],[0,1,0],[4,5,6]] ) );
    a.setCol(1,8,4,2);
    assert( eq( a, [[1,8,0],[0,4,0],[4,2,6]] ) );

    assert( eq( a.row(0), [[1,8,0]] ) );
    assert( eq( a.col(0), [[1],[0],[4]] ) );
}

unittest
{
    auto b = mat3.diag(2) * vec3(2,3,4);
    assert( is( typeof(b) == vec3 ) );
    assert( eq( b, [4,6,8] ) );

    auto c = vec3(1,1,1) * mat3.diag(1,2,3);
    assert( is( typeof(c) == vec3 ) );
    assert( eq( c, [1,2,3] ) );
}

unittest
{
    auto mtr = matD(2,3).fill( 1,2,3, 
                               3,4,7 );

    auto a = mtr * vec3(1,1,1);

    assert( is( typeof(a) == Vector!(0,float) ) );
    assert( a.length == 2 );
    assert( eq( a, [ 6, 14 ] ) );

    auto b = vec3(1,1,1) * mtr.T;
    assert( eq( a, b ) );
}

///
unittest
{
    void check(E)( E mtr ) if( isMatrix!E )
    {
        mtr.fill( 1,2,3,4,
                  5,6,7,8,
                  9,10,11,12,
                  13,14,15,16 );
        auto sm = mtr.subWithout( [0,3,3,3], [1,2] );
        assert( is( typeof(sm) == matD ) );
        assert( sm.width == 2 );
        assert( sm.height == 2 );
        assert( eq( sm, [ [5,8], [9,12] ] ) );
        assert( mustExcept({ mtr.sub( [0,4], [1,2] ); }) );
        auto sm2 = mtr.subWithout( [], [1,2] );
        assert( sm2.width == 2 );
        assert( sm2.height == 4 );
        assert( eq( sm2, [ [1,4],[5,8],[9,12],[13,16] ] ) );
    }

    check( matD(4,4) );
    check( mat4() );
}

unittest
{
    assert( eq( matD(4,4,0).fillDiag(1,2,3,4).det, 24 ) );
}

unittest
{
    auto mtr = rmatD(4,4).fill( 1,2,5,2,
                                5,6,1,4,
                                9,1,3,0,
                                9,2,4,2 );
    auto xx = mtr * mtr.inv;
    assert( eq( xx, matD(4,4,0).fillDiag(1) ) );
}

unittest
{
    auto mtr = matD(4,4).fill( 0,1,0,2,
                               1,0,0,4,
                               0,0,1,1,
                               0,0,0,1 );
    auto vv = vec4(4,2,1,1);
    auto rv = mtr.speedTransformInv * (mtr*vv);
    assert( eq( rv, vv ) );
}

unittest
{
    auto mtr = matD(4,4).fillDiag(1);
    auto vv = vec4(4,2,1,1);
    auto rv = vv * mtr;
    auto vr = mtr.T * vv * mtr;
}

unittest
{
    auto mtr = rmat4.diag(1);
    auto vv = vec4(4,2,1,1);
    auto rv = vv * mtr;
    auto vr = mtr.T * vv * mtr;

    auto xx = mtr * mtr.inv;
    assert( eq( xx, mat4.diag(1) ) );
}

unittest
{
    auto mtr = rmat4( 1,2,5,2,
                      5,6,1,4,
                      9,1,3,0,
                      9,2,4,2 );

    auto xx = mtr * mtr.rowReduceInv;
    assert( eq( xx, mat4() ) );
}

///
unittest
{
    auto mtr = mat4().setRect(0,0,mat3.diag(1)).setCol(3,1,2,3,4);
    assert( eq( mtr, [[1,0,0,1],
                      [0,1,0,2],
                      [0,0,1,3],
                      [0,0,0,4]] ) );
}

unittest
{
    auto stm = mat4();
    assert( stm );
    auto dnm = matD();
    assert( dnm );
}

///
auto quatToMatrix(E)( in Quaterni!E iq )
{
    auto q = iq / iq.len2;

    E wx, wy, wz, xx, yy, yz, xy, xz, zz, x2, y2, z2;

    x2 = q.i + q.i;
    y2 = q.j + q.j;
    z2 = q.k + q.k;
    xx = q.i * x2;   xy = q.i * y2;   xz = q.i * z2;
    yy = q.j * y2;   yz = q.j * z2;   zz = q.k * z2;
    wx = q.a * x2;   wy = q.a * y2;   wz = q.a * z2;

    return Matrix!(3,3,E)( 1.0-(yy+zz),  xy-wz,        xz+wy,
                           xy+wz,        1.0-(xx+zz),  yz-wx,
                           xz-wy,        yz+wx,        1.0-(xx+yy) );
}

///
unittest
{
    auto q = rquat.fromAngle( PI_2, vec3(0,0,1) );

    auto m = quatToMatrix(q);
    auto r = mat3(0,-1, 0, 1, 0, 0, 0, 0, 1);
    assert( eq_approx( m, r, 1e-7 ) );
}

///
auto quatAndPosToMatrix(E,V)( in Quaterni!E iq, in V pos )
    if( isCompatibleVector!(3,E,V) )
{
    auto q = iq / iq.len2;

    E wx, wy, wz, xx, yy, yz, xy, xz, zz, x2, y2, z2;

    x2 = q.i + q.i;
    y2 = q.j + q.j;
    z2 = q.k + q.k;
    xx = q.i * x2;   xy = q.i * y2;   xz = q.i * z2;
    yy = q.j * y2;   yz = q.j * z2;   zz = q.k * z2;
    wx = q.a * x2;   wy = q.a * y2;   wz = q.a * z2;

    return Matrix!(4,4,E)( 1.0-(yy+zz),  xy-wz,        xz+wy,       pos.x,
                           xy+wz,        1.0-(xx+zz),  yz-wx,       pos.y,
                           xz-wy,        yz+wx,        1.0-(xx+yy), pos.z,
                           0,            0,            0,           1     );
}

///
unittest
{
    auto q = rquat.fromAngle( PI_2, vec3(0,0,1) );
    auto m = quatAndPosToMatrix(q, vec3(1,2,3) );
    assert( eq_approx( m, [[0,-1,0,1],
                           [1, 0,0,2],
                           [0, 0,1,3],
                           [0, 0,0,1]], 1e-7 ) );

}
