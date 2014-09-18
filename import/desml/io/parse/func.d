module desml.io.parse.func;

import std.stdio;
import std.exception;

public import desml.value;

import desml.io.simple;

alias Value delegate( in Value[] args... ) Function;

Function[string] BaseFunctions;

class FunctionException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

static this()
{
    BaseFunctions["include"] = (in Value[] args...)
    {
        enforce( args.length == 1,
                new FunctionException( "args count for 'include' must be 1" ) );
        enforce( args[0].value.length > 0,
                new FunctionException( "args[0].value must be a file name, its empty" ) );

        string result;

        auto f = File( args[0].value, "r" );

        char[] buf;
        while( f.readln(buf) )
            result ~= buf;

        f.close();
        
        return parseDML( result );
    };

    BaseFunctions["value"] = (in Value[] args...)
    {
        enforce( args.length == 1,
                new FunctionException( "args count for 'value' must be 1" ) );
        return Value( args[0].value );
    };

    BaseFunctions["array"] = (in Value[] args...)
    {
        enforce( args.length == 1,
                new FunctionException( "args count for 'value' must be 1" ) );
        return Value( args[0].array );
    };

    BaseFunctions["dict"] = (in Value[] args...)
    {
        enforce( args.length == 1,
                new FunctionException( "args count for 'value' must be 1" ) );
        return Value( args[0].dict );
    };
}
