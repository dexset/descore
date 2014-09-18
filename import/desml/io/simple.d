module desml.io.simple;

import std.stdio;
import std.string;

import desml.value;

import desml.io.parse;
import desml.io.rules;

Value readDML( string fname, Function[string] funcs=null,
                             in Value context=Value.init )
{
    string str;
    char[] buf;

    auto f = File( fname, "r" );
    while( f.readln(buf) ) str ~= buf;
    f.close();

    return parseDML( str, funcs, context );
}

Value parseDML( string dml, Function[string] flist=null,
                            in Value context=Value.init )
{
    auto funcs = merge( BaseFunctions, flist );
    auto rules = new Rules;
    auto lines = dml.splitLines;
    auto root = new ParseNode( null, rules );
    root.setFuncs( funcs );
    root.action.replace( Value(context) );
    root.parse( BlockSource( lines, 0 ) );
    return root.compile();
}

unittest
{
    auto dml = `
# this is comment

some string

another string

a: b: c:
    x: abc

block:
    value for this block

    @: value for first elem of array
    @: value for second elem of array
    @: value for third elem of array

    fsub:
        @:
            x: 5
        @:
            hello: world
            
        abc:
            a: 1
            b: 2

    fsub:
        bcd: okda

    ssub:
        @:
            y: 5
        @:
            hello: world

        abc:
            a: 10
            c: 30

        cde: 
            f: 4

    !it: is +a simple(value)

    fff:
        +$../ssub # append
        =$../fsub # replace
        %$../fsub # update

    append block value
`;

    auto val = parseDML( dml );

    printBlock( val.block.fff );
}

void printBlock( Value block, string indent="" )
{
    enum baseIndent = "  ";
    stderr.writeln( indent ~ "---" );

    stderr.writeln( indent ~ "self value:" );
    stderr.writeln( indent ~ baseIndent ~ block.value );

    foreach( i, a; block.array )
    {
        stderr.writefln( "%sarray elem: %s", indent, i );
        printBlock( a, indent ~ baseIndent );
    }

    foreach( key, a; block.dict )
    {
        stderr.writefln( "%sblock: %s", indent, key );
        printBlock( a, indent ~ baseIndent );
    }

    stderr.writeln( indent ~ "---" );
}

auto merge(T,K)( T[K][] lists... )
{
    T[K] ret;
    foreach( list; lists )
        foreach( key, val; list )
            ret[key] = val;
    return ret;
}

/+
void writeDML( string fname, in Value obj )
{
    auto f = File( fname, "w" );
    f.write( obj.toString() );
    f.close();
}

@property string toString( in Value obj )
{
    auto s = new Serializator;
    return s.serialize( obj );
}
+/
