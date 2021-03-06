module des.util.stdext.string;

public import std.string;
import std.array;
import std.algorithm;

import des.util.data.type : ArrayData, AlienArray;

@trusted pure
{
    ///
    string toSnakeCase( in string str, bool ignore_first=true ) @property
    {
        string[] buf;
        buf ~= "";
        foreach( i, ch; str )
        {
            if( [ch].toUpper == [ch] ) buf ~= "";
            buf[$-1] ~= [ch].toLower;
        }
        if( buf[0].length == 0 && ignore_first )
            buf = buf[1..$];
        return buf.join("_");
    }

    ///
    string toCamelCaseBySep( in string str, string sep="_", bool first_capitalize=true )
    {
        auto arr = array( filter!"a.length > 0"( str.split(sep) ) );
        string[] ret;
        foreach( i, v; arr )
        {
            auto bb = v.capitalize;
            if( i == 0 && !first_capitalize )
                bb = v.toLower;
            ret ~= bb;
        }
        return ret.join("");
    }

    ///
    string toCamelCase( in string str, bool first_capitalize=true ) @property
    { return toCamelCaseBySep( str, "_", first_capitalize ); }

    /// copy chars to string
    string toDString( const(char*) c_str ) nothrow
    {
        if( c_str is null ) return "";
        char *ch = cast(char*)c_str;
        size_t n;
        while( *ch++ != '\0' ) n++;
        return AlienArray!char( ArrayData( n, cast(void*)c_str ) ).arr.idup;
    }

    /// ditto
    string toDStringFix(size_t S)( const(char[S]) c_buf ) nothrow
    {
        size_t n;
        foreach( c; c_buf )
        {
            if( c == '\0' ) break;
            n++;
        }
        return AlienArray!char( ArrayData( n, cast(void*)c_buf.ptr ) ).arr.idup;
    }
}

///
unittest
{
    assert( "someVar".toSnakeCase == "some_var" );
    assert( "SomeVar".toSnakeCase == "some_var" );
    assert( "SomeVar".toSnakeCase(false) == "_some_var" );
    assert( "ARB".toSnakeCase == "a_r_b" );
    assert( "ARB".toSnakeCase(false) == "_a_r_b" );
}

///
unittest
{
    assert( "some_class".toCamelCase == "SomeClass" );
    assert( "_some_class".toCamelCase == "SomeClass" );
    assert( "some_func".toCamelCase(false) == "someFunc" );
    assert( "_some_func".toCamelCase(false) == "someFunc" );
    assert( "a_r_b".toCamelCase == "ARB" );
    assert( toCamelCase( "program_build" ) == "ProgramBuild" );
    assert( toCamelCaseBySep( "single-precision-constant", "-", false ) == "singlePrecisionConstant" );
}
