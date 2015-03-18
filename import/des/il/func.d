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

import std.stdio;

///
enum ImRepack
{
    NONE,  ///
    ROT90, ///
    ROT180,///
    ROT270,///
    MIRHOR,///
    MIRVER,///
    MTRANS,///
    STRANS,///
}

private CrdVector!N permutateComp(size_t N,T)( in Vector!(N,T) v, ImRepack tr, size_t[2] crdNum ) pure
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
        case ImRepack.ROT90:
        case ImRepack.ROT270:
        case ImRepack.MTRANS:
        case ImRepack.STRANS:
            auto ret = CrdVector!N(v);
            ret[crdNum[0]] = v[crdNum[1]];
            ret[crdNum[1]] = v[crdNum[0]];
            return ret;
        default: return CrdVector!N(v);
    }
}

private void function( coord_t, coord_t, coord_t, coord_t,
               ref coord_t, ref coord_t ) getRepackCrdFunc( ImRepack repack )
out(fnc) { assert( fnc !is null ); } body
{
    final switch( repack )
    {
        case ImRepack.NONE:   return &noRepackCrd;
        case ImRepack.ROT90:  return &rotCrd90;
        case ImRepack.ROT180: return &rotCrd180;
        case ImRepack.ROT270: return &rotCrd270;
        case ImRepack.MIRHOR: return &mirHorCrd;
        case ImRepack.MIRVER: return &mirVerCrd;
        case ImRepack.MTRANS: return &mTransCrd;
        case ImRepack.STRANS: return &sTransCrd;
    }
}

private
{
    void noRepackCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                        ref coord_t rx, ref coord_t ry )
    { rx=px; ry=py; }

    void rotCrd90( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=sy-1-py; ry=px; }

    void rotCrd180( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=sx-1-px; ry=sy-1-py; }

    void rotCrd270( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=py; ry=sx-1-px; }

    void mirHorCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=sx-1-px; ry=py; }

    void mirVerCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=px; ry=sy-1-py; }

    void mTransCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=py; ry=px; }

    void sTransCrd( coord_t px, coord_t py, coord_t sx, coord_t sy,
                    ref coord_t rx, ref coord_t ry )
    { rx=sy-1-py; ry=sx-1-px; }
}

/// copy `src` image from `copy_reg` to `dst` image in `paste_pos` with repack
void imCopy( string file=__FILE__, size_t line=__LINE__, size_t A,
            size_t B, T, E)( ref Image dst, in Vector!(A,T) paste_pos,
                in Image src, in Region!(B,E) copy_reg,
                ImRepack repack=ImRepack.NONE, size_t[2] repack_dim=[0,1] )
if( isIntegral!T && isIntegral!E )
{
    auto dims = dst.dims;
    imEnforce!(file,line)( dims > 0, "no dimensions in dst" );
    imEnforce!(file,line)( src.dims > 0, "no dimensions in src" );
    imEnforce!(file,line)( dims >= src.dims,
            "too much source dimensions" );
    imEnforce!(file,line)( dims == paste_pos.length,
            "dst dims mismatch with dst_pos dims" );
    imEnforce!(file,line)( dims == copy_reg.dims,
            "dst dims mismatch with src_reg dims" );
    imEnforce!(file,line)( repack_dim[0] < dims,
            "repack_dim[0] not less what dst dims" );
    imEnforce!(file,line)( dst.info == src.info,
            "dst info mismatch with src info" );

    auto rd0 = repack_dim[0];
    auto rd1 = repack_dim[1];

    if( dims == 1 ) rd1 = rd0;
    else imEnforce!(file,line)( rd1 < dims,
            "repack_dim[1] not less what dst dims" );

    auto src_size = src.robSize(dims);

    imEnforce!(file,line)( isAllCompPositive(copy_reg.pos),
            "copy region must be in source image" );
    imEnforce!(file,line)( isAllCompPositive(src_size-copy_reg.lim),
            "copy region must be in source image" );

    auto paste_reg = CrdRegionD( paste_pos,
            permutateComp( copy_reg.size, repack, repack_dim ) );

    auto crop = CrdRegionD.fromSize( dst.size ).overlapLocal( paste_reg );

    auto copy_count = reduce!((s,v)=>s*=v)( crop.size );

    auto repack_crd_func = getRepackCrdFunc( repack );

    auto bpe = dst.info.bpe;

    foreach( i; 0 .. copy_count )
    {
        auto local_crop_crd = CrdVectorD( getCoord( crop.size, i ) );

        auto dst_crd = crop.pos + local_crop_crd;

        auto dst_offset = getIndex( dst.size, dst_crd );

        auto paste_crd = dst_crd - paste_reg.pos;
        auto src_crd = CrdVectorD( paste_crd );

        repack_crd_func( paste_crd[rd0], paste_crd[rd1],
                         paste_reg.size[rd0], paste_reg.size[rd1],
                         src_crd[rd0], src_crd[rd1] );

        auto src_offset = getIndex( src_size, src_crd + copy_reg.pos );

        memcpy( dst.data.ptr + dst_offset * bpe,
                src.data.ptr + src_offset * bpe, bpe );
    }
}

///
unittest
{
    auto etype = ElemInfo( 1, DataType.INT );
    auto dst = Image( ivec2(3,3), etype );

    auto src = Image( ivec2(2,2), etype, [ 1,2, 3,4 ]);

    imCopy( dst, ivec2(1,1), src, CrdRegionD(0,0,2,2), ImRepack.ROT90 );

    assertEq( dst.data, [ 0,0,0,
                          0,2,4,
                          0,1,3 ] );

    imCopy( dst, ivec2(0,0), src, CrdRegionD(0,0,2,2), ImRepack.ROT270 );

    assertEq( dst.data, [ 3,1,0,
                          4,2,4,
                          0,1,3 ] );
}

///
unittest
{
    auto etype = ElemInfo( 1, DataType.INT );
    auto dst = Image( ivec3(3,3,3), etype );
    auto src = Image( CrdVectorD(3), etype, [1,2,4] );

    imCopy( dst, ivec3(0,0,0), src, CrdRegionD(0,0,0,3,1,1), ImRepack.ROT270 );
    assertEq( dst.mapAs!int, [ 1,0,0,
                               2,0,0,
                               4,0,0, // z=0

                               0,0,0,
                               0,0,0,
                               0,0,0, // z=1

                               0,0,0,
                               0,0,0,
                               0,0,0, // z=2
                             ] );

    imCopy( dst, ivec3(1,0,0), src, CrdRegionD(0,0,0,3,1,1), ImRepack.ROT90, [0,2] );
    assertEq( dst.mapAs!int, [ 1,4,0,
                               2,0,0,
                               4,0,0, // z=0

                               0,2,0,
                               0,0,0,
                               0,0,0, // z=1

                               0,1,0,
                               0,0,0,
                               0,0,0, // z=2
                             ] );
}

///
unittest
{
    auto etype = ElemInfo( 1, DataType.INT );
    auto dst = Image( ivec3(3,3,3), etype );
    auto src = Image( CrdVectorD(3), etype, [1,2,4] );

    imCopy( dst, ivec3(1,0,0), src, CrdRegionD(1,0,0,2,1,1), ImRepack.ROT270 );
    assertEq( dst.mapAs!int, [ 0,2,0,
                               0,4,0,
                               0,0,0, // z=0

                               0,0,0,
                               0,0,0,
                               0,0,0, // z=1

                               0,0,0,
                               0,0,0,
                               0,0,0, // z=2
                             ] );
}

///
void imCopy(string file=__FILE__, size_t line=__LINE__, size_t A,T)
           ( ref Image dst, in Vector!(A,T) paste_pos,
            in Image src, ImRepack repack=ImRepack.NONE,
            size_t[2] repack_dim=[0,1] )
if( isIntegral!T )
{
    imCopy!(file,line)( dst, paste_pos, src,
            CrdRegionD.fromSize( src.robSize(dst.dims) ),
            repack, repack_dim );
}

///
unittest
{
    auto etype = ElemInfo( 1, DataType.INT );
    auto dst = Image( ivec2(4,4), etype );
    auto src = Image( ivec2(3,2), etype, [ 1,2,4, 5,6,8 ] );

    imCopy( dst, ivec2(-1,-1), src, ImRepack.ROT90 );
    assertEq( dst.mapAs!int, [ 6,0,0,0,
                               5,0,0,0,
                               0,0,0,0,
                               0,0,0,0 ] );
    imCopy( dst, ivec2(2,1), src, ImRepack.ROT180 );
    assertEq( dst.mapAs!int, [ 6,0,0,0,
                               5,0,8,6,
                               0,0,4,2,
                               0,0,0,0 ] );
    imCopy( dst, ivec2(-1,3), src, ImRepack.MIRVER );
    assertEq( dst.mapAs!int, [ 6,0,0,0,
                               5,0,8,6,
                               0,0,4,2,
                               6,8,0,0 ] );
}

///
unittest
{
    auto etype = ElemInfo( 1, DataType.INT );
    auto dst = Image( ivec2(2,2), etype );
    auto src = Image( ivec2(3,3), etype, [ 1,2,4, 5,6,8, 9,7,3 ] );

    imCopy( dst, ivec2(-1,-1), src, CrdRegionD(0,0,3,3) );
    assertEq( dst.mapAs!int, [ 6,8,
                               7,3 ] );

}

///
unittest
{
    auto etype = ElemInfo( 1, DataType.INT );
    auto dst = Image( ivec3(2,2,2), etype );
    auto src = Image( ivec!1(2), etype, [ 1,2 ] );

    imCopy( dst, ivec3(0,0,0), src, ImRepack.NONE );
    assertEq( dst.mapAs!int, [1,2, 0,0,  0,0, 0,0] );

    imCopy( dst, ivec3(0,0,0), src, ImRepack.ROT270 );
    assertEq( dst.mapAs!int, [1,2, 2,0,  0,0, 0,0] );

    dst.clear();
    imCopy( dst, ivec3(0,0,0), src, ImRepack.ROT90, [0,2] );
    assertEq( dst.mapAs!int, [2,0, 0,0,  1,0, 0,0] );
}

/// copy and repack image from region to new image
Image imGetCopy(string file=__FILE__,size_t line=__LINE__,size_t B,E)( in Image src, in Region!(B,E) copy_reg,
                    ImRepack repack=ImRepack.NONE, size_t[2] repack_dim=[0,1] )
if( isIntegral!E )
{
    if( src.dims == 1 ) repack_dim[1] = repack_dim[0];
    auto sz = permutateComp( copy_reg.size, repack, repack_dim );
    auto ret = Image( sz, src.info );
    imCopy!(file,line)( ret, CrdVectorD.fill(src.dims,0), src, copy_reg, repack, repack_dim );
    return ret;
}

///
unittest
{
    auto a = Image( ivec!1(5), ElemInfo( 2, DataType.FLOAT ) );
    a.pixel!vec2(3) = vec2(1,1);
    a.pixel!vec2(4) = vec2(2,2);
    auto b = imGetCopy( a, Region!(1,int)(3,2) );
    assert( b.pixel!vec2(0) == a.pixel!vec2(3) );
    assert( b.pixel!vec2(1) == a.pixel!vec2(4) );
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
        ubyte[] r = [ 8,12,16, 7,11,15 ];
        assertEq( imGetCopy( img, iRegion2(2,1,2,3), ImRepack.ROT90 ).mapAs!ubyte, r );
    }

    {
        ubyte[] r = [ 14,10,6, 15,11,7 ];
        assertEq( imGetCopy( img, iRegion2(1,1,2,3), ImRepack.ROT270 ).mapAs!ubyte, r );
    }

    {
        ubyte[] r= [ 3,2,1, 7,6,5 ];
        assertEq( imGetCopy( img, iRegion2(0,0,3,2), ImRepack.MIRHOR ).mapAs!ubyte, r );
    }

    {
        ubyte[] r = [ 5,6,7, 1,2,3 ];
        assert( imGetCopy( img, iRegion2(0,0,3,2), ImRepack.MIRVER ).mapAs!ubyte == r );
    }
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

    ubyte[] d2l0 = [ 1,2,3,4,5,6 ];
    ubyte[] d2l1 = [ 7,8,9,10,11,12 ];

    ubyte[] d1l0 = [ 1,2,3,7,8,9 ];
    ubyte[] d1l1 = [ 4,5,6,10,11,12 ];

    ubyte[] d0l0 = [ 1, 4, 7, 10 ];
    ubyte[] d0l1 = [ 2, 5, 8, 11 ];

    auto img = Image( ivec3(3,2,2), 1, DataType.UBYTE, img_data );

    assertEq( imGetCopy( img, CrdRegionD(0,0,0,3,2,1) ).mapAs!ubyte, d2l0 );
    assertEq( imGetCopy( img, CrdRegionD(0,0,1,3,2,1) ).mapAs!ubyte, d2l1 );

    assertEq( imGetCopy( img, CrdRegionD(0,0,0,3,1,2) ).mapAs!ubyte, d1l0 );
    assertEq( imGetCopy( img, CrdRegionD(0,1,0,3,1,2) ).mapAs!ubyte, d1l1 );

    assertEq( imGetCopy( img, CrdRegionD(0,0,0,1,2,2) ).mapAs!ubyte, d0l0 );
    assertEq( imGetCopy( img, CrdRegionD(1,0,0,1,2,2) ).mapAs!ubyte, d0l1 );
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
    imCopy( res, ivec2(-1,-1), im );
    assert( res.data == datav1 );

    res = Image(orig);
    imCopy( res, ivec2(1,1), im );
    assert( res.data == datav2 );
}

unittest
{
    ubyte[] src_data = [ 1,2,3, 4,5,6, 7,8,9 ];

    ubyte[] dst1_data =
        [
        0,0,0, 0,0,0, 0,0,0,

        1,2,3, 4,5,6, 7,8,9,

        0,0,0, 0,0,0, 0,0,0
        ];

    ubyte[] dst2_data =
        [
        0,1,0, 0,2,0, 0,3,0,

        0,4,0, 0,5,0, 0,6,0,

        0,7,0, 0,8,0, 0,9,0
        ];

    auto src = Image( ivec2(3,3), ElemInfo( 1, DataType.UBYTE ), src_data );
    auto dst = Image( ivec3(3,3,3), ElemInfo( 1, DataType.UBYTE ) );
    imCopy( dst, ivec3(0,0,1), Image( ivec3(3,3,1), src.info, src.data ) );
    assert( dst.data == dst1_data );
    dst.clear();
    imCopy( dst, ivec3(1,0,0), Image.external( ivec3(1,3,3), src.info, src.data ) );
    assertEq( dst.data, dst2_data );
}

unittest
{
    ubyte[] dt =
        [
        0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,

        0,0,0,0, 0,1,2,0, 0,3,4,0, 0,0,0,0,

        0,0,0,0, 0,5,6,0, 0,7,8,0, 0,0,0,0,

        0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        ];

    ubyte[] cp =
        [
        1,2,1,2, 3,4,3,4, 1,2,1,2, 3,4,3,4,

        5,6,5,6, 7,8,7,8, 5,6,5,6, 7,8,7,8,

        1,2,1,2, 3,4,3,4, 1,2,1,2, 3,4,3,4,

        5,6,5,6, 7,8,7,8, 5,6,5,6, 7,8,7,8,
        ];

    ubyte[] rs = [ 8,7, 6,5, 4,3, 2,1 ];

    auto EType = ElemInfo( 1, DataType.UBYTE );

    auto a = Image( ivec3(4,4,4), EType, dt );
    auto b = Image( ivec3(4,4,4), EType, cp );
    auto c = Image( ivec3(4,4,4), EType );

    auto part = imGetCopy( a, iRegion3( ivec3(1,1,1), ivec3(2,2,2) ) );

    imCopy( c, ivec3(0,0,0), part );
    imCopy( c, ivec3(0,2,0), part );
    imCopy( c, ivec3(2,0,0), part );
    imCopy( c, ivec3(2,2,0), part );

    imCopy( c, ivec3(0,0,2), part );
    imCopy( c, ivec3(0,2,2), part );
    imCopy( c, ivec3(2,0,2), part );
    imCopy( c, ivec3(2,2,2), part );

    assert( b == c );

    auto part2 = imGetCopy( b, iRegion3(ivec3(1,1,1), ivec3(2,2,2)) );
    auto rr = Image( ivec3(2,2,2), EType, rs );
    assert( rr == part2 );
}

unittest
{
    auto type = ElemInfo(1,DataType.UBYTE);

    ubyte[] srcData =
        [
            1,2,3,
            4,5,6,
        ];

    auto src = Image( ivec2(3,2), type, srcData );
    auto dst = Image( ivec3(3,3,3), type );
    imCopy( dst, ivec3(1,0,0), src, ImRepack.ROT180 );
    imCopy( dst, ivec3(-1,-1,1), src, ImRepack.ROT90 );
    imCopy( dst, ivec3(0,0,2), src, ImRepack.NONE );

    auto expectedDstData =
        [
            0,6,5, 0,3,2, 0,0,0,

            5,0,0, 4,0,0, 0,0,0,

            1,2,3, 4,5,6, 0,0,0,
        ];

    assertEq( expectedDstData, dst.mapAs!ubyte );
}

/++ get histogram convolution
    +/
Image imHistoConv( in Image img, size_t dim ) pure
in { assert( dim < img.dims ); } body
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
