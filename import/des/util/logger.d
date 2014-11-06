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

module des.util.logger;

import std.stdio;
import std.string;
import std.conv;
import std.datetime;
import std.traits;

import std.algorithm;

enum LogLevel
{
    OFF   = 0,
    ERROR = 1,
    WARN  = 2,
    INFO  = 3,
    DEBUG = 4,
    TRACE = 5
};

struct LogMessage
{
    string emitter;
    ulong ts;
    LogLevel level;
    string message;

    @disable this();

    pure nothrow @safe this( string emitter, ulong ts,
                             LogLevel level, string message )
    {
        this.emitter = emitter;
        this.ts = ts;
        this.level = level;
        this.message = message;
    }
}

string formatLogMessage( in LogMessage lm )
{
    auto fmt = "[%016.9f][%5s][%s]: %s";
    return format( fmt, lm.ts / 1e9f, lm.level, lm.emitter, lm.message );
}

mixin template AnywayLogger()
{
    private Logger __logger;
    protected nothrow final @property
    {
        const(Logger) logger() const
        {
            static import des.util.logger;
            if( __logger is null )
                return des.util.logger.simple_logger;
            else return __logger;
        }
        void logger( Logger lg ) { __logger = lg; }
    }
}

abstract class Logger
{
    mixin( getLogFunctions( "", "__log", "procFuncName", true ) );
protected:
    nothrow string procFuncName( string name ) const
    in{ assert( name.length ); }
    out(ret){ assert( ret.length ); }
    body { return name; }
}

private class SimpleLogger : Logger {}

SimpleLogger simple_logger;

static this()
{
    simple_logger = new SimpleLogger;
}

class InstanceLogger : Logger
{
protected:
    string class_name;
    string inst_name;

public:
    this( Object obj, string inst="" )
    {
        class_name = typeid(obj).name;
        inst_name = inst;
    }

    this( string obj, string inst="" )
    {
        class_name = obj;
        inst_name = inst;
    }

    nothrow @property
    {
        void instance( string i ) { inst_name = i; }
        string instance() const { return inst_name; }
    }

protected:

    override nothrow string procFuncName( string name ) const
    {
        try return fullEmitterName ~ "." ~ name.split(".")[$-1];
        catch(Exception e) return fullEmitterName;
    }

    nothrow @property string fullEmitterName() const
    { return class_name ~ (inst_name.length?".["~inst_name~"]":""); }
}

class InstanceFullLogger : InstanceLogger
{
    public this( Object obj, string inst="" ) { super(obj,inst); }
    protected override nothrow string procFuncName( string name ) const
    { return fullEmitterName ~ ".[" ~ name ~ "]"; }
}

mixin( getLogFunctions( "log_", "__log" ) );

private string getLogFunctions( string prefix, string baselog, string emitterProc="", bool isConst=false )
{
    string fnc = `
    nothrow void %s%s(string fnc=__FUNCTION__,Args...)( Args args )%s
    { %s( LogMessage( %s, __ts, LogLevel.%s, toMessage(args) ) ); }
    `;

    string emitter = emitterProc ? emitterProc ~ "(fnc)" : "fnc";

    string ret;
    foreach( lvl; [EnumMembers!LogLevel] )
    {
        if( lvl == LogLevel.OFF ) continue;
        auto slvl = to!string(lvl);
        auto fname = slvl.toLower;
        if( fname == "debug" && prefix.length == 0 ) fname = "Debug";
        ret ~= format( fnc, prefix, fname, isConst?" const":"",
                baselog, emitter, slvl );
    }
    return ret;
}

private nothrow @property ulong __ts()
{
    try return Clock.currAppTick().length;
    catch(Exception e) return 0;
}

private nothrow void __log( in LogMessage lm )
{
    try
    {
        if( log_rule.allow(lm.emitter) >= lm.level )
        {
            if( lm.level < LogLevel.INFO )
                stderr.writeln( formatLogMessage( lm ) );
            else
                stdout.writeln( formatLogMessage( lm ) );
        }
    }
    catch(Exception e)
    {
        try stderr.writefln( "[INTERNAL LOG EXCEPTION]: %s", e );
        catch(Exception){}
    }
}

nothrow string toMessage(Args...)( Args args )
{
    try
    {
        static if( is( Args[0] == string ) )
            return format( args );
        else
        {
            string res;
            foreach( arg; args )
                res ~= to!string(arg);
            return res;
        }
    } 
    catch(Exception e)
        return "[MESSAGE CTOR EXCEPTION]: " ~ e.msg;
}

private synchronized class Rule
{
protected:
    shared Rule parent;

    LogLevel level = LogLevel.ERROR;
    shared Rule[string] inner;

    bool use_minimal = true;

public:
    this( shared Rule parent = null ) { this.parent = parent; }

    @property bool useMinimal() const
    {
        if( parent !is null )
            return parent.useMinimal();
        else return use_minimal;
    }

    void setLevel( LogLevel lvl, string emitter="" )
    {
        auto addr = splitAddress( emitter );
        if( addr[0].length == 0 ) { level = lvl; return; }
        auto iname = addr[0];
        if( iname !in inner ) inner[iname] = new shared Rule(this);
        inner[iname].setLevel( lvl, addr[1] );
    }

    LogLevel allow( string emitter="" )
    {
        auto addr = splitAddress( emitter );
        if( addr[0].length == 0 ) return level;
        auto iname = addr[0];
        if( iname !in inner ) return level;
        if( useMinimal )
            return min( level, inner[iname].allow( addr[1] ) );
        else
            return inner[iname].allow( addr[1] );
    }

    string print( string offset="" ) const
    {
        string ret = format( "%s", level );
        foreach( key, val; inner )
            ret ~= format( "\n%s%s : %s", offset, key, val.print( offset ~ mlt(" ",key.length) ) );
        return ret;
    }

protected:

    static string[2] splitAddress( string emitter )
    {
        auto addr = emitter.split(".");
        if( addr.length == 0 ) return ["",""];
        if( addr.length == 1 ) return [addr[0],""];
        
        return [ addr[0], addr[1..$].join(".") ];
    }
}

private T[] mlt(T)( T[] val, size_t cnt )
{
    T[] buf;
    foreach( i; 0 .. cnt )
        buf ~= val;
    return buf;
}

unittest { assert( "    ", mlt( " ", 4 ) ); }

unittest
{
    auto r = new shared Rule;

    r.setLevel( LogLevel.INFO );
    r.setLevel( LogLevel.TRACE, "des.gl" );
    r.setLevel( LogLevel.WARN, "des" );

    assert( r.allow() == LogLevel.INFO );
    assert( r.allow("des") == LogLevel.WARN );
    assert( r.allow("des.gl") == LogLevel.WARN );

    r.use_minimal = false;

    assert( r.allow() == LogLevel.INFO );
    assert( r.allow("des") == LogLevel.WARN );
    assert( r.allow("des.gl") == LogLevel.TRACE );
}

private static shared Rule log_rule;

shared static this()
{
    if( log_rule !is null ) return;

    import core.runtime, std.getopt;
    import std.stdio;
    import std.file;

    log_rule = new shared Rule;

    auto args = thisExePath ~ Runtime.args;
    string[] logging;
    bool useMinimal = false;
    
    try
    {
        getopt( args,
                std.getopt.config.passThrough,
                "log", &logging,
                "log-use-min", &useMinimal,
              );
    }
    catch( Exception e ) stderr.writefln( "bad log arguments: %s", e.msg );

    log_rule.use_minimal = useMinimal;

    foreach( ln; logging )
    {
        auto sp = ln.split(":");
        if( sp.length == 1 )
        {
            try log_rule.setLevel( toLogLevel( sp[0] ) );
            catch( Exception e )
                stderr.writefln( "log argument '%s' can't conv to LogLevel: %s", ln, e.msg );
        }
        else if( sp.length == 2 )
        {
            try
            {
                auto level = toLogLevel( sp[1] );
                log_rule.setLevel( level, sp[0] );
            }
            catch( Exception e )
                stderr.writefln( "log argument '%s' can't conv '%s' to LogLevel: %s", ln, sp[1], e.msg );
        }
        else stderr.writefln( "bad log argument: %s" );
    }

    if( logging.length )
    {
        writeln( "[log use min]: ", useMinimal );
        writeln( "[log rules]:\n", log_rule.print() );
    }
}

LogLevel toLogLevel( string s ) { return to!LogLevel( s.toUpper ); }
