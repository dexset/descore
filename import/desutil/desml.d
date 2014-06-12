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

module desutil.desml;

import std.string;
import std.conv; 
import std.array;

version(unittest) 
{ 
    private 
    {
        debug
        {
            void log(A...)( string fmt, A args )
            {
                import std.stdio;
                stderr.writefln( fmt, args );
            }

            void log(T)( in T[] t ) { log( "%s", t ); }
            void log(T)( in T t ) if( !is( T == string ) ) { log( "%s", t ); }

            void print( in DMLValue ff, string name="", string offset="" )
            {
                log( offset ~ "[%s]", name );

                foreach( k, v; ff.str )
                    log( offset ~ "  " ~ "\"%s\" == %s", k, v );
                foreach( k, v; ff.chnode )
                    foreach( oo; v )
                        print( oo, k, offset ~ "  " );

                log( offset ~ "[/%s]", name );
            }

        }

        void throwCheck(int ln=__LINE__)( void delegate() f, string msg="" )
        {
            bool thr = false;
            try f(); catch( Throwable t ) thr = true;
            assert( thr, format( "[at line %d]: %s", ln, msg ) );
        }
    }
}

class DMLException: Exception
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, int line=__LINE__ ) 
    { super( msg, file, line ); } 
}

class DMLConvertDefault: DMLException
{
    @safe pure nothrow this( string msg, string file=__FILE__, int line=__LINE__ ) 
    { super( msg, file, line ); } 
}

class DMLParseException: DMLException
{ 
    @safe pure nothrow this( string msg, int line=__LINE__ ) 
    { super( msg, __FILE__, line ); } 
}

private void throwFmt(int line=__LINE__, A...)( string fmt, A args ) 
{ throw new DMLParseException( format( "ERROR: " ~ fmt, args ), line ); }

private void assertFmt(int line=__LINE__, A...)( bool v, string fmt, A args )
{ if( !v ) throwFmt!line( fmt, args ); }

alias string delegate(string[]) DMLMacros;

struct DMLValue
{
    string[][string] str;
    DMLValue[][string] chnode;

    pure this(T)( in T c )
        if( is( T == DMLValue ) || is( T == shared DMLValue ) )
    {
        foreach( k, v; c.str )
            if( v !is null )
            {
                str[k] = [];
                foreach( s; v ) str[k] ~= s;
            }
        str.rehash();

        foreach( k, v; c.chnode )
            if( v !is null ) 
            {
                chnode[k] = [];
                foreach( o; v ) 
                    chnode[k] ~= DMLValue(o);
            }
        chnode.rehash();
    }

    static DMLValue load( in ubyte[] data )
    { return parseDML(cast(string)data.idup); }

    auto dump() const
    { return cast(immutable(ubyte)[])(writeDML(this).idup); }

    // FIXME: workaround 
    static private enum opEqualsStr = 
        `foreach( k, v; c.str )
            if( k !in str ) return false;
            else foreach( i, s; c.str[k] )
                if( s != str[k][i] ) return false;
        foreach( k, v; c.chnode )
            if( k !in chnode ) return false;
            else foreach( i, o; c.chnode[k] )
                if( o != chnode[k][i] ) return false;
        return true;`;

    bool opEquals(T)( in T c ) const
        if( is( T == DMLValue ) || is( T == shared DMLValue ) )
    { mixin( opEqualsStr ); }

    shared bool opEquals(T)( in T c ) const
        if( is( T == DMLValue ) || is( T == shared DMLValue ) )
    { mixin( opEqualsStr ); }

    void assign( string key, string[] val... ) { str[key] = val.dup; }

    void assign( string key, in DMLValue[] val... ) 
    { 
        DMLValue[] buf;
        foreach( v; val )
            buf ~= DMLValue( v );
        chnode[key] = buf; 
    }

    void append( string key, string[] val... )
    {
        auto ll = key in str;
        if(ll) (*ll) ~= val;
        else str[key] = val.dup;
    }

    void append( string key, in DMLValue[] val... )
    {
        DMLValue[] buf;
        foreach( v; val ) buf ~= DMLValue(v);

        auto ll = key in chnode;
        if(ll) (*ll) ~= buf;
        else chnode[key] = buf;
    }

    ref DMLValue obj( string key, size_t index=0 ) 
    { return chnode[key][index]; }

    ref const(DMLValue) obj( string key, size_t index=0 ) const 
    { return chnode[key][index]; }

    string opIndex( string key, size_t index=0 ) const
    { 
        if( key !in str || str[key] is null )
            throw new DMLException( format( "no key '%s' in str list", key ) );

        return str[key][index];
    }

    string opIndexAssign( string val, string key, size_t index=0 )
    {
        if( key !in str || str[key] is null )
            str[key] = [val];
        else if( index == str[key].length ) str[key] ~= val;
        else str[key][index] = val;

        return val;
    }

    private pure static @property auto defconv(T)()
    { 
        static if( __traits(compiles, to!T(string.init) ) )
            return delegate T(string x) { return to!T(x); }; 
        else 
            return delegate T(string x)
            { throw new DMLException( format("no conertion function and no function 'to!%s'", T.stringof ) ); };
    }

    private const(DMLValue)* leafptr( string[] node ) const
    {
        if( node.length == 0 )
            return &this;

        const(DMLValue)* v = &this;
        foreach( n; node )
        {
            auto r = n in v.chnode;
            if( r is null || r.length == 0 ) return null;
            v = &((*r)[0]);
        }
        return v;
    }

    DMLValue leaf( string path, string pathsplitter="." ) const
    {
        auto v = leafptr( path.split(pathsplitter) );
        if( v is null ) return DMLValue();
        else return DMLValue( (*v) );
    }

    T get(T)( string path, T def, T delegate(string) cnv=defconv!T, size_t index=0, string pathsplitter="." ) const
    {
        auto node = path.split(pathsplitter);
        auto key = node[$-1].strip();
        auto v = leafptr( node[0 .. $-1] );
        if( v is null ) return def;
        if( key !in (*v).str || (*v).str[key] is null )
            return def;

        cnv = cnv !is null ? cnv : defconv!T;
        try return cnv( (*v).str[key][index] );
        catch( DMLConvertDefault ) return def;
    }

    T[] getAll(T)( string path, T def, T delegate(string) cnv=defconv!T, string pathsplitter="." ) const
    {
        auto node = path.split(pathsplitter);
        auto key = node[$-1].strip();
        auto v = leafptr( node[0 .. $-1] );
        if( v is null ) return [ def ];
        if( key !in (*v).str || (*v).str[key] is null )
            return [ def ];

        cnv = cnv !is null ? cnv : defconv!T;
        T[] ret;
        foreach( s; (*v).str[key] )
        {
            try ret ~= cnv(s);
            catch( DMLConvertDefault ) ret ~= def;
        }

        return ret;
    }

    @property ref DMLValue opDispatch(string key, size_t index=0)()
    {
        if( key !in chnode ) 
            throw new DMLException( format( "no key '%s' in obj tree, %s", key, chnode.keys ) );
        return chnode[key][index];
    }

    @property ref const(DMLValue) opDispatch(string key, size_t index=0)() const
    {
        if( key !in chnode ) 
            throw new DMLException( format( "no key '%s' in obj tree", key ) );
        return chnode[key][index];
    }
}

unittest
{
    DMLValue ch1;

    ch1["param1"] = "value1";
    import std.stdio;
    assert( ch1["param1"] == "value1" );
    ch1["param1"] = "value2";
    assert( ch1["param1"] == "value2" );
    ch1["param1",1] = "value1";
    assert( ch1["param1",0] == "value2" );
    assert( ch1["param1",1] == "value1" );
    ch1["param1",0] = "value3";
    assert( ch1["param1",0] == "value3" );
    ch1["param2"] = "value3";
    assert( ch1["param2",0] == "value3" );

    throwCheck( { ch1["param2",2] = "value3"; } );

    ch1.assign("param1", "val");
    assert( ch1["param1"] == "val" );
    assert( ( ch1["param1",1] = "value1" ) == "value1" );
    throwCheck( { ch1["param1",3] = "value1"; } );

    DMLValue ch2;
    ch2["param"] = "value";

    ch1.assign( "child", ch2 );
    assert( ch1.obj("child")["param"] == "value" );

    assert( ch1.child["param"] == "value" );
    throwCheck( { ch1.chold["param"] = "ok"; }, "'no value' exception must be throwed" );

    auto a = ch1;
    auto b = shared DMLValue( a );
    auto c = immutable DMLValue( a );
    auto d = shared immutable DMLValue( a );
    auto e = shared const DMLValue( a );
    assert( a == b );
    assert( a == c );
    assert( a == d );
    assert( a == e );
    auto ab = DMLValue( b );
    auto ac = DMLValue( c );
    auto ad = DMLValue( d );
    auto ae = DMLValue( e );
    assert( a == ab );
    assert( a == ac );
    assert( a == ad );
    assert( a == ae );
    auto ba = shared DMLValue( b );
    auto ca = immutable DMLValue( c );
    auto da = shared immutable DMLValue( d );
    auto ea = shared const DMLValue( e );
    assert( a == ba );
    assert( a == ca );
    assert( a == da );
    assert( a == ea );
}

private string[] prepareRaw( string raw )
{
    auto lines = splitLines( raw );
    foreach( ref l; lines ) 
        l = strip(l);
    return lines;
}

unittest
{
    auto tst =
        `
        line1    

        #comment

        line2       
        line3
        `;
    auto res = prepareRaw( tst );
    assert( res == 
            [ 
            "",
            "line1", 
            "",
            "#comment",
            "",
            "line2", 
            "line3",
            ""
            ] );
}

private string[] findParams( in string[] dml, size_t ln, size_t spos, 
        ref size_t mlen, char open='[', char close=']', ptrdiff_t findcount = -1, char splitter=',', char[2] quotes=['"','"'] )
{
    string[] ret;
    bool finded = false;
    string buf;

    void buf2ret(bool st=true)
    {
        buf = st ? strip( buf ) : buf;
        if( buf.length ) ret ~= buf;
        buf = "";
    }

    size_t k = 1;
    string line;
    if( spos >= dml[ln].length ) line = dml[ln+k++];
    else line = strip( dml[ln][spos .. $] );

    bool block = false;
    bool escape = false;

    void throwNotAllow(int codeline=__LINE__)( char badchar )
    {
        throwFmt!codeline( "at line #%d '%s' : '%s' not allowed outside quotes %s %s in param at line #%d '%s'",
                    ln+k, dml[ln+k-1], badchar, quotes[0], quotes[1], ln, dml[ln] );
    }

    void checkAllow(int codeline=__LINE__)( char cc, string badchars )
    { foreach( bad; badchars ) if( cc == bad ) throwNotAllow!codeline( cc ); }

    while( !finded )
    {
        escape = false;

        if( line.length != 0 && line[0] != '#' )
        {

            foreach( i, cc; line )
            {
                if( escape )
                {
                    buf ~= cc;
                    escape = false;
                }
                else
                if( cc == quotes[0] )
                {
                    if( block ) buf2ret(false);
                    else buf = ""; 
                    block = !block;
                }
                else
                {
                    if( !block )
                    {
                        if( cc == splitter ) { buf2ret(); continue; }
                        else
                        if( cc == close ) { finded = true; break; }
                        else
                        if( cc == '\\' )
                        {
                            escape = true;
                            continue;
                        }
                        else checkAllow( cc, "[]{}()=" ~ open );
                    }
                    buf ~= cc;
                    escape = false;
                }
            }

            if( buf.length && !escape ) buf ~= " ";

            if( finded ) { buf2ret(); break; }

            if( findcount > 0 && ( ret.length + 1 >= findcount ) && !block && !escape ) { buf2ret(); break; }

        }

        if( ln+k >= dml.length && !finded )
            throwFmt( "unexpected EOF while read params #%d '%s'", ln, dml[ln] );

        if( !finded ) line = strip( dml[ln+k++] );
    }

    mlen = k;
    return ret;
}

unittest
{
    auto test1 = `{ a b, b
        c
        , c\
        d ,
        " ", multi
            line,
        multi\
            line2,
        "a,b,c", x\,y\]z }`;

    size_t mlen;
    auto finded = findParams( prepareRaw( test1 ), 0, 1, mlen, '{', '}' );
    assert( mlen == 9 );
    assert( finded == [ "a b", "b c", "cd", " ", "multi line", "multiline2", "a,b,c", "x,y]z" ] );

    auto test2 = `
        par1 = val1
    { Macro1 :
        a, b, c 
    }`;
    finded = findParams( prepareRaw( test2 ), 2, 10, mlen, '{', '}' );
    assert( mlen == 3 );
    assert( finded == [ "a", "b", "c" ] );

    // TODO: MORE TESTS
}

private void pasteMacros( ref string[] dml, DMLMacros[string] macros, bool except=false )
{
    if( macros is null ) return;

    string[] callMacros( size_t ln, ref size_t mlen )
    {
        auto line = dml[ln];

        string macroname;
        size_t paramstart = 0;

        foreach( i, ch; line[1 .. $] )
            if( ch == '}' )
            {
                paramstart = 0;
                break;
            }
            else if( ch == ':' )
            {
                paramstart = i+1;
                break;
            }
            else macroname ~= ch;

        macroname = toUpper( strip(macroname) );

        if( macroname !in macros )
        {
            if( except ) 
                throw new DMLException( format( "no macros '%s'", macroname ) );

            return [];
        }
        
        string[] params;

        if( paramstart ) params = findParams( dml, ln, paramstart+1, mlen, '{', '}' );

        return prepareRaw( macros[macroname]( params ) );
    }

    size_t wline = 0;
    while( dml.length > wline )
    {
        if( dml[wline].length && dml[wline][0] == '{' ) 
        {
            size_t mlen=1;
            auto mres = callMacros( wline, mlen );

            dml = dml[0 .. wline] ~ mres ~ 
                ( dml.length > wline+mlen ? dml[wline+mlen .. $] : [] );
        }
        else wline++;
    }
}

unittest
{
    auto mdef = `
        par1 = val1
    { Macro1 :
        a, b, c 
    }`;

    auto dml = prepareRaw( mdef );

    DMLMacros[string] mc;

    mc["MACRO1"] = (string[] par){ return join(par, "|"); };

    pasteMacros( dml, mc );

    assert( dml.length == 3 );
    assert( dml[0] == "" );
    assert( dml[1] == "par1 = val1" );
    assert( dml[2] == "a|b|c" );
}


private struct Elem
{
    DMLValue *val;
    string name;
}

private void parseLine( Elem elem, in string[] dml, ref size_t lineno )
in { assert( elem.val !is null ); }
body
{
    size_t startline = lineno;

    void checkName(int codeline=__LINE__)( string name, size_t lno )
    { assertFmt!codeline( name.length > 0, "empty name not allowed at line #%d '%s'", lno, dml[lno] ); }

    while( lineno < dml.length )
    {
        auto line = dml[lineno];

        if( line.length == 0 || line[0] == '#' )
        {
            lineno++;
            continue;
        }

        if( line[0] == '[' )
        {
            assertFmt( line[$-1] == ']', "bad format line #%d '%s'", lineno, line );
            auto name = strip( line[1 .. $-1] );
            checkName( name, lineno );

            lineno++;
            if( name[0] == '/' ) 
            {
                name = name[1 .. $]; 
                assertFmt( name == elem.name, "you must close '%s' before at line #%d '%s'", 
                        elem.name, lineno-1, dml[lineno-1] );
                return;
            }
            else
            {
                if( name[0] == '+') 
                {
                    name = name[1 .. $];
                    auto ee = name in (*(elem.val)).chnode;
                    if( ee && ee.length )
                        parseLine( Elem( &( (*(elem.val)).chnode[name][0] ), name ), dml, lineno );
                    else
                    {
                        DMLValue buf;
                        parseLine( Elem( &buf, name ), dml, lineno );
                        elem.val.assign( name, buf );
                    }
                }
                else
                {
                    DMLValue buf;
                    bool append = false;
                    if( name[0] == '*' )
                    {
                        append = true;
                        name = name[1 .. $];
                    }

                    parseLine( Elem( &buf, name ), dml, lineno );

                    if( append ) elem.val.append( name, buf );
                    else elem.val.assign( name, buf );
                }
            }
        }
        else
        {
            auto parts = split( line, "=" );
            auto name = strip( parts[0] );
            string[] params;
            
            auto rpart = strip( join( parts[1 .. $], "=" ) );

            size_t mlen = 1;

            //TEMP
            if( rpart.length == 0 ){ lineno++; continue; }

            import std.algorithm;
            if( rpart[0] == '[' )
            {
                params = findParams( dml, lineno, 
                        line.length - find( line, "[" ).length + 1, mlen, '[', ']' );
            }
            else
            {
                params = findParams( dml, lineno, 
                        line.length - find( line, "=" ).length + 1, mlen, '[', ']', 1 );
            }

            bool append = false;
            if( name[0] == '*' )
            {
                name = name[1 .. $];
                append = true;
            }

            checkName( name, lineno );

            if( append ) elem.val.append( name, params );
            else elem.val.assign( name, params );

            lineno += mlen;
        }
    }

    assertFmt( elem.name == "", "unexpected EOF, not closed elem '%s' at line #%d '%s'", 
            elem.name, startline, dml[startline] );
}

DMLValue parseDML( string origin, DMLMacros[string] macros=null, bool except=false )
{
    DMLValue root;

    auto dml = prepareRaw( origin );

    pasteMacros( dml, macros, except );

    size_t rline = 0;
    while( rline < dml.length )
        parseLine( Elem( &root, "" ), dml, rline );

    return root;
}

unittest
{
    auto dmlstr =
    `
    notrootparam 1 = true

    [root]
        param1 = value1   
        param2 = multi \
            line
        param3 = "megamulti   
            superline
            value"

        #comment line

        param1 = replace value 1
        *param2 = add to array
        array param = [ av1, array 
                                value 2, 
                        av3
                        ,
                        "ar[ray]
                            val=ue,4",
                        , av5,
                        ]
        [object1]
            [in1]
                p1 = v1
            [/in1]

            [*in1]
                p1 = v2
                p2 = v3
            [/in1]
        [/object1]


        param5 = value5

    [/root]

    [macrotest]

        {TEST_MACRO1}

        {TEST_MACRO2: 1
                    , 
                3\
                    4

                    , ololo value, "multi, line 
                    argument", new multi 
                    line argument, p5, "  " }

        {TEST_MACRO3:}
        {TEST_MACRO4:    }   

        param5 = value5

    [/macrotest]

    notrootparam 2 = notroot1

    *notrootparam 2 = notroot2
    `;

    DMLMacros[string] macros;
    macros["TEST_MACRO1"] = (string[] p){ return "m1 = m1 value"; };
    macros["TEST_MACRO3"] = (string[] p){ return "m3 = m3 value"; };
    macros["TEST_MACRO4"] = (string[] p){ return "m4 = m4 value"; };
    macros["TEST_MACRO2"] = (string[] params)
    {
        string buf;
        foreach( p; params )
            buf ~= "m2 " ~ p ~ " = test\n";
        return buf;
    };

    auto res = parseDML( dmlstr, macros );

    //print( res );

    assert( res["notrootparam 1"] == "true" );
    assert( res["notrootparam 2",0] == "notroot1" );
    assert( res["notrootparam 2",1] == "notroot2" );
    auto root = res.obj("root");
    assert( root["param1"] == "replace value 1" );
    assert( root["param5"] == "value5" );
    assert( root["param2",0] == "multi line" );
    assert( root["param2",1] == "add to array" );
    assert( root["param3"] == "megamulti superline value" );
    assert( root.str["array param"] == ["av1", "array value 2", "av3", "ar[ray] val=ue,4", "av5"] );
    auto root_object1 = root.obj("object1");
    auto root_object1_in1_arr = root_object1.chnode["in1"];
    assert( root_object1_in1_arr.length == 2 );

    auto RO1I1_0 = root_object1.obj("in1");
    assert( RO1I1_0.str.keys == [ "p1" ] );
    assert( RO1I1_0["p1"] == "v1" );

    auto RO1I1_1 = root_object1.obj("in1",1);
    assert( RO1I1_1.str.keys.sort == [ "p1", "p2" ].sort );
    assert( RO1I1_1["p1"] == "v2" );
    assert( RO1I1_1["p2"] == "v3" );

    auto mtest = res.obj("macrotest");
    assert( mtest["param5"] == "value5" );
    assert( mtest["m1"] == "m1 value" );
    assert( mtest["m2"] == "test" );
    assert( mtest["m2 34"] == "test" );
    assert( mtest["m2 p5"] == "test" );
    assert( mtest["m2 1"] == "test" );
    assert( mtest["m3"] == "m3 value" );
    assert( mtest["m2 ololo value"] == "test" );
    assert( mtest["m2 multi, line argument"] == "test" );
    assert( mtest["m2 new multi line argument"] == "test" );
    assert( mtest["m4"] == "m4 value" );
}

unittest
{
    struct tvec { double x,y,z; }
    tvec convertor( string s )
    {
        auto n = s.split();
        assert( n.length == 3 );
        return tvec( to!double(n[0]), to!double(n[1]), to!double(n[2]) );
    }

    auto dmlstr = `
        scale = 1.234
        [error]
            scale = 4.32
            [aa]
                offset = 1
                scale = 0.2
                *scale = 0.3
            [/aa]
            [ab]
                offset = 0.3
                scale = [ 0.1, 0.2, 0.3 ]
            [/ab]

            [b]
                vec = [ 0.1 0.2 0.3,
                        0.3 0.4 0.5 ]
                *vec = 0.5 0.6 0.7
            [/b]
        [/error]`;

    auto res = parseDML( dmlstr );

    assert( res.get("error.aa.offset", 0.0) == 1.0 );
    assert( res.get("error.scale", 0.0) == 4.32 );
    assert( res.get("scale", 0.0) == 1.234 );
    assert( res.getAll("error.aa.scale", 0.0) == [0.2, 0.3] );
    assert( res.getAll("error.ab.scale", 0.0) == [0.1, 0.2, 0.3] );
    assert( res.getAll("error.ac.scale", 0.666) == [0.666] );
    assert( res.getAll("error.b.vec", tvec(0,0,0), &convertor ) == [ tvec(.1,.2,.3),
                                                                         tvec(.3,.4,.5),
                                                                         tvec(.5,.6,.7) ] );

    auto b = res.leaf("error.b");
    assert( b.getAll("vec", tvec(0,0,0), &convertor ) == [ tvec(.1,.2,.3),
                                                           tvec(.3,.4,.5),
                                                           tvec(.5,.6,.7) ] );
    auto c = res.leaf("error.c");
    assert( c.str.length == 0 );
    assert( c.chnode.length == 0 );

    assert( res.getAll("error|ac|scale", 0.666, null, "|") == [0.666] );
}

string writeDML( in DMLValue dml )
{
    enum space = "    ";

    string ret;

    void writeparam( string key, in string[] val, string offset )
    { 
        if( val.length > 1 )
        ret ~= format( "%s%s = %s\n", offset, key, val ); 
        else
        ret ~= format( "%s%s = \"%s\"\n", offset, key, val[0] ); 
    }

    void writeobj( string key, in DMLValue[] objlist, string offset )
    { 
        foreach( obj; objlist )
        {
            ret ~= format( "%s[%s%s]\n", offset, objlist.length > 1 ? "*": "", key );
            foreach( k, v; obj.str )
                writeparam( k, v, offset ~ space );
            foreach( k, ch; obj.chnode )
                writeobj( k, ch, offset ~ space );
            ret ~= format( "%s[/%s]\n", offset, key );
        }
    }
    
    foreach( k, v; dml.str )
        writeparam( k, v, "" );
    foreach( k, ch; dml.chnode )
        writeobj( k, ch, "" );

    return ret;
}

unittest
{
    auto origin =
        `
        name = Ivan \
                Ivanov

        phone = +7-916-000-00-00

        [work]
            org = "[an,nica|"
            years = 2005-2008
        [/work]

        [*work]
            org = RedHat\[\]
            years = 2008-*
        [/work]

        [ok]
            param1 = [ value1, abc, okda ]
            [ok2]
                param2 = value2
                [ok3]
                    param3 = value3
                    *param3 = val4
                [/ok3]
                param3 = value_ok23
            [/ok2]
        [/ok]
        `;

    auto dml = parseDML( origin );
    auto res = parseDML( writeDML( dml ) );

    assert( dml == res );
}

unittest
{
    import desutil.pdata;
    auto origin =
        `
        name = Ivan \
                Ivanov

        phone = +7-916-000-00-00

        [work]
            org = "[an,nica|"
            years = 2005-2008
        [/work]

        [*work]
            org = RedHat\[\]
            years = 2008-*
        [/work]

        [ok]
            param1 = [ value1, abc, okda ]
            [ok2]
                param2 = value2
                [ok3]
                    param3 = value3
                    *param3 = val4
                [/ok3]
                param3 = value_ok23
            [/ok2]
        [/ok]
        `;

    auto dml = parseDML( origin );
    auto a = PData( dml );
    auto dml2 = a.as!DMLValue;
    assert( dml == dml2 );
}
