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

module desutil.colorparse;

ulong hex2ulong( string hex )
{
    import std.string;

    enum tbl = [ '0':  0, '1':  1, '2':  2, '3':  3, 
                 '4':  4, '5':  5, '6':  6, '7':  7, 
                 '8':  8, '9':  9, 'A': 10, 'B': 11, 
                 'C': 12, 'D': 13, 'E': 14, 'F': 15 ];

    ulong ret = 0;
    size_t i = 0;
    auto uHex = toUpper( hex );
    foreach_reverse( c; uHex )
        ret += tbl[c] << (4 * i++);

    return ret;
}

T[4] parseColorStr(T=float)( string cstr, real norm=1 )
{
    if( cstr[0] == '#' )
        cstr = cstr[ 1 .. $ ];
    else if( cstr[0] == '0' && cstr[1] == 'x' )
        cstr = cstr[ 2 .. $ ];
    else
        throw new Exception( "unsupported hex color string (format): '" ~ cstr ~ "'" );

    ulong shortWrite = 0;
    bool alpha = false;
    switch( cstr.length )
    {
        case 1:
            shortWrite = 2;
            break;
        case 2:
            shortWrite = 3;
            alpha = true;
            break;
        case 3:
            shortWrite = 1;
            break;
        case 4:
            shortWrite = 1;
            alpha = true;
            break;
        case 6: break;
        case 8:
            alpha = true;
            break;
        default: 
            throw new Exception( "unsupported hex color string (length): '" ~ cstr ~ "'" );
    }

    if( shortWrite == 1 )
    {
        string buf;

        foreach( c; cstr )
            buf ~= [c,c];

        cstr = buf;
    }
    else if( shortWrite >= 2 )
    {
        string buf;

        buf ~= [ cstr[0], cstr[0], cstr[0], cstr[0], cstr[0], cstr[0] ];

        if( shortWrite == 3 )
            buf ~= [ cstr[1], cstr[1] ];

        cstr = buf;
    }

    ulong val = hex2ulong( cstr );

    enum compbits = byte.sizeof * 8;
    enum compmask = 0xFF;

    auto k = norm / cast(real)(compmask);
    auto cr = cast(T)( ( ( val >> ( ( 2 + alpha ) * compbits ) ) & compmask ) * k );
    auto cg = cast(T)( ( ( val >> ( ( 1 + alpha ) * compbits ) ) & compmask ) * k );
    auto cb = cast(T)( ( ( val >> ( ( 0 + alpha ) * compbits ) ) & compmask ) * k );
    auto ca = cast(T)( alpha ? ( val & compmask ) * k : norm );

    return [ cr, cg, cb, ca ];
}

unittest
{
    assert( [1.0f,0,1,0] == parseColorStr( "#FF00FF00" ) );
    assert( [1.0f,0,1,1] == parseColorStr( "#FF00FF" ) );
    assert( [1.0f,0,1,0] == parseColorStr( "#F0F0" ) );
    assert( [1.0f,0,1,1] == parseColorStr( "#F0F" ) );
    assert( [1.0f,1,1,0] == parseColorStr( "#F0" ) );
    assert( [1.0f,1,1,1] == parseColorStr( "#F" ) );
    assert( [0.0f,0,0,1] == parseColorStr( "#0" ) );
    assert( [1.0f,1,1,1] == parseColorStr( "0xF" ) );
    assert( [0.0f,0,0,1] == parseColorStr( "0x0" ) );

    assert( [255,15,255,255] == parseColorStr!ubyte( "#FF0FFF", 255 ) );
}
