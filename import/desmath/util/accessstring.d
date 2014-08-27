module desmath.util.accessstring;

import std.string;
import std.algorithm;

pure bool isCompatibleArrayAccessString( size_t N, string str, string sep="" )
{ return str.length != 0 && N == getAccessFieldsCount(str,sep) && isArrayAccessString(str,sep); }

pure size_t getAccessFieldsCount( string str, string sep )
{ return str.split(sep).length; }

pure ptrdiff_t getIndex( string str, string arg, string sep="" )
{
    foreach( i, v; str.split(sep) )
        if( arg == v ) return i;
    return -1;
}

pure bool oneOfAccess( string str, string arg, string sep="" )
{
    auto splt = str.split(sep);
    return canFind(splt,arg);
}

pure bool oneOfAccessAll( string str, string arg, string sep="" )
{
    auto splt = arg.split("");
    return all!(a=>oneOfAccess(str,a,sep))(splt);
}

pure bool isOneSymbolPerFieldAccessString( string str, string sep="" )
{
    auto splt = str.split(sep);
    foreach( s; splt )
        if( s.length > 1 ) return false;
    return true;
}

unittest
{
    assert( isValueAccessString( "hello" ) );
    assert( isValueAccessString( "x" ) );
    assert( isValueAccessString( "_ok" ) );
    assert( isValueAccessString( "__ok" ) );
    assert( isValueAccessString( "__o1k" ) );
    assert( isValueAccessString( "_2o1k3" ) );
    assert( !isValueAccessString( "0__ok" ) );
    assert( !isValueAccessString( "__o-k" ) );
    assert( isArrayAccessString( "xyz" ) );
    assert( isArrayAccessString( "x|dx|y|dy", "|" ) );
    assert( isCompatibleArrayAccessString( 4, "x|dx|y|dy", "|" ) );
    assert( isCompatibleArrayAccessString( 3, "xyz" ) );
    assert( !isCompatibleArrayAccessString( 4, "xxxy" ) );
    assert( !isCompatibleArrayAccessString( 3, "xxx" ) );
    static assert( getIndex( "x,y,z", "x", "," ) == 0 );
    static assert( getIndex( "x,y,z", "y", "," ) == 1 );
    static assert( getIndex( "x,y,z", "z", "," ) == 2 );
    assert( getIndex( "x|dx|y|dy", "dx", "|" ) == 1 );
    assert( getIndex( "x|dx|y|dy", "1dx", "|" ) == -1 );

    assert( oneOfAccessAll("xyz","xy") );
    assert( oneOfAccessAll("xyz","yx") );
    assert( oneOfAccessAll("xyz","xxxxyxyyyz") );
    assert( oneOfAccessAll("x,y,z","xxxxyxyyyz",",") );
    assert( isOneSymbolPerFieldAccessString("xyz") );
    assert( isOneSymbolPerFieldAccessString("x,y,z",",") );
}

pure
{

bool isArrayAccessString( string as, string sep="" )
{
    auto splt = as.split(sep);
    foreach( i, val; splt )
        if( !isValueAccessString(val) || canFind(splt[0..i],val) )
            return false;
    return true;
}

bool isValueAccessString( in string as )
{ return as.length > 0 && startsWithAllowedChars(as) && allowedCharsOnly(as); }

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
