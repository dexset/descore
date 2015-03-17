module des.il.func;

import std.algorithm;
import std.traits;
import std.range;

import des.il.util;
import des.il.image;
import des.il.region;

import des.util.testsuite;

import des.math.linear.vector;

import std.c.string : memcpy, memset;

///
enum ImRepack
{
    NONE,  ///
    ROT90, ///
    ROT180,///
    ROT270,///
    MIRHOR,///
    MIRVER ///
}

/// copy and repack image from region to new image
auto imCopy(size_t N,T)( in Image orig, Region!(N,T) reg, ImRepack tr=ImRepack.NONE, size_t[2] cn=[0,1] )
    if( isIntegral!T )
in
{
    assert( orig.dims == reg.dims );
    assert( cn[0] < orig.dims );
    if( orig.dims > 1 )
        assert( cn[1] < orig.dims );
    assert( cn[0] != cn[1] );
}
body
{
    if( orig.dims == 1 ) cn[1] = cn[0];

    alias CReg = CrdRegion!0;
    alias CVec = CrdVector!0;

    auto rSize = imPermutateComp( reg.size, tr, cn );

    auto ret = Image( rSize, orig.info );

    auto crop = CReg( CVec.fill(orig.dims,0).data ~ orig.size.data ).overlapLocal( reg );
    auto bpe = orig.info.bpe;

    auto copy_count = reduce!((s,v)=>s*=v)( crop.size );

    auto tr_func = imGetTrCrdFunc(tr);

    coord_t A = reg.size[cn[0]], B = reg.size[cn[1]];

    foreach( i; 0 .. copy_count )
    {
        auto local_crop_crd = CVec( getCoord( crop.size, i ) );

        auto orig_crd = crop.pos + local_crop_crd;

        auto reg_crd = orig_crd - reg.pos;

        auto ret_crd = reg_crd;
        tr_func( reg_crd[cn[0]], reg_crd[cn[1]], A, B, ret_crd[cn[0]], ret_crd[cn[1]] );

        auto ret_offset = getIndex( ret.size, ret_crd );
        auto orig_offset = getIndex( orig.size, orig_crd );

        memcpy( ret.data.ptr + ret_offset * bpe,
                orig.data.ptr + orig_offset * bpe, bpe );
    }

    return ret;
}

///
unittest
{
    auto a = Image( ivec!1(5), ElemInfo( 2, DataType.FLOAT ) );
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

    auto orig = Image( ivec2(5,5), 1, DataType.UBYTE, data );
    auto im = imCopy( orig, iRegion2( 0, 0, 5, 5 ) );
    assert( orig == im );

    auto imv1 = Image( ivec2( 7, 7 ), 1, DataType.UBYTE, datav1 );
    assert( imCopy( orig, iRegion2( -1, -1, 7, 7 ) ) == imv1 );

    auto imv2 = Image( ivec2(3,3), 1, DataType.UBYTE, datav2 );
    assert( imCopy( orig, iRegion2( 1, 1, 3, 3 ) ) == imv2 );

    auto imv3 = Image( ivec2(4,4), 1, DataType.UBYTE, datav3 );
    assert( imCopy( orig, iRegion2( -1, -1, 4, 4 ) ) == imv3 );

    auto imv4 = Image( ivec2(4,4), 1, DataType.UBYTE, datav4 );
    assert( imCopy( orig, iRegion2( 2, -1, 4, 4 ) ) == imv4 );

    auto imv5 = Image( ivec2(4,4), 1, DataType.UBYTE, datav5 );
    assert( imCopy( orig, iRegion2( -1, 2, 4, 4 ) ) == imv5 );

    auto imv6 = Image( ivec2(4,4), 1, DataType.UBYTE, datav6 );
    assert( imCopy( orig, iRegion2( 2, 2, 4, 4 ) ) == imv6 );
}


///
unittest
{
    ubyte[] imgdata = [
        1, 2, 3, 4,
        5, 6, 7, 8,
        9,10,11,12,
       13,14,15,16
    ];

    auto img = Image( ivec2(4,4), 1, DataType.UBYTE, imgdata );

    {
        ubyte[] r1data = [
            0, 0, 0, 0,
            8,12,16, 0,
            7,11,15, 0,
        ];

        auto r1 = Image( ivec2(4,3), 1, DataType.UBYTE, r1data );
        assert( imCopy( img, iRegion2(2,1,3,4), ImRepack.ROT90 ) == r1 );
    }

    {
        ubyte[] r2data = [ 11,10,9,0, 7,6,5,0 ];
        auto r2 = Image( ivec2(4,2), 1, DataType.UBYTE, r2data );
        assert( imCopy( img, iRegion2(-1,1,4,2), ImRepack.ROT180 ) == r2 );
    }

    {
        ubyte[] r3data = [ 0,14,10,6, 0,15,11,7 ];
        auto r3 = Image( ivec2(4,2), 1, DataType.UBYTE, r3data );
        assert( imCopy( img, iRegion2(1,1,2,4), ImRepack.ROT270 ) == r3 );
    }

    {
        ubyte[] r4data = [ 3,2,1, 7,6,5 ];
        auto r4 = Image( ivec2(3,2), 1, DataType.UBYTE, r4data );
        assert( imCopy( img, iRegion2(0,0,3,2), ImRepack.MIRHOR ) == r4 );
    }

    {
        ubyte[] r5data = [ 5,6,7, 1,2,3 ];
        auto r5 = Image( ivec2(3,2), 1, DataType.UBYTE, r5data );
        assert( imCopy( img, iRegion2(0,0,3,2), ImRepack.MIRVER ) == r5 );
    }
}

CrdVector!N imPermutateComp(size_t N,T)( in Vector!(N,T) v, ImRepack tr, size_t[2] crdNum )
    if( isIntegral!T )
in
{
    assert( crdNum[0] < v.length );
    assert( crdNum[1] < v.length );
}
body
{
    switch( tr )
    {
        case ImRepack.ROT90: case ImRepack.ROT270:
            auto ret = CrdVector!N(v);
            ret[crdNum[0]] = v[crdNum[1]];
            ret[crdNum[1]] = v[crdNum[0]];
            return ret;
        default: return CrdVector!N(v);
    }
}

void function( coord_t, coord_t, coord_t, coord_t,
               ref coord_t, ref coord_t ) imGetTrCrdFunc( ImRepack tr )
out(fnc) { assert( fnc !is null ); } body
{
    final switch( tr )
    {
        case ImRepack.NONE:   return &imNoneTrCrd;
        case ImRepack.ROT90:  return &imRotCrd90;
        case ImRepack.ROT180: return &imRotCrd180;
        case ImRepack.ROT270: return &imRotCrd270;
        case ImRepack.MIRHOR: return &imMirHorCrd;
        case ImRepack.MIRVER: return &imMirVerCrd;
    }
}

void imNoneTrCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                  ref coord_t rx, ref coord_t ry )
{ rx=px; ry=py; }

void imRotCrd90( coord_t px, coord_t py, coord_t sx, coord_t sy,
                  ref coord_t rx, ref coord_t ry )
{ rx=py; ry=sx-1-px; }

void imRotCrd180( coord_t px, coord_t py, coord_t sx, coord_t sy,
                  ref coord_t rx, ref coord_t ry )
{ rx=sx-1-px; ry=sy-1-py; }

void imRotCrd270( coord_t px, coord_t py, coord_t sx, coord_t sy,
                  ref coord_t rx, ref coord_t ry )
{ rx=sy-1-py; ry=px; }

void imMirHorCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                  ref coord_t rx, ref coord_t ry )
{ rx=sx-1-px; ry=py; }

void imMirVerCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                  ref coord_t rx, ref coord_t ry )
{ rx=px; ry=sy-1-py; }

/// paste in image other image
void imPaste(size_t N,V)( ref Image img, in Vector!(N,V) pos, in Image pim )
    if( isIntegral!V )
{
    enforce( pim.dims == img.dims, new ImageException( "image dims mismatch" ) );
    enforce( pim.dims == pos.length, new ImageException( "wrong pos dimensions" ) );
    enforce( pim.info == img.info, new ImageException( "image infos mismatch" ) );

    alias CReg = CrdRegion!0;
    alias CVec = CrdVector!0;

    auto pim_reg = CReg( pos, pim.size );

    auto crop = CReg( CVec.fill(img.dims,0), img.size ).overlapLocal( pim_reg );
    auto bpe = img.info.bpe;

    auto count = reduce!((s,v)=>s*=v)( crop.size );

    foreach( i; 0 .. count )
    {
        auto lccrd = CVec( getCoord( crop.size, i ) );
        auto pim_crd = -CVec(pos) + crop.pos + lccrd;
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


    auto orig = Image( ivec2( 7, 7 ), ElemInfo( 1, DataType.UBYTE ) );
    auto im = Image( ivec2( 5, 5 ), 1, DataType.UBYTE, data );

    auto res = Image(orig);
    imPaste( res, ivec2(-1,-1), im );
    assert( res.data == datav1 );

    res = Image(orig);
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

    auto src = Image( ivec2(3,3), ElemInfo( 1, DataType.UBYTE ), src_data );
    auto dst = Image( ivec3(3,3,3), ElemInfo( 1, DataType.UBYTE ) );
    imPaste( dst, ivec3(0,0,1), Image( ivec3(3,3,1), src.info, src.data ) );
    assert( dst.data == dst1_data );
    dst.clear();
    imPaste( dst, ivec3(1,0,0), Image.external( ivec3(1,3,3), src.info, src.data ) );
    assertEq( dst.data, dst2_data );
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

    auto EType = ElemInfo( 1, DataType.UBYTE );

    auto a = Image( ivec3(4,4,4), EType, dt );
    auto b = Image( ivec3(4,4,4), EType, cp );
    auto c = Image( ivec3(4,4,4), EType );

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
    auto rr = Image( ivec3(2,2,2), EType, rs );
    assert( rr == part2 );

    auto nn = imCopy( rr, iRegion3( ivec3(-1,-1,-1), ivec3(2,2,2) ) );
    auto nndi = Image( ivec3(2,2,2), EType, nnd );

    assert( nn == nndi );
}

/++ get histogram convolution
    +/
Image imHistoConv( in Image img, size_t dim ) pure
in
{
    assert( dim < img.dims );
}
body
{
    auto ret = Image( ivecD( cut( img.size, dim ) ), img.info );

    auto bpe = img.info.bpe;

    foreach( i; 0 .. ret.pixelCount )
    {
        auto buf = ret.data.ptr + i * bpe;
        utDataAssign( img.info, buf, 0 );
        foreach( j; 0 .. img.size[dim] )
            utDataOp!"+"( img.info, buf,
            cast(void*)( img.data.ptr + getOrigIndexByLayerCoord( img.size, dim, i, j ) * bpe ) );
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

    auto img = Image( ivec2(4,2), ElemInfo( 1, DataType.UBYTE ), img_data );
    auto hi_x = Image( ivec!1(2), ElemInfo( 1, DataType.UBYTE ), hi_x_data );
    auto hi_y = Image( ivec!1(4), ElemInfo( 1, DataType.UBYTE ), hi_y_data );

    assert( imHistoConv(img,0) == hi_x );
    assert( imHistoConv(img,1) == hi_y );
}

/// get layer of image
Image imLayer( Image img, size_t dim, size_t lno ) pure
in
{
    assert( dim < img.dims );
    assert( lno < img.size[dim] );
}
body
{
    auto ret = Image( ivecD( cut( img.size, dim ) ), img.info );
    auto bpe = img.info.bpe;
    foreach( i; 0 .. ret.pixelCount )
        memcpy( ret.data.ptr + i * bpe, img.data.ptr + getOrigIndexByLayerCoord(img.size,dim,i,lno) * bpe, bpe );
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

    auto info = ElemInfo( 1, DataType.UBYTE );

    ubyte[] d2l0 = [ 1,2,3,4,5,6 ];
    ubyte[] d2l1 = [ 7,8,9,10,11,12 ];

    ubyte[] d1l0 = [ 1,2,3,7,8,9 ];
    ubyte[] d1l1 = [ 4,5,6,10,11,12 ];

    ubyte[] d0l0 = [ 1, 4, 7, 10 ];
    ubyte[] d0l1 = [ 2, 5, 8, 11 ];

    auto img = Image( ivec3(3,2,2), info, img_data );
    auto id2l0 = Image( ivec2(3,2), info, d2l0 );
    auto id2l1 = Image( ivec2(3,2), info, d2l1 );
    auto id1l0 = Image( ivec2(3,2), info, d1l0 );
    auto id1l1 = Image( ivec2(3,2), info, d1l1 );
    auto id0l0 = Image( ivec2(2,2), info, d0l0 );
    auto id0l1 = Image( ivec2(2,2), info, d0l1 );

    assert( imLayer(img,2,0) == id2l0 );
    assert( imLayer(img,2,1) == id2l1 );

    assert( imLayer(img,1,0) == id1l0 );
    assert( imLayer(img,1,1) == id1l1 );

    assert( imLayer(img,0,0) == id0l0 );
    assert( imLayer(img,0,1) == id0l1 );
}
