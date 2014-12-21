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

module des.math.util.accessstring;

import std.string;
import std.algorithm;
import std.stdio;

/// compatible for creating access dispatches
pure bool isCompatibleArrayAccessStrings( size_t N, string str, string sep1="", string sep2="|" )
in { assert( sep1 != sep2 ); } body
{
    auto strs = str.split(sep2);
    foreach( s; strs )
        if( !isCompatibleArrayAccessString(N,s,sep1) )
            return false;

    string[] fa;
    foreach( s; strs )
        fa ~= s.split(sep1);

    foreach( ref v; fa ) v = strip(v);

    foreach( i, a; fa )
        foreach( j, b; fa )
            if( i != j && a == b ) return false;

    return true;
}


/// compatible for creating access dispatches
pure bool isCompatibleArrayAccessString( size_t N, string str, string sep="" )
{ return N == getAccessFieldsCount(str,sep) && isArrayAccessString(str,sep); }

///
pure bool isArrayAccessString( in string as, in string sep="", bool allowDot=false )
{
    if( as.length == 0 ) return false;
    auto splt = as.split(sep);
    foreach( i, val; splt )
        if( !isValueAccessString(val,allowDot) || canFind(splt[0..i],val) )
            return false;
    return true;
}

///
pure size_t getAccessFieldsCount( string str, string sep )
{ return str.split(sep).length; }

///
pure ptrdiff_t getIndex( string as, string arg, string sep1="", string sep2="|" )
in { assert( sep1 != sep2 ); } body
{
    foreach( str; as.split(sep2) )
        foreach( i, v; str.split(sep1) )
            if( arg == v ) return i;
    return -1;
}

///
pure bool oneOfAccess( string str, string arg, string sep="" )
{
    auto splt = str.split(sep);
    return canFind(splt,arg);
}

///
pure bool oneOfAccessAll( string str, string arg, string sep="" )
{
    auto splt = arg.split("");
    return all!(a=>oneOfAccess(str,a,sep))(splt);
}

///
pure bool oneOfAnyAccessAll( string str, string arg, string sep1="", string sep2="|" )
in { assert( sep1 != sep2 ); } body
{
    foreach( s; str.split(sep2) )
        if( oneOfAccessAll(s,arg,sep1) ) return true;
    return false;
}

/// check symbol count for access to field
pure bool isOneSymbolPerFieldForAnyAccessString( string str, string sep1="", string sep2="|" )
in { assert( sep1 != sep2 ); } body
{
    foreach( s; str.split(sep2) )
        if( isOneSymbolPerFieldAccessString(s,sep1) ) return true;
    return false;
}

/// check symbol count for access to field
pure bool isOneSymbolPerFieldAccessString( string str, string sep="" )
{
    foreach( s; str.split(sep) )
        if( s.length > 1 ) return false;
    return true;
}

/++
Using all functions
+/
unittest
{
    static assert(  isValueAccessString( "hello" ) );
    static assert(  isValueAccessString( "x" ) );
    static assert(  isValueAccessString( "_ok" ) );
    static assert(  isValueAccessString( "__ok" ) );
    static assert(  isValueAccessString( "__o1k" ) );
    static assert(  isValueAccessString( "_2o1k3" ) );
    static assert( !isValueAccessString( "0__ok" ) );
    static assert( !isValueAccessString( "__o-k" ) );
    static assert(  isArrayAccessString( "xyz" ) );
    static assert(  isArrayAccessString( "x|dx|y|dy", "|" ) );
    static assert(  isCompatibleArrayAccessString( 4, "x|dx|y|dy", "|" ) );
    static assert(  isCompatibleArrayAccessString( 3, "xyz" ) );
    static assert( !isCompatibleArrayAccessString( 4, "xxxy" ) );
    static assert( !isCompatibleArrayAccessString( 3, "xxx" ) );
    static assert(  isCompatibleArrayAccessStrings( 3, "xyz" ) );
    static assert(  isCompatibleArrayAccessStrings( 3, "x y z", " " ) );
    static assert(  isCompatibleArrayAccessStrings( 2, "xy|uv" ) );
    static assert(  isCompatibleArrayAccessStrings( 3, "abc|efg" ) );
    static assert( !isCompatibleArrayAccessStrings( 3, "abc|afg" ) );
    static assert( !isCompatibleArrayAccessStrings( 3, "xxy|uv" ) );
    static assert(  isCompatibleArrayAccessStrings( 3, "x,y,z;u,v,t", ",", ";" ) );
    static assert( getIndex( "x y z", "x", " " ) == 0 );
    static assert( getIndex( "x y z", "y", " " ) == 1 );
    static assert( getIndex( "x y z", "z", " " ) == 2 );
    static assert( getIndex( "x|dx|y|dy", "dx", "|", ";" ) == 1 );
    static assert( getIndex( "x|dx|y|dy", "1dx", "|", ";" ) == -1 );

    static assert( oneOfAccessAll("xyz","xy") );
    static assert( oneOfAccessAll("xyz","yx") );
    static assert( oneOfAccessAll("xyz","xxxxyxyyyz") );
    static assert( oneOfAccessAll("x,y,z","xxxxyxyyyz",",") );
    static assert( isOneSymbolPerFieldAccessString("xyz") );
    static assert( isOneSymbolPerFieldAccessString("x,y,z",",") );
    static assert( isOneSymbolPerFieldForAnyAccessString( "xy|uv", "", "|" ) );
    static assert( isOneSymbolPerFieldForAnyAccessString( "near far|n f", " ", "|" ) );

    static assert( !isArrayAccessString("x.y.z","",false) );
    static assert( !isArrayAccessString("x.y.z","",true) );
    static assert( !isArrayAccessString("x.y.z"," ",false) );
    static assert(  isArrayAccessString("x.y.z"," ",true) );
    static assert(  isArrayAccessString("pos.x pos.y pos.z vel.x vel.y vel.z"," ",true) );

    static assert(  isArrayAccessString( "pos vel", " ", true ) );
    static assert(  isArrayAccessString( "abcd", " ", true ) );
    static assert(  isArrayAccessString( "a1 a2", " ", true ) );
    static assert(  isArrayAccessString( "ok.no", " ", true ) );
    auto fstr = "pos.x pos.y vel.x vel.y";
    assert(  isArrayAccessString( fstr, " ", true ) );
    assert( !isArrayAccessString( fstr[0 .. $-1], " ", true ) );
    assert( !isArrayAccessString( "ok.1", " ", true ) );
    assert( !isArrayAccessString( "1abcd", " ", true ) );
    assert( !isArrayAccessString( "not 2ok", " ", true ) );
}

pure
{

bool isValueAccessString( in string as, bool allowDot=false )
{
    return as.length > 0 &&
    startsWithAllowedChars(as) &&
    (allowDot?(all!(a=>isValueAccessString(a))(as.split("."))):allowedCharsOnly(as));
}

bool startsWithAllowedChars( in string as )
{
    switch(as[0])
    {
        case 'a': .. case 'z': goto case;
        case 'A': .. case 'Z': goto case;
        case '_': return true;
        default: return false;
    }
}

bool allowedCharsOnly( in string as )
{
    foreach( c; as ) if( !allowedChar(c) ) return false;
    return true;
}

bool allowedChar( in char c )
{
    switch(c)
    {
        case 'a': .. case 'z': goto case;
        case 'A': .. case 'Z': goto case;
        case '0': .. case '9': goto case;
        case '_': return true;
        default: return false;
    }
}

}
