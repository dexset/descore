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
import std.traits : isNumeric, isFloatingPoint;
import desmath.linear.vector;

private pure nothrow {
    @property string indentstr(size_t H, size_t W)()
    {
        string buf = "[ ";
        foreach( j; 0 .. H )
            foreach( i; 0 .. W )
                static if( W == H )
                    buf ~= i == j ? "1.0f, " : "0.0f, ";
                else
                    buf ~= "0.0f, ";
        return buf ~ " ]";
    }
}

private pure bool ff( size_t[] arr, size_t needle )
{
    import std.algorithm;
    return canFind( arr, needle );
}

private pure nothrow
{
    void isMatrixImpl( size_t H, size_t W, E )( mat!(H,W,E) ){}
    void isCompMatrixImpl( size_t H, size_t W, E, Z )( mat!(H,W,Z) ) if( is( Z : E ) ) {}
}

@property bool isMatrix(E)()
{ return is( typeof( isMatrixImpl(E.init) ) ); }

@property bool isCompMatrix(size_t H, size_t W, E, M)()
{ return is( typeof( isCompMatrixImpl!(H,W,E)( M.init ) ) ); }

class MatException: Exception 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

struct mat( size_t H, size_t W, E=float )
    if( H > 0 && W > 0 && isNumeric!E )
{
    alias mat!(H,W,E) selftype;
    alias E datatype;
    alias H h;
    alias W w;

    E[w*h] data = mixin( indentstr!(H,W) );

    pure this(X...)( in X vals ) 
    {
        static if( isStaticCompatibleArgs!(H*W,E,X) )
            mixin( getAllStaticData!("vals", "data",E,X) );
        else static if( !hasDynamicArray!(X) )
            static assert(0, "bad arguments '" ~ X.stringof ~ "' for " ~ selftype.stringof );
        else
        {
            E[] buf;
            foreach( v; vals )
                buf ~= getDynamicData!E(v);
            if( buf.length != W*H )
                throw new MatException( "bad size" );
            data[] = buf[];
        }
    }

    pure this(X)( in mat!(H,W,X) m ) if( is( X : E ) )
    {
        mixin( generateFor!(W*H)( "data[%1$d] = cast(E)( m.data[%1$d] );" ) );
    }

    auto opAssign(X)( in mat!(H,W,X) m ) if( is( X : E ) )
    {
        static if( is( X == E ) ) data = m.data;
        else mixin( generateFor!(W*H)( "data[%1$d] = cast(E)( m.data[%1$d] );" ) );
        return this;
    }
    
    static auto asRows(S...)( in S vals )
        if( S.length == H && isCompVectors!(W,E,S) )
    { return selftype( vals ); }

    static auto asCols(S...)( in S vals )
        if( S.length == W && isCompVectors!(H,E,S) )
    { 
        selftype ret;
        foreach( i; 0 .. H )
            foreach( j, v; vals )
                ret[i,j] = v[i];
        return ret;
    }

    /+ static constructions +/
    static if( W == H )
    {
        static auto diag(S)( in S[] vals... ) if( is( S : E ) )
        {
            size_t s = vals.length;
            selftype ret;
            foreach( i; 0 .. H )
                foreach( j; 0 .. W )
                    ret[i,j] = i==j ? ( s ? vals[i%s] : 1.0 ) : 0.0;
            return ret;
        }

        static if( isFloatingPoint!E )
        {
            static if( W == 4 )
            {
                static auto fromQuatPos(U,V)( vec!(4,U,"ijka") q, in V pos )
                    if( isCompVector!(3,E,V) )
                {
                    q /= q.len2;

                    E wx, wy, wz, xx, yy, yz, xy, xz, zz, x2, y2, z2;

                    x2 = q.i + q.i;
                    y2 = q.j + q.j;
                    z2 = q.k + q.k;
                    xx = q.i * x2;   xy = q.i * y2;   xz = q.i * z2;
                    yy = q.j * y2;   yz = q.j * z2;   zz = q.k * z2;
                    wx = q.a * x2;   wy = q.a * y2;   wz = q.a * z2;

                    selftype m;

                    m[0,0]=1.0-(yy+zz);  m[0,1]=xy-wz;        m[0,2]=xz+wy;
                    m[1,0]=xy+wz;        m[1,1]=1.0-(xx+zz);  m[1,2]=yz-wx;
                    m[2,0]=xz-wy;        m[2,1]=yz+wx;        m[2,2]=1.0-(xx+yy);

                    m[0,3] = pos[0];
                    m[1,3] = pos[1];
                    m[2,3] = pos[2];

                    m[3,0] = m[3,1] = m[3,2] = 0;
                    m[3,3] = 1;

                    return m;
                }
            }
            else static if( W == 3 )
            {
                static auto fromQuat(U)( vec!(4,U,"ijka") q )
                {
                    q /= q.len2;

                    E wx, wy, wz, xx, yy, yz, xy, xz, zz, x2, y2, z2;

                    x2 = q.i + q.i;
                    y2 = q.j + q.j;
                    z2 = q.k + q.k;
                    xx = q.i * x2;   xy = q.i * y2;   xz = q.i * z2;
                    yy = q.j * y2;   yz = q.j * z2;   zz = q.k * z2;
                    wx = q.a * x2;   wy = q.a * y2;   wz = q.a * z2;

                    selftype m;

                    m[0,0]=1.0-(yy+zz);  m[0,1]=xy-wz;        m[0,2]=xz+wy;
                    m[1,0]=xy+wz;        m[1,1]=1.0-(xx+zz);  m[1,2]=yz-wx;
                    m[2,0]=xz-wy;        m[2,1]=yz+wx;        m[2,2]=1.0-(xx+yy);

                    return m;
                }
            }
        }
    }

    // i - row, j - col
    ref E opIndex( size_t i, size_t j ){ return data[i*W+j]; }
    E opIndex( size_t i, size_t j ) const { return data[i*W+j]; }

    static if( W == 1 || H == 1 )
    {
        enum length = W*H;
        ref E opIndex( size_t i ){ return data[i]; }
        E opIndex( size_t i ) const { return data[i]; }
    }

    /++ row & col access +/
    @property auto col(size_t cno)() const
        if( cno >= 0 && cno < W )
    {
        mat!(H,1,E) ret;
        mixin( generateFor!(H)( "ret[%1$d] = data[cno+%1$d*W];" ) );
        return ret;
    }

    @property auto row(size_t rno)() const
        if( rno >= 0 && rno < H )
    {
        mat!(1,W,E) ret;
        mixin( generateFor!(W)( "ret[%1$d] = data[rno*W+%1$d];" ) );
        return ret;
    }

    @property auto col(size_t cno,V)( in V v )
        if( cno >= 0 && cno < W && ( isCompVector!(H,E,V) || isCompMatrix!(H,1,E,V) ) )
    {
        foreach( i; 0 .. H ) opIndex(i,cno) = v[i];
        return v;
    }

    @property auto row(size_t rno,V)( in V v )
        if( rno >= 0 && rno < H && ( isCompVector!(W,E,V) || isCompMatrix!(1,W,E,V) ) )
    {
        foreach( i; 0 .. W ) opIndex(rno,i) = v[i];
        return v;
    }

    auto setCol(V)( size_t cno, in V v )
        if( isCompVector!(H,E,V) || isCompMatrix!(H,1,E,V) )
    {
        foreach( i; 0 .. H ) opIndex(i,cno) = v[i];
        return v;
    }

    auto setRow(V)( size_t rno, in V v )
        if( isCompVector!(W,E,V) || isCompMatrix!(1,W,E,V) )
    {
        foreach( i; 0 .. W ) opIndex(rno,i) = v[i];
        return v;
    }

    /++/

    @property auto T() const
    {
        mat!(W,H,E) r;
        mixin( generateFor2!(H,W)( "r[%2$d,%1$d] = this[%1$d,%2$d];" ) );
        return r;
    }

    auto opUnary(string op)() const
        if( op == "-" )
    {
        selftype r = this;
        r.data[] *= -1;
        return r;
    }

    auto opBinary(string op,X)( in mat!(H,W,X) b ) const
        if( op == "+" || op == "-" )
    {
        mat!(H,W,E) ret;
        mixin( generateFor!(H*W)( "ret.data[%1$d] = cast(E)(data[%1$d] " ~ op ~ " b.data[%1$d]);" ) );
        return ret;
    }

    auto opOpAssign(string op,X)( in mat!(H,W,X) b )
        if( op == "+" || op == "-" )
    { return ( this = opBinary!op(b) ); }

    auto opBinary(string op,X)( in X b ) const
        if( ( op == "*" || op == "/" ) && isNumeric!X )
    {
        mat!(H,W,E) ret;
        mixin( generateFor!(H*W)( "ret.data[%1$d] = cast(E)(data[%1$d] " ~ op ~ " b);" ) );
        return ret;
    }

    auto opOpAssign(string op,X)( in X b )
        if( ( op == "*" || op == "/" ) && is( X : E ) )
    { return ( this = opBinary!op(b) ); }

    static pure private @property string gen_matrix_mult(size_t HH, size_t WW, size_t MM)()
    {
        import std.string;
        string[] res;
        foreach( i; 0 .. HH )
            foreach( j; 0 .. MM )
            {
                string[] res_arr;
                foreach( k; 0 .. WW )
                    res_arr ~= format( "a[%d,%d]*b[%d,%d]", i,k,k,j );
                res ~= format( "ret[%d,%d] = ", i, j ) ~ res_arr.join(" + ") ~ ";";
            }
        return res.join("\n");
    }

    auto opBinary(string op, size_t M,X)( in mat!(W,M,X) b ) const
        if( op == "*" && is( generalType!(E,X) ) )
    {
        mat!(H,M,E) ret;
        alias this a;
        mixin( gen_matrix_mult!(H,W,M) );
        return ret;
    }

    bool opCast(E)() const if( is( E == bool ) )
    { 
        foreach( v; data ) if( !isFinite(v) ) return false;
        return true;
    }

    static pure private @property string gen_matrix_mult_vector(size_t HH, size_t WW)()
    {
        import std.string;
        string[] res;
        foreach( i; 0 .. HH )
        {
            string[] res_arr;
            foreach( j; 0 .. WW )
                res_arr ~= format( "a[%d,%d]*b[%d]", i,j,j );
            res ~= format( "ret[%d] = ", i ) ~ res_arr.join(" + ") ~ ";";
        }
        return res.join("\n");
    }

    // vector as column
    auto opBinary(string op, X)( in X b ) const
        if( op == "*" && isCompVector!(W,E,X) )
    {
        vec!(H,generalType!(E,X.datatype),H==W?X.accessString:"") ret;
        alias this a;
        mixin( gen_matrix_mult_vector!(H,W) );
        return ret;
    }

    auto opBinaryRight(string op, X)( in X b ) const
        if( op == "*" && isCompVector!(H,E,X) )
    {
        vec!(W,E,H==W?X.accessString:"") ret;
        alias this a;
        mixin( gen_matrix_mult_vector!(H,W) );
        return ret;
    }

    static if( H > 1 && W > 1 )
    {
        auto sub(size_t nH=1, size_t nW=1)( size_t[nH] wR, size_t[nW] wC ) const
            if( nH > 0 && nH < H && nW > 0 && nW < W )
        {
            mat!(H-nH,W-nW,E) ret;

            size_t i=0, j=0;

            foreach( ii; 0 .. H )
            {
                if( ff( wR, ii ) ) continue;
                j=0;
                foreach( jj; 0 .. W )
                {
                    if( ff( wC, jj ) ) continue;
                    ret[i,j] = opIndex(ii, jj);
                    j++;
                }
                i++;
            }
            return ret;
        }
    }

    static if( W == H )
    {
        // TODO: первый элемент не должен быть нулём 
        @property auto rowReduceInv() const
        {
            E[W][H] orig;
            E[W*H] invt;
            foreach( r, ref row; orig )
                foreach( c, ref v; row )
                {
                    v = this[r,c];
                    invt[r*W+c] = c == r;
                }

            foreach( r; 0 .. H-1 )
            {
                size_t n = r+1;
                foreach( rr; n .. H )
                {
                    E k = orig[rr][r] / orig[r][r];
                    foreach( c; 0 .. W )
                    {
                        orig[rr][c] -= k * orig[r][c];
                        invt[rr*W+c] -= k * invt[r*W+c];
                    }
                }
            }

            foreach_reverse( r; 0 .. H-1 )
            {
                size_t n = r+1;
                foreach( rr; 0 .. n )
                {
                    E k = orig[rr][n] / orig[n][n];
                    foreach( c; 0 .. W )
                    {
                        orig[rr][c] -= k * orig[n][c];
                        invt[rr*W+c] -= k * invt[n*W+c];
                    }
                }
            }

            foreach( r; 0 .. H )
            {
                E ident = orig[r][r];
                foreach( c; 0 .. W )
                {
                    orig[r][c] /= ident;
                    invt[r*W+c] /= ident;
                }
            }

            return selftype( invt );
        }

        static if( W == 1 )
        {
            @property E det() const { return data[0]; }

            @property auto inv() const
            { return selftype( 1.0 / data[0] ); }
        }
        else static if( W == 2 )
        {
            @property E det() const
            { return this[0,0] * this[1,1] - this[0,1] * this[1,0]; }

            @property auto inv() const
            { return selftype( this[1,1], -this[1,0], -this[0,1],  this[0,0] ).T / det; }
        }
        else static if( W == 3 )
        {
            @property E det() const
            {
                alias this a;
                return
                 a[0,0] * (a[1,1]*a[2,2]-a[1,2]*a[2,1]) +
                -a[0,1] * (a[1,0]*a[2,2]-a[1,2]*a[2,0]) +
                 a[0,2] * (a[1,0]*a[2,1]-a[1,1]*a[2,0]);
            }

            @property auto inv() const
            {
                alias this a;

                /+ для удобства
                    a.data = [ a[0,0], a[0,1], a[0,2],
                               a[1,0], a[1,1], a[1,2],
                               a[2,0], a[2,1], a[2,2] ];
                 +/

                auto A = selftype( [
                 (a[1,1]*a[2,2]-a[1,2]*a[2,1]), 
                -(a[1,0]*a[2,2]-a[1,2]*a[2,0]), 
                 (a[1,0]*a[2,1]-a[1,1]*a[2,0]),

                -(a[0,1]*a[2,2]-a[0,2]*a[2,1]), 
                 (a[0,0]*a[2,2]-a[0,2]*a[2,0]), 
                -(a[0,0]*a[2,1]-a[0,1]*a[2,0]),

                 (a[0,1]*a[1,2]-a[0,2]*a[1,1]), 
                -(a[0,0]*a[1,2]-a[0,2]*a[1,0]), 
                 (a[0,0]*a[1,1]-a[0,1]*a[1,0]),
                               ] );
                return A.T / ( a[0,0] * A[0,0] + a[0,1] * A[0,1] + a[0,2] * A[0,2] );
            }
        }
        else
        {
            @property E det() const 
            { 
                E res = 0;

                foreach( i; 0 .. W )
                    res += (i%2?-1:1) * this[0,i] * sub!(1,1)( [0], [i] ).det;

                return res;
            }

            @property auto inv() const
            { 
                selftype A;
                E d = 0;
                foreach( i; 0 .. H )
                {
                    foreach( j; 0 .. W )
                    {
                        A[i,j] = ((i+j)%2?-1:1) * sub!(1,1)( [i],[j] ).det;
                        if( i == 0 ) d += this[0,j] * A[i,j];
                    }
                }
                return A.T / d;
            }
        }

        static if( W == 4 )
        {
            @property auto speedTransformInv() const
            {
                selftype ret;

                mixin( generateFor2!(3,3)( "ret[%2$d,%1$d] = this[%1$d,%2$d];" ) );

                auto a22k = 1.0 / this[3,3];

                ret[0,3] = -( ret[0,0] * this[0,3] + ret[0,1] * this[1,3] + ret[0,2] * this[2,3] ) * a22k;
                ret[1,3] = -( ret[1,0] * this[0,3] + ret[1,1] * this[1,3] + ret[1,2] * this[2,3] ) * a22k;
                ret[2,3] = -( ret[2,0] * this[0,3] + ret[2,1] * this[1,3] + ret[2,2] * this[2,3] ) * a22k;

                ret[3,0] = -( this[3,0] * ret[0,0] + this[3,1] * ret[1,0] + this[3,2] * ret[2,0] ) * a22k;
                ret[3,1] = -( this[3,0] * ret[0,1] + this[3,1] * ret[1,1] + this[3,2] * ret[2,1] ) * a22k;
                ret[3,2] = -( this[3,0] * ret[0,2] + this[3,1] * ret[1,2] + this[3,2] * ret[2,2] ) * a22k;
                
                ret[3,3] = a22k * ( 1.0 - ( this[3,0] * ret[0,3] + this[3,1] * ret[1,3] + this[3,2] * ret[2,3] ) );

                return ret;
            }
        }

    }

}

template col( size_t H, E=float ){ alias mat!(H,1,E) col; }
template row( size_t W, E=float ){ alias mat!(1,W,E) row; }

alias mat!(2,2) mat2;
alias mat!(3,3) mat3;
alias mat!(4,4) mat4;

alias mat!(2,3) mat2x3;
alias mat!(3,2) mat3x2;
alias mat!(2,4) mat2x4;
alias mat!(4,2) mat4x2;
alias mat!(3,4) mat3x4;
alias mat!(4,3) mat4x3;

alias mat!(1,2) mat1x2;
alias mat!(1,3) mat1x3;
alias mat!(1,4) mat1x4;
alias mat!(2,1) mat2x1;
alias mat!(3,1) mat3x1;
alias mat!(4,1) mat4x1;

alias mat!(2,2,double) dmat2;
alias mat!(3,3,double) dmat3;
alias mat!(4,4,double) dmat4;

alias mat!(2,3,double) dmat2x3;
alias mat!(3,2,double) dmat3x2;
alias mat!(2,4,double) dmat2x4;
alias mat!(4,2,double) dmat4x2;
alias mat!(3,4,double) dmat3x4;
alias mat!(4,3,double) dmat4x3;

alias mat!(1,2,double) dmat1x2;
alias mat!(1,3,double) dmat1x3;
alias mat!(1,4,double) dmat1x4;
alias mat!(2,1,double) dmat2x1;
alias mat!(3,1,double) dmat3x1;
alias mat!(4,1,double) dmat4x1;

alias mat!(2,2,real) rmat2;
alias mat!(3,3,real) rmat3;
alias mat!(4,4,real) rmat4;

alias mat!(2,3,real) rmat2x3;
alias mat!(3,2,real) rmat3x2;
alias mat!(2,4,real) rmat2x4;
alias mat!(4,2,real) rmat4x2;
alias mat!(3,4,real) rmat3x4;
alias mat!(4,3,real) rmat4x3;

alias mat!(1,2,real) rmat1x2;
alias mat!(1,3,real) rmat1x3;
alias mat!(1,4,real) rmat1x4;
alias mat!(2,1,real) rmat2x1;
alias mat!(3,1,real) rmat3x1;
alias mat!(4,1,real) rmat4x1;

version(unittest) import std.stdio;

unittest
{

    auto cl = col!3( [1,2,3] );
    assert( cl[0,0] == 1 && cl[1,0] == 2 && cl[2,0] == 3 );
    assert( cl[0] == 1 && cl[1] == 2 && cl[2] == 3 );
    assert( cl.length == 3 );

    assert( mat3().col!(0).data == [1,0,0] );
    assert( mat3().col!(1).data == [0,1,0] );

    assert( mat3().row!(0).data == [1,0,0] );
    assert( mat3().row!(1).data == [0,1,0] );

    auto mr = mat3();
    mr.row!1 = vec3( 2,3,4 );
    assert( mr.data == [ 1, 0, 0, 2, 3, 4, 0, 0, 1 ] );

    mr.col!2 = vec3( 4,5,6 );
    assert( mr.data == [ 1, 0, 4, 2, 3, 5, 0, 0, 6 ] );

    assert( mr.T.data == [ 1, 2, 0, 0, 3, 0, 4, 5, 6 ] );

    assert( (-mr).T.data == [ -1, -2, 0, 0, -3, 0, -4, -5, -6 ] );

    assert( (mr + mr).data == [ 2, 0, 8, 4, 6, 10, 0, 0, 12 ] );
    mr += mr;
    assert( mr.data == [ 2, 0, 8, 4, 6, 10, 0, 0, 12 ] );
    mr /= 2.0;
    assert( mr.data == [ 1, 0, 4, 2, 3, 5, 0, 0, 6 ] );

    assert( mat4() * mat4() == mat4() );
    assert( mat4() );

    assert( mat4() * vec4( 1,2,3,4 ) == vec4( 1,2,3,4 ) );
    assert( vec4( 1,2,3,4 ) * mat4() == vec4( 1,2,3,4 ) );

    assert( is( typeof( mat4() + rmat4() ) == mat4 ) );
    assert( is( typeof( rmat4() + mat4() ) == rmat4 ) );
}

unittest
{
    mat4 x;
    assert( x.data == [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ] );

    auto m = mat3( 1,2,3,4,5,6,7,8,9 );
    assert( m.data == [ 1,2,3,4,5,6,7,8,9 ] );
    auto k = rmat3(m);
    assert( k.data == [ 1,2,3,4,5,6,7,8,9 ] );
    assert( is( k.datatype == real ) );

    auto mfv = mat3x2.asCols( vec3(1,2,3), vec3(3,4,5) );
    assert( mfv.data == [ 1,3, 2,4, 3,5 ] );
    assert( !is( typeof( mat3x2.asRows( vec3(1,2,3), vec3(3,4,5) ) ) ) );
    auto mfv2 = mat3x2.asRows( vec2(1,2), 
                               vec2(4,5),
                               vec2(9,8) );
    assert( mfv2.data == [ 1,2, 4,5, 9,8 ] );

    auto d = mat4.diag( 1,2,3,4 );
    assert( d.data == [ 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4 ] );

    auto qm = mat3.fromQuat( quat( 0,0,0,1 ) );
    assert( qm.data == [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ] );

    auto qpm = mat4.fromQuatPos( quat.fromAngle( PI_2, vec3(0,0,1) ), vec3(2,3,4) );
    auto qpm_res = [ 0,-1, 0, 2, 1, 0, 0, 3, 0, 0, 1, 4, 0, 0, 0, 1 ];
    float r = 0;
    foreach( i; 0 .. 16 ) r += abs( qpm.data[i] - qpm_res[i] );
    assert( r < float.epsilon * 9 );

    assert( qpm[0,3] == 2 );

    auto vec_result = qm * vec3( 1,2,3 );
    assert( is( typeof( vec_result ) == vec3 ) );

    auto mb = mat!(8,3,real)();
    auto k2 = mb * vec3( 1,2,3 );
    assert( is( typeof( k2 ) == vec!(8,real,"") ) );

    assert( is( typeof( mat!(4,2)() * mat!(2,8,real)() ) == mat!(4,8,float) ) );
}

unittest
{
    mat!(3,7) a;
    mat!(7,4) b;
    mat!(4,2) c;
    auto k = a * b * c;
    assert( is( typeof(k) == mat!(3,2) ) );
}

unittest
{
    mat!(4,4) a;
    auto b = a.sub!(1,1)( [0], [3] );
    assert( b == mat!(3,3)( [ 0, 1, 0, 0, 0, 1, 0, 0, 0 ] ));

    auto c = a.sub!(3,1)( [0,2,3], [2] );
    assert( c == mat!(1,3)( [ 0, 1, 0 ] ) );
}

unittest
{
    auto k = mat!(1,1)( 8 );
    auto r = k * k.inv;

    double rs = 0;
    foreach( v; r.data )
        rs += v;

    assert( abs(rs-k.h) < 2e-6 );
}

unittest
{
    auto k = mat!(2,2)( 1,2,3,4 );
    auto r = k * k.inv;

    double rs = 0;
    foreach( v; r.data )
        rs += v;

    assert( abs(rs-k.h) < 2e-6 );
}

unittest
{
    auto k = mat!(5,5)( 1, 3, 9, 8, 2,
                        3, 2, 6, 2, 1,
                        4, 8, 8, 7, 5,
                        9, 2, 7, 0, 2,
                        2, 1, 4, 2, 1 );

    auto r = k * k.inv;

    double rs = 0;
    foreach( v; r.data )
        rs += v;

    assert( abs(rs-k.h) < 2e-6 );
}

unittest
{
    auto k = mat!(5,5)( 1, 3, 9, 8, 2,
                        3, 2, 6, 2, 1,
                        4, 8, 8, 7, 5,
                        9, 2, 7, 0, 2,
                        2, 1, 4, 2, 1 );

    auto r = k * k.rowReduceInv;

    double rs = 0;
    foreach( v; r.data )
        rs += v;

    assert( abs(rs-k.h) < 2e-5 );
}
