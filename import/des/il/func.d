module des.il.func;

import std.algorithm;
import std.traits;
import std.range;

import des.il.util;
import des.il.image;
import des.il.region;

import des.math.linear.vector;

import std.c.string : memcpy;

enum ImRepack
{
    NONE,
    ROT90,
    ROT180,
    ROT270,
    HORMIR,
    VERMIR
}

auto imRepackRegion(T)( in Image2 img, Region!(2,T) reg, ImRepack tr )
    if( isIntegral!T )
{
    Image2 ret;

    if( tr == ImRepack.NONE ) return imCopy( img, reg );

    ret = Image2( imGetResultTrSize( CrdVector!2(reg.size), tr ), img.info );

    auto trfunc = imGetTrCrdFunc( tr );

    size_t H = reg.size.x, W = reg.size.y;
    size_t rW = ret.size.y;
    size_t bpe = img.info.bpe;

    size_t rx, ry;
    foreach( y; 0 .. H )
        foreach( x; 0 .. W )
        {
            auto src = ((y+reg.pos.y)*img.size.x+x+reg.pos.x) * bpe;
            trfunc( x, y, W, H, rx, ry );
            auto dst = (ry*rW+rx) * bpe;
            ret.data[dst..dst+bpe] = img.data[src..src+bpe];
        }

    return ret;
}

CrdVector!2 imGetResultTrSize( CrdVector!2 size, ImRepack tr )
{
    switch( tr )
    {
        case ImRepack.ROT90:
        case ImRepack.ROT270:
            return size.yx;
        default: return size;
    }
}

void function( size_t, size_t, size_t, size_t,
               ref size_t, ref size_t ) imGetTrCrdFunc( ImRepack tr )
{
    final switch( tr )
    {
        case ImRepack.ROT90:  return &imRotCrd90;
        case ImRepack.ROT180: return &imRotCrd180;
        case ImRepack.ROT270: return &imRotCrd270;
        case ImRepack.HORMIR: return &imHorMirCrd;
        case ImRepack.VERMIR: return &imVerMirCrd;
        case ImRepack.NONE: assert( 0, "WTF? ImRepack.NONE must process before" );
    }
}

void imNoneTrCrd( size_t px, size_t py, size_t sx, size_t sy,
                  ref size_t rx, ref size_t ry )
{ rx=px; ry=py; }

void imRotCrd90( size_t px, size_t py, size_t sx, size_t sy,
                  ref size_t rx, ref size_t ry )
{ rx=py; ry=sx-1-px; }

void imRotCrd180( size_t px, size_t py, size_t sx, size_t sy,
                  ref size_t rx, ref size_t ry )
{ rx=sx-1-px; ry=sy-1-py; }

void imRotCrd270( size_t px, size_t py, size_t sx, size_t sy,
                  ref size_t rx, ref size_t ry )
{ rx=sy-1-py; ry=px; }

void imHorMirCrd( size_t px, size_t py, size_t sx, size_t sy,
                  ref size_t rx, ref size_t ry )
{ rx=sx-1-px; ry=py; }

void imVerMirCrd( size_t px, size_t py, size_t sx, size_t sy,
                  ref size_t rx, ref size_t ry )
{ rx=px; ry=sy-1-py; }

auto imRepack( in Image!3 img, ImRepack tr )
{
    pragma(msg,"TODO THIS: ",__FILE__," ",__LINE__);
}

/// copy image region to new image
auto imCopy(size_t N,T)( in Image!N img, in Region!(N,T) r )
if( isIntegral!T )
{
    auto ret = Image!N( r.size, img.info );

    alias Reg = Region!(N,ptrdiff_t);
    alias SV = CrdVector!N;

    auto crop = Reg( SV(), img.size ).overlapLocal(r);
    auto bpe = img.info.bpe;

    auto count = reduce!((s,v)=>s*=v)( crop.size );

    foreach( i; 0 .. count )
    {
        auto lccrd = CrdVector!N( getCoord( crop.size, i ) );
        auto ret_crd = -SV(r.pos) + crop.pos + lccrd;
        auto img_crd =  crop.pos + lccrd;
        auto ret_offset = getIndex( ret.size, ret_crd );
        auto img_offset = getIndex( img.size, img_crd );
        memcpy( ret.data.ptr + ret_offset * bpe,
                img.data.ptr + img_offset * bpe, bpe );
    }

    return ret;
}

///
unittest
{
    auto a = Image1( ivec!1(5), ElemInfo( DataType.FLOAT, 2 ) );
    a.pixel!vec2(3) = vec2(1,1);
    a.pixel!vec2(4) = vec2(2,2);
    auto b = imCopy( a, Region!(1,int)(3,2) );
    assert( b.pixel!vec2(0) == a.pixel!vec2(3) );
    assert( b.pixel!vec2(1) == a.pixel!vec2(4) );
}

///
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

    auto orig = Image2( ivec2(5,5), DataType.UBYTE, 1, data );
    auto im = imCopy( orig, iRegion2( 0, 0, 5, 5 ) );
    assert( orig == im );
    
    auto imv1 = Image2( ivec2( 7, 7 ), DataType.UBYTE, 1, datav1 );
    assert( imCopy( orig, iRegion2( -1, -1, 7, 7 ) ) == imv1 );

    auto imv2 = Image2( ivec2(3,3), DataType.UBYTE, 1, datav2 );
    assert( imCopy( orig, iRegion2( 1, 1, 3, 3 ) ) == imv2 );

    auto imv3 = Image2( ivec2(4,4), DataType.UBYTE, 1, datav3 );
    assert( imCopy( orig, iRegion2( -1, -1, 4, 4 ) ) == imv3 );

    auto imv4 = Image2( ivec2(4,4), DataType.UBYTE, 1, datav4 );
    assert( imCopy( orig, iRegion2( 2, -1, 4, 4 ) ) == imv4 );

    auto imv5 = Image2( ivec2(4,4), DataType.UBYTE, 1, datav5 );
    assert( imCopy( orig, iRegion2( -1, 2, 4, 4 ) ) == imv5 );

    auto imv6 = Image2( ivec2(4,4), DataType.UBYTE, 1, datav6 );
    assert( imCopy( orig, iRegion2( 2, 2, 4, 4 ) ) == imv6 );
}

/// paste in image other image
void imPaste(size_t N,V)( ref Image!N img, in Vector!(N,V) pos, in Image!N pim )
    if( isIntegral!V )
{
    enforce( pim.info == img.info,
        new ImageException( "Image info is wrong for paste." ) );

    alias Reg = Region!(N,ptrdiff_t);
    alias SV = CrdVector!N;

    auto pim_reg = Reg( pos, pim.size );

    auto crop = Reg( SV(), img.size ).overlapLocal( pim_reg );
    auto bpe = img.info.bpe;

    auto count = reduce!((s,v)=>s*=v)( crop.size );

    foreach( i; 0 .. count )
    {
        auto lccrd = getCoord( crop.size, i );
        auto pim_crd = -SV(pos) + crop.pos + lccrd;
        auto img_crd =  crop.pos + lccrd;
        auto pim_offset = getIndex( pim.size, pim_crd );
        auto img_offset = getIndex( img.size, img_crd );
        memcpy( img.data.ptr + img_offset * bpe,
                pim.data.ptr + pim_offset * bpe, bpe );
    }
}

///
unittest 
{
    ubyte[] data = 
    [
        2, 1, 3, 5, 2,
        9, 1, 2, 6, 3,
        2, 5, 2, 9, 1,
        8, 3, 6, 3, 0,
        6, 2, 8, 1, 5 
    ];

    ubyte[] datav1 = 
    [
        1, 2, 6, 3, 0, 0, 0,
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
        0, 9, 1, 2, 6, 3, 0,
        0, 2, 5, 2, 9, 1, 0,  
        0, 8, 3, 6, 3, 0, 0,
        0, 6, 2, 8, 1, 5, 0,
        0, 0, 0, 0, 0, 0, 0
    ];


    auto orig = Image2( ivec2( 7, 7 ), ElemInfo( DataType.UBYTE, 1 ) );
    auto im = Image2( ivec2( 5, 5 ), DataType.UBYTE, 1, data );

    auto res = Image2(orig);
    imPaste( res, ivec2(-1,-1), im );
    assert( res.data == datav1 );

    res = Image2(orig);
    imPaste( res, ivec2(1,1), im );
    assert( res.data == datav2 );
}

///
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

    auto src = Image2( ivec2(3,3), ElemInfo( DataType.UBYTE, 1 ), src_data );
    auto dst = Image3( ivec3(3,3,3), ElemInfo( DataType.UBYTE, 1 ) );
    imPaste( dst, ivec3(0,0,1), Image3( src ) );
    assert( dst.data == dst1_data );
    dst.clear();
    imPaste( dst, ivec3(1,0,0), Image3(src,0) );
    assert( dst.data == dst2_data );
}

///
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

    auto a = Image3( ivec3(4,4,4), ElemInfo( DataType.UBYTE, 1 ), dt );
    auto b = Image3( ivec3(4,4,4), ElemInfo( DataType.UBYTE, 1 ), cp );
    auto c = Image3( ivec3(4,4,4), ElemInfo( DataType.UBYTE, 1 ) );

    auto part = imCopy( a, iRegion3( ivec3(1,1,1), ivec3(2,2,2) ) );

    imPaste( c, ivec3(0,0,0), part );
    imPaste( c, ivec3(0,2,0), part );
    imPaste( c, ivec3(2,0,0), part );
    imPaste( c, ivec3(2,2,0), part );

    imPaste( c, ivec3(0,0,2), part );
    imPaste( c, ivec3(0,2,2), part );
    imPaste( c, ivec3(2,0,2), part );
    imPaste( c, ivec3(2,2,2), part );

    assert( b == c );

    auto part2 = imCopy( b, iRegion3(ivec3(1,1,1), ivec3(2,2,2)) );
    auto rr = Image3( ivec3(2,2,2), ElemInfo( DataType.UBYTE, 1 ), rs );
    assert( rr == part2 );

    auto nn = imCopy( rr, iRegion3( ivec3(-1,-1,-1), ivec3(2,2,2) ) );
    auto nndi = Image3( ivec3(2,2,2), ElemInfo( DataType.UBYTE,1 ), nnd );

    assert( nn == nndi );
}

/++ get histogram convolution 
    +/
Image!(N-1) imHistoConv(size_t N)( in Image!N img, size_t K ) pure
if( N > 1 )
in { assert( K < N ); } body
{
    auto ret = Image!(N-1)( ivec!(N-1)( removeStat( img.size, K ) ), img.info );

    auto bpe = img.info.bpe;

    foreach( i; 0 .. ret.header.pixelCount )
    {
        auto buf = ret.data.ptr + i * bpe;
        utDataAssign( img.info, buf, 0 );
        foreach( j; 0 .. img.size[K] )
            utDataOp!"+"( img.info, buf,
            cast(void*)( img.data.ptr + getOrigIndexByLayerCoord( img.size, K, i, j ) * bpe ) );
    }

    return ret;
}

///
unittest
{
    ubyte[] img_data =
    [
        1,2,5,8,
        4,3,1,1
    ];

    ubyte[] hi_x_data = [ 16, 9 ];
    ubyte[] hi_y_data = [ 5, 5, 6, 9 ];

    auto img = Image2( ivec2(4,2), ElemInfo( DataType.UBYTE, 1 ), img_data );
    auto hi_x = Image1( ivec!1(2), ElemInfo( DataType.UBYTE, 1 ), hi_x_data );
    auto hi_y = Image1( ivec!1(4), ElemInfo( DataType.UBYTE, 1 ), hi_y_data );

    assert( imHistoConv(img,0) == hi_x );
    assert( imHistoConv(img,1) == hi_y );
}

/++ get layer of image
    +/
Image!(N-1) imLayer(size_t N)( Image!N img, size_t K, size_t lno ) pure
{
    auto ret = Image!(N-1)( ivec!(N-1)( removeStat( img.size, K ) ), img.info );
    auto bpe = img.info.bpe;
    foreach( i; 0 .. ret.header.pixelCount )
        memcpy( ret.data.ptr + i * bpe, img.data.ptr + getOrigIndexByLayerCoord(img.size,K,i,lno) * bpe, bpe );
    return ret;
}

///
unittest
{
    ubyte[] img_data =
    [
        1,2,3,
        4,5,6,
        
        7,8,9,
        10,11,12,
    ];

    auto info = ElemInfo( DataType.UBYTE, 1 );

    ubyte[] d2l0 = [ 1,2,3,4,5,6 ];
    ubyte[] d2l1 = [ 7,8,9,10,11,12 ];

    ubyte[] d1l0 = [ 1,2,3,7,8,9 ];
    ubyte[] d1l1 = [ 4,5,6,10,11,12 ];

    ubyte[] d0l0 = [ 1, 4, 7, 10 ];
    ubyte[] d0l1 = [ 2, 5, 8, 11 ];

    auto img = Image3( ivec3(3,2,2), info, img_data );
    auto id2l0 = Image2( ivec2(3,2), info, d2l0 );
    auto id2l1 = Image2( ivec2(3,2), info, d2l1 );
    auto id1l0 = Image2( ivec2(3,2), info, d1l0 );
    auto id1l1 = Image2( ivec2(3,2), info, d1l1 );
    auto id0l0 = Image2( ivec2(2,2), info, d0l0 );
    auto id0l1 = Image2( ivec2(2,2), info, d0l1 );

    assert( imLayer(img,2,0) == id2l0 );
    assert( imLayer(img,2,1) == id2l1 );

    assert( imLayer(img,1,0) == id1l0 );
    assert( imLayer(img,1,1) == id1l1 );

    assert( imLayer(img,0,0) == id0l0 );
    assert( imLayer(img,0,1) == id0l1 );
}
