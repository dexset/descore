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
    LogLevel level;
    ulong ts;
    string emmiter;
    string message;

    this( LogLevel ll, string em, string msg )
    {
        ts = Clock.currAppTick().length;
        level = ll;
        emmiter = em;
        message = msg;
    }
}

nothrow
{
    void log_error(string m=__MODULE__, Args...)( Args args ) { __log( m, __ts, LogLevel.ERROR, args ); }
    void log_warn (string m=__MODULE__, Args...)( Args args ) { __log( m, __ts, LogLevel.WARN,  args ); }
    void log_info (string m=__MODULE__, Args...)( Args args ) { __log( m, __ts, LogLevel.INFO,  args ); }
    void log_debug(string m=__MODULE__, Args...)( Args args ) { __log( m, __ts, LogLevel.DEBUG, args ); }
    void log_trace(string m=__MODULE__, Args...)( Args args ) { __log( m, __ts, LogLevel.TRACE, args ); }
}

private nothrow @property ulong __ts()
{
    try return Clock.currAppTick().length;
    catch(Exception e) return 0;
}

private nothrow void __log(Args...)( string emmiter, ulong timestamp, LogLevel level, Args args )
{
    try
    {
        auto fmt = "[%016.9f][%5s][%s]: %s";
        auto msg = message( args );
        if( rule.allow(emmiter) >= level )
        {
            if( level < LogLevel.INFO )
                stderr.writefln( fmt, timestamp / 1e9f, level, emmiter, msg );
            else
                stdout.writefln( fmt, timestamp / 1e9f, level, emmiter, msg );
        }
    }
    catch(Exception e)
    {
        try stderr.writefln( "[INTERNAL LOG EXCEPTION]: %s", e );
        catch(Exception){}
    }
}

string message(Args...)( Args args )
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

private class Rule
{
    Rule parent;

    LogLevel level = LogLevel.OFF;
    Rule[string] inner;

    bool use_minimal = true;

    @property bool useMinimal() const
    {
        if( parent !is null )
            return parent.useMinimal();
        else return use_minimal;
    }

    this( Rule parent = null ) { this.parent = parent; }

    string[2] splitAddress( string emmiter )
    {
        auto addr = emmiter.split(".");
        if( addr.length == 0 ) return ["",""];
        if( addr.length == 1 ) return [addr[0],""];
        
        return [ addr[0], addr[1..$].join(".") ];
    }

    void setLevel( LogLevel lvl, string emmiter="" )
    {
        auto addr = splitAddress( emmiter );

        if( addr[0].length == 0 ) { level = lvl; return; }

        auto iname = addr[0];

        if( iname !in inner ) inner[iname] = new Rule(this);

        inner[iname].setLevel( lvl, addr[1] );
    }

    LogLevel allow( string emmiter="" )
    {
        auto addr = splitAddress( emmiter );

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
    auto r = new Rule;

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

private Rule rule;

static this()
{
    import core.runtime, std.getopt;
    import std.stdio;
    import std.file;

    rule = new Rule;

    auto args = thisExePath ~ Runtime.args;
    string[] logging;
    bool useMinimal;
    
    try
    {
        getopt( args,
                "log", &logging,
                "log-use-minimal", &useMinimal,
              );
    }
    catch( Exception e ) stderr.writefln( "bad log arguments: %s", e.msg );

    rule.use_minimal = useMinimal;

    foreach( ln; logging )
    {
        auto sp = ln.split(":");
        if( sp.length == 1 )
        {
            try rule.setLevel( toLogLevel( sp[0] ) );
            catch( Exception e )
                stderr.writefln( "log argument '%s' can't conv to LogLevel: %s", ln, e.msg );
        }
        else if( sp.length == 2 )
        {
            try
            {
                auto level = toLogLevel( sp[1] );
                rule.setLevel( level, sp[0] );
            }
            catch( Exception e )
                stderr.writefln( "log argument '%s' can't conv '%s' to LogLevel: %s", ln, sp[1], e.msg );
        }
        else stderr.writefln( "bad log argument: %s" );
    }

    writeln( "[log use minimal]: ", useMinimal );
    writeln( "[log rules]:\n", rule.print() );
}

LogLevel toLogLevel( string s ) { return to!LogLevel( s.toUpper ); }
