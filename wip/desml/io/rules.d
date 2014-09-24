module desml.io.rules;

import std.string;
import std.stdio;
import std.conv;
import std.exception;
import std.algorithm;

import desml.value;
import desml.io.parse;

import std.stdio;

struct BlockSource
{
    string[] text;
    size_t start_at_line;
}

class Rules
{
    string[string] params;

    this( string[string] params = null )
    {
        if( params !is null )
            this.params = params.dup;
        appendDefaultParams();
        this.params.rehash();
    }

    void appendDefaultParams()
    {
        params["comment"] = "#";

        params["blockstart"] = ":";

        params["string"] = "!";
        params["array"] = "@";

        //commands
        params["append"] = "+";
        params["replace"] = "=";
        params["update"] = "%";

        params["quote1_open"] = "\"";
        params["quote1_close"] = "\"";

        params["quote2_open"] = "'";
        params["quote2_close"] = "'";

        params["reference"] = "$";
        params["addrsplit"] = "/";
    }

    bool isUseless( string str ) const
    { return isEmpty( str ) || isComment( str ); }

    bool isComment( string str ) const
    { return checkPrefix( strip( str ), "comment" ); }

    bool isEmpty( string str ) const
    { return strip( str ).length == 0; }

    bool checkPrefix( string str, string val ) const
    { return str.startsWith( params[val] ); }

    bool isValue( string str ) const
    {
        return isQuoted( str ) ||
               isStringDefinition( str ) ||
               hasNoSpecialSymbols( str );
    }

    bool isQuoted( string str ) const
    {
        auto s = strip( str );
        return isQuotedWith( s, "quote1" ) ||
               isQuotedWith( s, "quote2" );
    }

    bool isQuotedWith( string str, string qname ) const
    {
        return str.startsWith( params[qname~"_open"] ) &&
               str.endsWith( params[qname~"_close"] );
    }

    bool isStringDefinition( string str ) const
    { return checkPrefix( strip(str), "string" ); }

    bool hasNoSpecialSymbols( string str ) const
    {
        foreach( key, val; params )
        {
            if( key == "comment" ) continue;
            if( canFind( str, val ) )
                return false;
        }

        return true;
    }

    bool isBlockDefinitionLine( string str ) const
    {
        if( !canFind( str, ":") || isValue(str) )
            return false;
        auto s = strip(str).split(":");
        return isTrueBlockName( s[0] );
    }

    bool isTrueBlockName( string str ) const
    {
        return isArrayDefinition(str) ||
               isValidName(str);
    }

    bool isValidName( string str ) const
    {
        return isValidNameFirstChar(str[0]) &&
               isValidNameBodyChars(str[1..$]);
    }

    bool isValidNameFirstChar( char ch ) const
    { return isUnderbar(ch) || isAlphabet(ch); }

    bool isUnderbar( char ch ) const
    { return ch == '_'; }

    bool isAlphabet( char ch ) const
    {
        switch( ch )
        {
            case 'a': ..
            case 'z': goto case;
            case 'A': ..
            case 'Z':
                return true;
            default:
                return false;
        }
    }

    bool isNumeric( char ch ) const
    {
        switch( ch )
        {
            case '0': ..
            case '9':
                return true;
            default:
                return false;
        }
    }

    bool isValidNameBodyChars( string str ) const
    {
        foreach( ch; str )
            if( !isAlphabet(ch) &&
                !isNumeric(ch) &&
                !isUnderbar(ch) )
                return false;
        return true;
    }

    bool isArrayDefinition( string str ) const
    { return str == "@"; }

    bool isCommand( string str ) const
    {
        auto s = strip( str );
        return checkPrefix( s, "append" ) ||
               checkPrefix( s, "replace" ) ||
               checkPrefix( s, "update" );
    }

    string extractValue( string str )
    {
        auto s = strip(str);
        if( checkPrefix( s, "string" ) )
            return chompPrefix( s, params["string"] );

        char[] buf;
        foreach( ch; s )
        {
            // TODO: remove quote
            // TODO: comment can be is MNOGO SIMVOLOV
            if( "" ~ ch == params["comment"] )
                break;
            else buf ~= ch;
        }
        return strip( buf.idup );
    }

    string appendValue( string value, string str )
    {
        if( value.length ) value ~= "\n";
        value ~= str;
        return value;
    }

    string[2] splitBlockDefinition( string str ) const
    {
        string[2] result;
        auto splited_index = countUntil( str, ":" );
        result[0] = str[0 .. splited_index].strip;
        result[1] = str[splited_index + 1 .. $];
        return result;
    }

    auto splitBlocks( BlockSource block ) const
    {
        BlockSource[] ret;
        ptrdiff_t indent = -1;
        size_t line_number = 0;
        while( line_number < block.text.length )
        {
            auto cur_line = block.text[line_number];
            if( isUseless(cur_line) )
            {
                line_number++;
                continue;
            }

            if( indent < 0 )
                indent = getIndent( cur_line );

            auto start = line_number;
            auto end = line_number+1;
            while( end < block.text.length && getIndent( block.text[end] ) > indent )
                end++;
            ret ~= BlockSource( block.text[start..end], start );
            line_number = end;
        }
        return ret;
    }

    size_t getIndent( string line ) const
    {
        foreach( no, ch; line )
            if( ch != ' ' )
                return no;
        return size_t.max;
    }

    Command parseCommand( BlockSource block ) const
    {
        Command ret;
        auto fline = strip( block.text[0] );

        ret.action = choiseAction( fline );
        fline = chompActionPrefix( ret.action, fline );

        ret.subject = getSubject( fline );

        return ret;
    }

    Command.Action choiseAction( string str ) const
    {
        if( checkPrefix( str, "append" ) )
            return Command.Action.APPEND;
        else if( checkPrefix( str, "replace" ) )
            return Command.Action.REPLACE;
        else if( checkPrefix( str, "update" ) )
            return Command.Action.UPDATE;
        else assert(0, "unknown command action" );
    }

    string chompActionPrefix( Command.Action act, string str ) const
    {
        string var;
        final switch(act)
        {
            case Command.Action.APPEND:  var = "append"; break; 
            case Command.Action.REPLACE: var = "replace"; break; 
            case Command.Action.UPDATE:  var = "update"; break; 
        }
        return chompPrefix( str, params[var] );
    }

    Command.Subject getSubject( string str ) const
    {
        if( isReference(str) )
            return getBlockAddressSubject( str );
        else if( isFunction(str) )
            return getSubjectFunction( str );
        else assert(0,"unknown subject type" );
    }

    bool isReference( string str ) const
    { return checkPrefix( str, "reference" ); }

    bool isFunction( string str ) const
    {
        pragma(msg,__FILE__,":",__LINE__,":TODO");
        return true;
    }

    Command.Subject getSubjectFunction( string str ) const
    { assert(0,"TODO"); }

    Command.Subject getBlockAddressSubject( string str ) const
    {
        Command.Subject ret;
        ret.type = ret.Type.BLOCK;
        auto addr_str = chompPrefix( str, params["reference"] );

        auto cu = countUntil( addr_str, params["comment"] );
        if( cu > 0 ) addr_str = addr_str[0 .. cu];

        enforce( addr_str.length > 1 );

        auto addr_arr = addr_str.split(params["addrsplit"]);
        foreach( no, ss; addr_arr )
        {
            auto s = strip(ss);
            if( s == "" )
            {
                if( no == 0 )
                    ret.addr ~= BlockAddress.root();
                else continue;
            }
            else if( s == "." ) ret.addr ~= BlockAddress.current();
            else if( s == ".." ) ret.addr ~= BlockAddress.parent();
            else if( checkPrefix(s,"array") )
                ret.addr ~= BlockAddress.array( getArrayIndex(s) );
            else
                ret.addr ~= BlockAddress.dict(s);
        }
        return ret;
    }

    size_t getArrayIndex( string str ) const
    {
        import std.stdio;
        auto s = chompPrefix( str, params["array"] );
        return to!size_t( s );
    }
}

unittest
{
    auto r = new Rules;

    assert( r.isEmpty( "" ) );
    assert( r.isEmpty( "   " ) );
    assert( !r.isEmpty( " x " ) );

    assert( r.isComment( "# abc" ) );
    assert( r.isComment( "  # abc" ) );
    assert( r.isComment( "# abc  " ) );
    assert( r.isComment( "  # abc  " ) );
    assert( !r.isComment( "abc" ) );
    assert( !r.isComment( "" ) );
    assert( !r.isComment( "   " ) );
    assert( !r.isComment( " abc#  " ) );
}

unittest
{
    auto r = new Rules;

    assert( r.isValue( "adlf kj" ) );
    assert( r.isValue( "adj l fkj" ) );
    assert( r.isValue( "  adj l fkj  " ) );
    assert( r.isValue( "  adj l fkj # with comment " ) );
    assert( r.isValue( "  !adj l fkj # it isn't comment " ) );
    assert( r.isValue( "  !adj: l fkj # it isn't comment " ) );
    assert( r.isValue( "  !adj: +l(fkj, ''# it isn't comment " ) );
    assert( !r.isValue( "  adj: fkj # it is comment " ) );
    assert( !r.isValue( "  +call(some) " ) );
    assert( !r.isValue( "  $/some/../addr/ " ) );

    assert( r.isBlockDefinitionLine( "  adj: fkj # it is comment " ) );
}

unittest
{
    auto r = new Rules;

    assert(  r.isTrueBlockName( "@" ) );
    assert( !r.isTrueBlockName( "@bac" ) );
    assert(  r.isTrueBlockName( "abc" ) );
    assert(  r.isTrueBlockName( "_1abc" ) );
    assert(  r.isTrueBlockName( "_1abc00" ) );
    assert(  r.isTrueBlockName( "a_bc00" ) );
    assert( !r.isTrueBlockName( "1abc00" ) );
    assert( !r.isTrueBlockName( "a bc" ) );
}

unittest
{
    auto r = new Rules;

    assert( r.extractValue( " some string # with comment " ) == "some string" );
    assert( r.extractValue( " !some string # with comment symbol " ) == "some string # with comment symbol" );
}

unittest
{
    auto r = new Rules;

    assert( r.isCommand( "   +$../ssub # append" ) );
    assert( r.isCommand( "=$../fsub # replace" ) );
    assert( r.isCommand( "   %$../fsub # update" ) );

}

unittest
{
    auto r = new Rules;

    void checkBlock( BlockSource block )
    {
        auto res = r.parseCommand( block );
        assert( res.action == Command.Action.APPEND );
        assert( res.subject.type == Command.Subject.Type.BLOCK );
        assert( res.subject.addr.length == 5 );
        assert( res.subject.addr[0] == BlockAddress.root() );

        assert( res.subject.addr[1].type == BlockAddress.Type.DICT );
        assert( res.subject.addr[1].name == "some" );

        assert( res.subject.addr[2].type == BlockAddress.Type.ARRAY );
        assert( res.subject.addr[2].index == 12 );

        assert( res.subject.addr[3] == BlockAddress.parent() );
    }
    checkBlock( BlockSource( [ "+$/some/@12/../@11/ # comment" ], 0 ) );
    checkBlock( BlockSource( [ "+$/some/@12/../@11 # comment" ], 0 ) );

}

unittest
{
    auto lines =
`
asfc
 asflkj
 aslfk

alskfj
    alskfdj

aslkdfj
`.splitLines;

    auto r = new Rules;
    auto sb = r.splitBlocks( BlockSource( lines, 0 ) );

    assert( sb.length == 3 );

    assert( sb[0].start_at_line == 1 );
    assert( sb[0].text.length == 4 );

    assert( sb[1].start_at_line == 5 );
    assert( sb[1].text.length == 3 );

    assert( sb[2].start_at_line == 8 );
    assert( sb[2].text.length == 1 );
}

unittest
{
    auto lines =
`
    a
    b
    c
`.splitLines;

    auto r = new Rules;
    auto sb = r.splitBlocks( BlockSource( lines, 0 ) );

    assert( sb.length == 3 );

    assert( sb[0].start_at_line == 1 );
    assert( sb[0].text.length == 1 );

    assert( sb[1].start_at_line == 2 );
    assert( sb[1].text.length == 1 );

    assert( sb[2].start_at_line == 3 );
    assert( sb[2].text.length == 1 );
}

unittest
{
    auto r = new Rules;
    auto line =" a:b:c: d: f: a: some_value";
    auto sp = r.splitBlockDefinition( line );
    string[2] result = ["a", "b:c: d: f: a: some_value"];
    assert( sp == result );
}

unittest
{
    auto r = new Rules;
    auto line = " block:";
    auto sp = r.splitBlockDefinition( line );
    string[2] result = [ "block", "" ];
    assert( sp == result );
}

unittest
{
    auto r = new Rules;
    assert( r.getIndent( "  32  " ) == 2 );
    assert( r.getIndent( " a" ) == 1 );
}

unittest
{
    auto r = new Rules;
    assert( r.appendValue( "", "abc" ) == "abc" );
    assert( r.appendValue( "xx", "abc" ) == "xx\nabc" );

}
