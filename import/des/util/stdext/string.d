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

module des.util.stdext.string;

import std.string;
import std.array;
import std.algorithm;

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

    ///
    string toDString( const(char*) c_str ) nothrow
    {
        string buf;
        char *ch = cast(char*)c_str;
        while( *ch != '\0' ) buf ~= *(ch++);
        return buf;
    }

    ///
    string toDStringFix(size_t S)( const(char[S]) c_buf ) nothrow
    {
        string buf;
        foreach( c; c_buf ) buf ~= c;
        return buf;
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
